import asyncio
import collections.abc
import functools
import json
import os
import sys
import textwrap
import time
import traceback

import dotenv
import openai

from util import find_game_root

dotenv.load_dotenv(override=True)


async_client = openai.AsyncClient(base_url="https://openrouter.ai/api/v1", api_key=os.environ["OPENROUTER_API_KEY"])

#
# what LLM is best to use???
#
#  gpt-4o is apparently the best for short text.
#  Claude-3.5-sonnet was allegedly the best for coherence and flow though.
#  (deepseek good for chinese apparently?)
#
# MODEL = "openai/gpt-3.5-turbo"
# MODEL = "openai/gpt-4o"
MODEL = "google/gemini-3-flash-preview"
TEMPERATURE = 0.0
RETRY_ATTEMPT = 10
CONCURRENT_REQUEST = 16


LANGUAGE_NAMES: dict[str, tuple[str, str]] = {
    # 1st tuple is English name (for LLM input)
    # 2nd tuple is native language name (for user display and LLM input)
    "fr": ("French", "Français"),
    "it": ("Italian", "Italiano"),
    "de": ("German", "Deutsch"),
    "es": ("Spanish", "Español"),
    "bg": ("Bulgarian", "Български"),
    "cs": ("Czech", "Čeština"),
    "da": ("Danish", "Dansk"),
    "nl": ("Dutch", "Nederlands"),
    "fi": ("Finnish", "Suomi"),
    "el": ("Greek", "Ελληνικά"),
    "hu": ("Hungarian", "Magyar"),
    "id": ("Indonesian", "Bahasa Indonesia"),
    "ja": ("Japanese", "日本語"),
    "ko": ("Korean", "한국어"),
    "no": ("Norwegian", "Norsk"),
    "pl": ("Polish", "Polski"),
    "pt_BR": ("Portuguese (Brazil)", "Português (Brasil)"),
    "pt": ("Portuguese", "Português"),
    "ro": ("Romanian", "Română"),
    "ru": ("Russian", "Русский"),
    "zh": ("Simplified Chinese", "简体中文"),  # Extracted from 'schinese'
    "es-419": ("Spanish (Latin America)", "Español (Latinoamérica)"),  # Extracted from 'latam'
    "sv": ("Swedish", "Svenska"),
    "th": ("Thai", "ไทย"),
    "zh_TW": ("Traditional Chinese", "繁體中文"),  # Extracted from 'tchinese'
    "tr": ("Turkish", "Türkçe"),
    "uk": ("Ukrainian", "Українська"),
    "vi": ("Vietnamese", "Tiếng Việt"),
}


# Works same as "keywords.json" in LOOTPLOT
LANGUAGE_KEYWORD_OVERRIDES: dict[str, dict[str, str]] = {}


@functools.lru_cache(None)
def get_keywords(lang: str):
    ret: list[str] = []
    if lang in LANGUAGE_KEYWORD_OVERRIDES:
        for k, v in LANGUAGE_KEYWORD_OVERRIDES[lang].items():
            ret.append("    " + k + ": " + v)

    return "\n".join(ret)


async def translate_text(lang: str, text: str):
    langname = LANGUAGE_NAMES.get(lang, lang)

    prompt = textwrap.dedent(
        f"""
    # ROLE AND GOAL
    You are an expert localization specialist, translating a casual incremental game from English to {langname[0]}. Your primary goal is to produce translations that are extremely clear, concise, and natural-sounding for gamers. The game revolves around farming crops in an arcade-style, buying upgrades in the upgrade-tree, and earning money.

    # CRITICAL RULES
    Follow these rules without exception:

    1. **Preserve Tags:** The source text contains formatting tags like `{{effect}}...{{/effect}}` or `{{image}} ... {{image2}} ...`. These tags must be preserved and if necessary wrap the corresponding words or phrases in the translated text.
        * **Input Example:** `I will give you {{c r=0 g=1 b=1}}three gold coins{{/c}}.`
        * **Correct Output (Spanish):** `Te daré {{c r=0 g=1 b=1}}tres monedas de oro{{/c}}.`
        * **Incorrect Output:** `{{c r=0 g=1 b=1}}Te daré{{/c}} tres monedas de oro.`
    
    2.  **Preserve Runtime Variables:** The source text may contain variables tags like `... %{{variable}} ...`. The `%{{variable}}` is single unit and denotes a variable. It must NOT be translated but they may be moved to match the translation better.
        * **Input Example:** `You have %{{bread}} breads`
        * **Correct Output (Indonesia):** `Kamu punya %{{bread}} roti`
        * **Incorrect Output:** `Kamu punya %{{roti}} roti`
        * **Incorrect Output:** `Kamu punya {{bread}}% roti` (relocating the percentage sign is wrong)

    3. **Prioritize Clarity & Brevity:** Your translations are for game UI elements and notifications. They MUST be concise and immediately understandable.
        * Sacrifice literal, word-for-word translation for clarity.
        * Sacrifice grammatical complexity for punchy, direct language.
        * This is the most important rule after keyword and tag handling.

    4. **Input Format:** The input format will be as follows:
       ```
       String: text to be translated, may span multiple lines.
       Context: additional context to aid translation.
       ```
       `Context` may or may not be provided. If provided, use it to improve translation accuracy.

    5. **Output Format:** Your ONLY output must be the raw translated text. No explanations, apologies, or conversational text like "Here is the translation:".

    # TRANSLATION TASK

    Translate the following text to **{langname[0]}/{langname[1]}**.
    """
    )

    backoff = 1

    text_and_context = text.split("\0")
    input_extract = text_and_context[0]
    input_for_llm = "String: " + input_extract
    if len(text_and_context) > 1:
        input_for_llm = input_for_llm + "\nContext: " + text_and_context[1]

    for _ in range(RETRY_ATTEMPT):
        try:
            resp = await async_client.chat.completions.create(
                model=MODEL,
                temperature=TEMPERATURE,
                messages=[{"role": "system", "content": prompt}, {"role": "user", "content": input_for_llm}],
                extra_body={"usage": {"include": True}},
            )
            output = resp.choices[0].message.content
            if output is None:
                raise ValueError("output is empty")

            print("Input:", text_and_context[0])
            if len(text_and_context) > 1:
                print("Context:", text_and_context[1])
            print("Output:", output)

            cost = 0.0
            if resp.usage:
                cost = float(resp.usage.model_dump()["cost"])
            return output, cost
        except Exception as e:
            traceback.print_exception(e, file=sys.stderr)
            time.sleep(backoff)
            backoff *= 2

    raise Exception("Failed after 5 attempts")


async def begin_translate(target_lang: str, keys: collections.abc.Iterable[str]):
    print("Translation target:", target_lang)

    output_translation: dict[str, str] = {}
    cost_total = 0.0
    semaphore = asyncio.Semaphore(CONCURRENT_REQUEST)

    async def managed_translate_text2(text: str):
        nonlocal cost_total

        async with semaphore:
            output_translation[text], cost = await translate_text(target_lang, text)
            cost_total += cost

    tasks = [managed_translate_text2(text) for text in keys]

    try:
        await asyncio.gather(*tasks)
    finally:
        print("Cost total (USD):", cost_total)

    print()
    return output_translation, cost_total


async def update(target_lang: str):
    with open(os.path.join(os.environ["APPDATA"], "LOVE/catx11/localization.json"), "r", encoding="utf-8") as f:
        input_translation: dict[str, str] = json.load(f)["strings"]

    locfile = os.path.join(find_game_root(), "assets/localization", f"{target_lang}.json")
    output_translation: dict[str, str] = {}
    if os.path.isfile(locfile):
        with open(locfile, "r", encoding="utf-8") as f:
            translation_info = json.load(f)
            output_translation = translation_info["strings"]

    new_translation, cost_total = await begin_translate(
        target_lang, set(input_translation.keys()) - set(output_translation.keys())
    )
    for k in set(output_translation.keys()) - set(input_translation.keys()):
        del output_translation[k]
    output_translation.update(new_translation)

    with open(locfile, "w", encoding="utf-8", newline="") as f:
        sorted_translation_by_key = sorted(output_translation.items(), key=lambda i: i[0])
        json.dump(
            {"name": LANGUAGE_NAMES[target_lang][1], "strings": dict(sorted_translation_by_key)},
            f,
            ensure_ascii=False,
            indent=4,
        )

    return cost_total


if __name__ == "__main__":

    async def main():
        cost_total = 0
        for k in LANGUAGE_NAMES.keys():
            cost_total += await update(k)

        print("Total Cost for All Translations:", cost_total, "USD")

    asyncio.run(main())
