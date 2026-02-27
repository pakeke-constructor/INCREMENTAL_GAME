
import json
import os
import re
from openai import OpenAI

# Initialize OpenRouter client
client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=os.environ.get("OPENROUTER_API_KEY"),
)

# Model to use
MODEL = "anthropic/claude-sonnet-4.6"

STEAM_APP_NAME = "Catx11"

# System prompt (will be cached)
SYSTEM_PROMPT = """
You are a professional translator for Steam game store pages. 
Translate the following game content accurately while preserving:
- HTML/BBCode formatting tags like [p], [/p], [h2], [list], [*], [img], etc.
- Special placeholders like {STEAM_APP_IMAGE}
- Technical terms and proper nouns (like game names, company names)
- The tone and style appropriate for game marketing

The game is called "Catx11".
It is a casual incremental game.

Translate ONLY the readable text content, not the tags or placeholders.
Keep the translation natural and engaging for gamers."""

def translate_text(text, target_language):
    """Translate a single text string to the target language."""

    if not text or text.strip() == "":
        return ""
    
    response = client.chat.completions.create(
        model=MODEL,
        messages=[
            {
                "role": "system",
                "content": SYSTEM_PROMPT
            },
            {
                "role": "user",
                "content": f"Translate the following text to {target_language}:\n\n{text}"
            }
        ],
        temperature=0.3,
    )
    
    return response.choices[0].message.content

def translate_language_section(english_data, target_language):
    """Translate all keys in a language section."""
    translated = {}
    
    print(f"\nTranslating to {target_language}...")
    for key, value in english_data.items():
        print(f"  Translating: {key[:50]}...")
        translated[key] = translate_text(value, target_language)
    
    return translated


def test_tags_valid(data):
    """Check that all img tags from English about section exist in every other language."""
    key = "app[content][about]"
    english = data["languages"]["english"][key]
    eng_imgs = re.findall(r'\[img[^\]]*\]\[/img\]', english)
    ok = True
    for lang, content in data["languages"].items():
        if lang == "english":
            continue
        about = content.get(key, "")
        for img in eng_imgs:
            if img not in about:
                print(f"  FAIL [{lang}]: missing {img}")
                ok = False
    if ok:
        print("All image tags valid!")
    return ok


def main():
    # Load the JSON file
    input_file = "storepage_all.json"  # Change this to your file name
    output_file = "steam_data_translated.json"
    
    print(f"Loading {input_file}...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Get the English data (source)
    english_data = data["languages"]["english"]
    
    # Iterate over each language and translate
    for language, content in data["languages"].items():
        if language == "english":
            continue  # Skip English (source language)
        
        # Check if language section is empty or needs translation
        # if not content or all(v == "" for v in content.values()):
        data["languages"][language] = translate_language_section(
            english_data, 
            language
        )
    
    # Save the translated data
    print(f"\nSaving to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
    
    print("Translation complete!")
    test_tags_valid(data)

if __name__ == "__main__":
    main()

