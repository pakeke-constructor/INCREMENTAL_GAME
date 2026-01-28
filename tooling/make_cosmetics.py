import datetime
import pathlib

import pydantic

from util import find_game_root

from typing import Literal


class Cosmetic(pydantic.BaseModel):
    name: str | dict[str, str]
    """Name of the item. If dict is given, it expects the name in each locale. (Usage: Steam Inventory)"""

    description: str | dict[str, str]
    """Description of the item. If dict is given, it expects the description in each locale. (Usage: Steam Inventory)"""

    image: str
    """
    Image ID used to draw this cosmetic. (Usage: In-Game)

    Image ID used to create the icon URL for Steam Inventory. (Usage: Steam Inventory)
    """

    type: Literal["HAT", "BACKGROUND", "AVATAR"]
    """Cosmetic type. (Usage: Steam Inventory, In-Game)"""


CHEST_ITEMDEF_ID = 1
CHEST_GENERATOR_ITEMDEF_ID = CHEST_ITEMDEF_ID + 1
COSMETIC_ITEMDEF_ID_START = 1000  # Cosmetic item ID will start at 1001
BASE_IMAGE_URL = "https://incrementalgame.npdep.com"
COSMETIC_IMAGE_FORMAT = "%(base_url)s/cosmetics/%(type)s/%(image)s.png"
COSMETIC_IMAGE_LARGE_FORMAT = "%(base_url)s/cosmetics/%(type)s/%(image)s_large.png"

# VERY IMPORTANT, READ THIS!!!!
# If you add items, ALWAYS APPEND to this list.
# PUT NEW COSMETICS ON THE BOTTOM AND DO NOT REORDER THIS LIST!!!!!
# REORDERING THIS LIST CHANGES THE STEAM ITEMDEF ID!!!!!!! (REALLY BAD)
COSMETICS = [
    Cosmetic(name="black", description="", image="black", type="BACKGROUND"),
    Cosmetic(name="blue", description="", image="blue", type="BACKGROUND"),
    Cosmetic(name="brownroom", description="", image="brownroom", type="BACKGROUND"),
    Cosmetic(name="candycane", description="", image="candycane", type="BACKGROUND"),
    Cosmetic(name="construction", description="", image="construction", type="BACKGROUND"),
    Cosmetic(name="danger", description="", image="danger", type="BACKGROUND"),
    Cosmetic(name="daytime", description="", image="daytime", type="BACKGROUND"),
    Cosmetic(name="diamond", description="", image="diamond", type="BACKGROUND"),
    Cosmetic(name="emerald", description="", image="emerald", type="BACKGROUND"),
    Cosmetic(name="gold", description="", image="gold", type="BACKGROUND"),
    Cosmetic(name="gray", description="", image="gray", type="BACKGROUND"),
    Cosmetic(name="grayroom", description="", image="grayroom", type="BACKGROUND"),
    Cosmetic(name="green", description="", image="green", type="BACKGROUND"),
    Cosmetic(name="neon", description="", image="neon", type="BACKGROUND"),
    Cosmetic(name="night", description="", image="night", type="BACKGROUND"),
    Cosmetic(name="orange", description="", image="orange", type="BACKGROUND"),
    Cosmetic(name="pitchblack", description="", image="pitchblack", type="BACKGROUND"),
    Cosmetic(name="purple", description="", image="purple", type="BACKGROUND"),
    Cosmetic(name="ruby", description="", image="ruby", type="BACKGROUND"),
    Cosmetic(name="silver", description="", image="silver", type="BACKGROUND"),
    Cosmetic(name="striped", description="", image="striped", type="BACKGROUND"),
    Cosmetic(name="sunset", description="", image="sunset", type="BACKGROUND"),
    Cosmetic(name="tiger", description="", image="tiger", type="BACKGROUND"),
    Cosmetic(name="whiteroom", description="", image="whiteroom", type="BACKGROUND"),
    Cosmetic(name="woodframe", description="", image="woodframe", type="BACKGROUND"),
    Cosmetic(name="woodframe_black", description="", image="woodframe_black", type="BACKGROUND"),
    Cosmetic(name="woodframe_blue", description="", image="woodframe_blue", type="BACKGROUND"),
    Cosmetic(name="woodframe_green", description="", image="woodframe_green", type="BACKGROUND"),
    Cosmetic(name="woodframe_red", description="", image="woodframe_red", type="BACKGROUND"),
    Cosmetic(name="woodframe_white", description="", image="woodframe_white", type="BACKGROUND"),
    Cosmetic(name="yellow", description="", image="yellow", type="BACKGROUND"),
    Cosmetic(name="zebra", description="", image="zebra", type="BACKGROUND"),
    Cosmetic(name="actuallyinvisiblecat", description="", image="actuallyinvisiblecat", type="AVATAR"),
    Cosmetic(name="angelcat", description="", image="angelcat", type="AVATAR"),
    Cosmetic(name="angrycat", description="", image="angrycat", type="AVATAR"),
    Cosmetic(name="blackcat", description="", image="blackcat", type="AVATAR"),
    Cosmetic(name="blankcat", description="", image="blankcat", type="AVATAR"),
    Cosmetic(name="brownsuitcat", description="", image="brownsuitcat", type="AVATAR"),
    Cosmetic(name="catptain", description="", image="catptain", type="AVATAR"),
    Cosmetic(name="cutecat", description="", image="cutecat", type="AVATAR"),
    Cosmetic(name="cyclopscat", description="", image="cyclopscat", type="AVATAR"),
    Cosmetic(name="demonicat", description="", image="demonicat", type="AVATAR"),
    Cosmetic(name="diamondcat", description="", image="diamondcat", type="AVATAR"),
    Cosmetic(name="emeraldcat", description="", image="emeraldcat", type="AVATAR"),
    Cosmetic(name="fatcat", description="", image="fatcat", type="AVATAR"),
    Cosmetic(name="goldencat", description="", image="goldencat", type="AVATAR"),
    Cosmetic(name="graycat", description="", image="graycat", type="AVATAR"),
    Cosmetic(name="greenscarfcat", description="", image="greenscarfcat", type="AVATAR"),
    Cosmetic(name="invisiblecat", description="", image="invisiblecat", type="AVATAR"),
    Cosmetic(name="negacat", description="", image="negacat", type="AVATAR"),
    Cosmetic(name="orangecat", description="", image="orangecat", type="AVATAR"),
    Cosmetic(name="plushcat", description="", image="plushcat", type="AVATAR"),
    Cosmetic(name="purplescarfcat", description="", image="purplescarfcat", type="AVATAR"),
    Cosmetic(name="quizzicalcat", description="", image="quizzicalcat", type="AVATAR"),
    Cosmetic(name="reanimatedcat", description="", image="reanimatedcat", type="AVATAR"),
    Cosmetic(name="redscarfcat", description="", image="redscarfcat", type="AVATAR"),
    Cosmetic(name="regularcat", description="", image="regularcat", type="AVATAR"),
    Cosmetic(name="rubycat", description="", image="rubycat", type="AVATAR"),
    Cosmetic(name="sadcat", description="", image="sadcat", type="AVATAR"),
    Cosmetic(name="silvercat", description="", image="silvercat", type="AVATAR"),
    Cosmetic(name="stripedcat", description="", image="stripedcat", type="AVATAR"),
    Cosmetic(name="surprisedcat", description="", image="surprisedcat", type="AVATAR"),
    Cosmetic(name="triplecat", description="", image="triplecat", type="AVATAR"),
    Cosmetic(name="tuffcat", description="", image="tuffcat", type="AVATAR"),
    Cosmetic(name="tuxcat", description="", image="tuxcat", type="AVATAR"),
    Cosmetic(name="blackcap", description="", image="blackcap", type="HAT"),
    Cosmetic(name="bluecap", description="", image="bluecap", type="HAT"),
    Cosmetic(name="buckethat", description="", image="buckethat", type="HAT"),
    Cosmetic(name="conehat", description="", image="conehat", type="HAT"),
    Cosmetic(name="cowboyhat", description="", image="cowboyhat", type="HAT"),
    Cosmetic(name="crown", description="", image="crown", type="HAT"),
    Cosmetic(name="divinghelmet", description="", image="divinghelmet", type="HAT"),
    Cosmetic(name="fishinghat", description="", image="fishinghat", type="HAT"),
    Cosmetic(name="ghost", description="", image="ghost", type="HAT"),
    Cosmetic(name="halo", description="", image="halo", type="HAT"),
    Cosmetic(name="kitten", description="", image="kitten", type="HAT"),
    Cosmetic(name="mafiahat", description="", image="mafiahat", type="HAT"),
    Cosmetic(name="monkblindfold", description="", image="monkblindfold", type="HAT"),
    Cosmetic(name="orangecap", description="", image="orangecap", type="HAT"),
    Cosmetic(name="pinkcap", description="", image="pinkcap", type="HAT"),
    Cosmetic(name="piratehat", description="", image="piratehat", type="HAT"),
    Cosmetic(name="rainbowcap", description="", image="rainbowcap", type="HAT"),
    Cosmetic(name="redcap", description="", image="redcap", type="HAT"),
    Cosmetic(name="stache", description="", image="stache", type="HAT"),
    Cosmetic(name="tinyhat", description="", image="tinyhat", type="HAT"),
    Cosmetic(name="tophat", description="", image="tophat", type="HAT"),
    Cosmetic(name="whitecap", description="", image="whitecap", type="HAT"),
    Cosmetic(name="yellowcap", description="", image="yellowcap", type="HAT"),
    # Add new items below, not above!
]


class SteamItem(pydantic.BaseModel):
    model_config = pydantic.ConfigDict(extra="allow")

    itemdefid: int
    type: Literal["item", "bundle", "generator", "playtimegenerator"]
    bundle: str | None = None
    name: str
    description: str
    display_type: str | None = None
    icon_url: str
    icon_url_large: str
    tradable: bool
    marketable: bool
    price: str | None = None
    exchange: str | None = None


class SteamItemdef(pydantic.BaseModel):
    model_config = pydantic.ConfigDict(populate_by_name=True)

    schema_url: str = pydantic.Field(
        alias="$schema", default="https://raw.githubusercontent.com/dukeofsussex/json-schema-steam/main/schema.json"
    )
    appid: int
    items: list[SteamItem]


def populate_localized(obj: object, prefix: str, kv: dict[str, str]):
    for k, v in kv.items():
        setattr(obj, f"{prefix}_{k}", v)


def main(root: pathlib.Path):
    # Generate Steam itemdef JSON
    with open(root / "steam_appid.txt", "r", encoding="utf-8") as f:
        appid = int(f.read())

    cosmetic_items: list[SteamItem] = []
    for itemdefid, cosmetic in enumerate(COSMETICS, COSMETIC_ITEMDEF_ID_START + 1):
        format = {"base_url": BASE_IMAGE_URL, "type": cosmetic.type, "image": cosmetic.image}
        si = SteamItem(
            itemdefid=itemdefid,
            type="item",
            name=cosmetic.name if isinstance(cosmetic.name, str) else cosmetic.name["english"],
            description=(
                cosmetic.description if isinstance(cosmetic.description, str) else cosmetic.description["english"]
            ),
            display_type=cosmetic.type.capitalize(),
            icon_url=COSMETIC_IMAGE_FORMAT % format,
            icon_url_large=COSMETIC_IMAGE_LARGE_FORMAT % format,
            tradable=True,
            marketable=True,
            price="1;VLV25",  # Change this if needed
        )
        if isinstance(cosmetic.name, dict):
            populate_localized(si, "name", cosmetic.name)
        if isinstance(cosmetic.description, dict):
            populate_localized(si, "name", cosmetic.description)
        cosmetic_items.append(si)

    steam_itemdef = SteamItemdef(
        appid=appid,
        items=[
            SteamItem(
                itemdefid=CHEST_ITEMDEF_ID,
                type="item",
                name="Chest",
                description="Cosmetic Chest",
                icon_url=f"{BASE_IMAGE_URL}/cosmetics/chest.png",
                icon_url_large=f"{BASE_IMAGE_URL}/cosmetics/chest_large.png",
                tradable=False,
                marketable=False,
            ),
            SteamItem(
                itemdefid=CHEST_GENERATOR_ITEMDEF_ID,
                type="generator",
                bundle=";".join(f"{c.itemdefid}x1" for c in cosmetic_items),
                name="Chest Generator",
                description="Cosmetic Chest Generator",
                icon_url=f"{BASE_IMAGE_URL}/cosmetics/chest.png",
                icon_url_large=f"{BASE_IMAGE_URL}/cosmetics/chest_large.png",
                tradable=False,
                marketable=False,
                exchange=f"{CHEST_ITEMDEF_ID}x1",
            ),
            *cosmetic_items,
        ],
    )
    with open(root / "steamitemdef.json", "w", encoding="utf-8") as f:
        f.write(steam_itemdef.model_dump_json(by_alias=True, indent=4, exclude_none=True))

    # Generate src/cosmetics/list.lua
    with open(root / "src/cosmetics/list.lua", "w", encoding="utf-8", newline="\n") as f:
        f.write(f"-- Auto-generated at {datetime.datetime.now(datetime.timezone.utc)}.\n")
        f.write("-- DO NOT EDIT! Changes on this file will be lost!\n")
        f.write("-- Modify tooling/make_cosmetics.py then re-run the script!\n\n")
        f.write("---@param defineCosmetic fun(type:g.CosmeticInfo.Type, id:string, name:string, def:g.CosmeticDef)\n")
        f.write("return function(defineCosmetic)\n")

        for c in COSMETICS:
            f.write(f"    defineCosmetic({c.type!r}, {c.image!r}, {c.name!r}, {{image = {c.image!r}}})\n")

        f.write("end\n")


if __name__ == "__main__":
    main(find_game_root())
