import datetime
import pathlib

import pydantic

from util import find_game_root

from typing import Literal, cast


class Cosmetic(pydantic.BaseModel):
    id: str
    """
    Cosmetic ID (Usage: In-Game)
    
    Image ID used to create the icon URL for Steam Inventory. (Usage: Steam Inventory)
    """

    name: str | dict[str, str]
    """
    Name of the item. If dict is given, it expects the name in each locale,, but `english` must exist.
    (Usage: Steam Inventory, In-Game)
    """

    description: str | dict[str, str]
    """Description of the item. If dict is given, it expects the description in each locale. (Usage: Steam Inventory)"""

    image: str
    """Image ID used to draw this cosmetic. (Usage: In-Game)"""

    type: Literal["HAT", "BACKGROUND", "AVATAR"]
    """Cosmetic type. (Usage: Steam Inventory, In-Game)"""

    offset_x: float = 0
    """Image X offset. Positive X goes to right. (Usage: In-Game)"""

    offset_y: float = 0
    """Image Y offset. Positive Y goes down. (Usage: In-Game)"""

    rarity: int = 0
    """Rarity ID. See `RARITY` keys for possible rarities."""


class Rarity(pydantic.BaseModel):
    name: str
    """Rarity Name"""

    color: str
    """Background Color"""

    weight: int
    """Rarity weight. Higher number means higher chance."""


CHEST_ITEMDEF_ID = 1
CHEST_GENERATOR_ITEMDEF_ID = CHEST_ITEMDEF_ID + 1
COSMETIC_ITEMDEF_ID_START = 1000  # Cosmetic item ID will start at 1001
BASE_IMAGE_URL = "https://incrementalgame.npdep.com"
COSMETIC_IMAGE_FORMAT = "%(base_url)s/cosmetics/%(type)s/%(image)s.png"
COSMETIC_IMAGE_LARGE_FORMAT = "%(base_url)s/cosmetics/%(type)s/%(image)s_large.png"

# VERY IMPORTANT, READ THIS!!!!
# If you add items, ALWAYS APPEND to this list.
# If you remove items, REPLACE THEM WITH `None` (DON'T REMOVE THEM!).
# PUT NEW COSMETICS ON THE BOTTOM AND DO NOT REORDER NOR REMOVE ITEM FROM THIS LIST!!!!!
# REORDERING THIS LIST CHANGES THE STEAM ITEMDEF ID!!!!!!! (REALLY BAD)
COSMETICS: list[Cosmetic | None] = [
    # Backgrounds
    Cosmetic(id="black", name="Black", description="", image="black", type="BACKGROUND"),
    Cosmetic(id="blue", name="Blue", description="", image="blue", type="BACKGROUND"),
    Cosmetic(id="brownroom", name="Brown Room", description="", image="brownroom", type="BACKGROUND"),
    Cosmetic(id="candycane", name="Candy Cane", description="", image="candycane", type="BACKGROUND"),
    Cosmetic(id="construction", name="Construction", description="", image="construction", type="BACKGROUND"),
    Cosmetic(id="danger", name="Danger", description="", image="danger", type="BACKGROUND"),
    Cosmetic(id="daytime", name="Daytime", description="", image="daytime", type="BACKGROUND"),
    Cosmetic(id="diamond", name="Diamond", description="", image="diamond", type="BACKGROUND"),
    Cosmetic(id="emerald", name="Emerald", description="", image="emerald", type="BACKGROUND"),
    Cosmetic(id="gold", name="Gold", description="", image="gold", type="BACKGROUND", rarity=2),
    Cosmetic(id="gray", name="Gray", description="", image="gray", type="BACKGROUND"),
    Cosmetic(id="grayroom", name="Grayroom", description="", image="grayroom", type="BACKGROUND"),
    Cosmetic(id="green", name="Green", description="", image="green", type="BACKGROUND"),
    Cosmetic(id="neon", name="Neon", description="", image="neon", type="BACKGROUND"),
    Cosmetic(id="night", name="Night", description="", image="night", type="BACKGROUND", rarity=1),
    Cosmetic(id="orange", name="Orange", description="", image="orange", type="BACKGROUND"),
    Cosmetic(id="pitchblack", name="Pitch Black", description="", image="pitchblack", type="BACKGROUND"),
    Cosmetic(id="purple", name="Purple", description="", image="purple", type="BACKGROUND"),
    Cosmetic(id="ruby", name="Ruby", description="", image="ruby", type="BACKGROUND"),
    Cosmetic(id="silver", name="Silver", description="", image="silver", type="BACKGROUND"),
    Cosmetic(id="striped", name="Striped", description="", image="striped", type="BACKGROUND"),
    Cosmetic(id="sunset", name="Sunset", description="", image="sunset", type="BACKGROUND", rarity=1),
    Cosmetic(id="tiger", name="Tiger", description="", image="tiger", type="BACKGROUND"),
    Cosmetic(id="whiteroom", name="Whiteroom", description="", image="whiteroom", type="BACKGROUND"),
    Cosmetic(id="woodframe", name="Wood Frame", description="", image="woodframe", type="BACKGROUND", rarity=1),
    Cosmetic(
        id="woodframe_black",
        name="Black Wood Frame",
        description="",
        image="woodframe_black",
        type="BACKGROUND",
        rarity=1,
    ),
    Cosmetic(
        id="woodframe_blue", name="Blue Wood Frame", description="", image="woodframe_blue", type="BACKGROUND", rarity=1
    ),
    Cosmetic(
        id="woodframe_green",
        name="Green Wood Frame",
        description="",
        image="woodframe_green",
        type="BACKGROUND",
        rarity=1,
    ),
    Cosmetic(
        id="woodframe_red", name="Red Wood Frame", description="", image="woodframe_red", type="BACKGROUND", rarity=1
    ),
    Cosmetic(
        id="woodframe_white",
        name="White Wood Frame",
        description="",
        image="woodframe_white",
        type="BACKGROUND",
        rarity=1,
    ),
    Cosmetic(id="yellow", name="Yellow", description="", image="yellow", type="BACKGROUND"),
    Cosmetic(id="zebra", name="Zebra", description="", image="zebra", type="BACKGROUND", rarity=2),
    # Cats
    None,  # was Actually Invisible Cat
    Cosmetic(id="angelcat", name="Angel Cat", description="", image="angelcat", type="AVATAR"),
    Cosmetic(id="angrycat", name="Angry Cat", description="", image="angrycat", type="AVATAR"),
    Cosmetic(id="blackcat", name="Black Cat", description="", image="blackcat", type="AVATAR"),
    Cosmetic(id="blankcat", name="Blank Cat", description="", image="blankcat", type="AVATAR"),
    Cosmetic(id="brownsuitcat", name="Brown Suit Cat", description="", image="brownsuitcat", type="AVATAR"),
    Cosmetic(id="catptain", name="Catptain", description="", image="catptain", type="AVATAR"),
    Cosmetic(id="cutecat", name="Cute Cat", description="", image="cutecat", type="AVATAR", rarity=1),
    Cosmetic(id="cyclopscat", name="Cyclops Cat", description="", image="cyclopscat", type="AVATAR", rarity=1),
    Cosmetic(id="demonicat", name="Demonicat", description="", image="demonicat", type="AVATAR", rarity=2),
    Cosmetic(id="diamondcat", name="Diamond Cat", description="", image="diamondcat", type="AVATAR", rarity=1),
    Cosmetic(id="emeraldcat", name="Emerald cat", description="", image="emeraldcat", type="AVATAR", rarity=1),
    Cosmetic(id="fatcat", name="Fat Cat", description="", image="fatcat", type="AVATAR"),
    Cosmetic(id="goldencat", name="Golden Cat", description="", image="goldencat", type="AVATAR", rarity=2),
    Cosmetic(id="graycat", name="Gray Cat", description="", image="graycat", type="AVATAR"),
    Cosmetic(id="greenscarfcat", name="Green Scarf Cat", description="", image="greenscarfcat", type="AVATAR"),
    Cosmetic(id="invisiblecat", name="Invisible Cat", description="", image="invisiblecat", type="AVATAR", rarity=1),
    Cosmetic(id="negacat", name="Negative Cat", description="", image="negacat", type="AVATAR", rarity=2),
    Cosmetic(id="orangecat", name="Orange Cat", description="", image="orangecat", type="AVATAR", rarity=1),
    Cosmetic(id="plushcat", name="Plush Cat", description="", image="plushcat", type="AVATAR"),
    Cosmetic(id="purplescarfcat", name="Purple Scarf Cat", description="", image="purplescarfcat", type="AVATAR"),
    Cosmetic(id="quizzicalcat", name="Quizzical Cat", description="", image="quizzicalcat", type="AVATAR", rarity=1),
    Cosmetic(id="reanimatedcat", name="Re-Animated Cat", description="", image="reanimatedcat", type="AVATAR"),
    Cosmetic(id="redscarfcat", name="Red Scarf Cat", description="", image="redscarfcat", type="AVATAR"),
    Cosmetic(id="rubycat", name="Ruby Cat", description="", image="rubycat", type="AVATAR"),
    Cosmetic(id="sadcat", name="Sad Cat", description="", image="sadcat", type="AVATAR"),
    Cosmetic(id="silvercat", name="Silver Cat", description="", image="silvercat", type="AVATAR"),
    Cosmetic(id="stripedcat", name="Striped Cat", description="", image="stripedcat", type="AVATAR"),
    Cosmetic(id="surprisedcat", name="Surprised Cat", description="", image="surprisedcat", type="AVATAR"),
    Cosmetic(id="triplecat", name="Triple Cat", description="", image="triplecat", type="AVATAR"),
    Cosmetic(id="tuffcat", name="Tuff Cat", description="", image="tuffcat", type="AVATAR"),
    Cosmetic(id="tuxcat", name="Tuxedo Cat", description="", image="tuxcat", type="AVATAR", rarity=2),
    # Hats
    Cosmetic(id="blackcap", name="Black Cap", description="", image="blackcap", type="HAT", offset_x=-1, offset_y=8),
    Cosmetic(id="bluecap", name="Blue Cap", description="", image="bluecap", type="HAT", offset_x=1.5, offset_y=5),
    Cosmetic(id="buckethat", name="Bucket Hat", description="", image="buckethat", type="HAT", offset_y=11, rarity=1),
    Cosmetic(id="conehat", name="Cone Hat", description="", image="conehat", type="HAT", offset_y=6, rarity=1),
    Cosmetic(id="cowboyhat", name="Cowboy Hat", description="", image="cowboyhat", type="HAT", offset_y=6),
    Cosmetic(id="crown", name="Crown", description="", image="crown", type="HAT", offset_y=5, rarity=2),
    Cosmetic(
        id="divinghelmet", name="Diving Helmet", description="", image="divinghelmet", type="HAT", offset_y=12, rarity=1
    ),
    Cosmetic(
        id="fishinghat", name="Fishing Hat", description="", image="fishinghat", type="HAT", offset_x=-0.5, offset_y=6
    ),
    Cosmetic(id="ghost", name="Ghost", description="", image="ghost", type="HAT", offset_x=-0.5, offset_y=15, rarity=1),
    Cosmetic(id="halo", name="Halo", description="", image="halo", type="HAT", offset_y=2),
    Cosmetic(id="kitten", name="Kitten", description="", image="kitten", type="HAT", offset_y=4, rarity=1),
    Cosmetic(id="mafiahat", name="Mafia Hat", description="", image="mafiahat", type="HAT", offset_y=5),
    Cosmetic(
        id="monkblindfold",
        name="Monk Blindfold",
        description="",
        image="monkblindfold",
        type="HAT",
        offset_x=-0.5,
        offset_y=8,
        rarity=2,
    ),
    Cosmetic(
        id="orangecap", name="Orange Cap", description="", image="orangecap", type="HAT", offset_x=1.5, offset_y=5
    ),
    Cosmetic(
        id="pinkcap", name="Pink Cap", description="", image="pinkcap", type="HAT", offset_x=0.5, offset_y=9, rarity=1
    ),
    Cosmetic(
        id="piratehat", name="Pirate Hat", description="", image="piratehat", type="HAT", offset_x=-0.5, offset_y=6
    ),
    Cosmetic(
        id="rainbowcap", name="Rainbow Cap", description="", image="rainbowcap", type="HAT", offset_x=1.5, offset_y=5
    ),
    Cosmetic(id="redcap", name="Red Cap", description="", image="redcap", type="HAT", offset_x=1.5, offset_y=5),
    Cosmetic(
        id="stache", name="Stache", description="", image="stache", type="HAT", offset_x=0.5, offset_y=13, rarity=1
    ),
    Cosmetic(id="tinyhat", name="Tiny Hat", description="", image="tinyhat", type="HAT", offset_y=4),
    Cosmetic(id="tophat", name="Top Hat", description="", image="tophat", type="HAT", offset_y=5, rarity=2),
    Cosmetic(id="whitecap", name="White Cap", description="", image="whitecap", type="HAT", offset_x=1.5, offset_y=5),
    Cosmetic(
        id="yellowcap", name="Yellow Cap", description="", image="yellowcap", type="HAT", offset_x=1.5, offset_y=5
    ),
    # Add new items below, not above!
]

RARITY = {
    0: Rarity(name="Common", color="95BEED", weight=80),
    1: Rarity(name="Rare", color="F2CF83", weight=15),
    2: Rarity(name="Legendary", color="C7002E", weight=5),
}


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
    granted_manually: bool
    background_color: str
    name_color: str
    granted_manually: bool
    price: str | None = None
    exchange: str | None = None
    auto_stack: bool | None = None
    purchase_limit: int | None = None


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

    # This has to be dict, the key is the indices in COSMETICS list.
    cosmetic_items: dict[int, SteamItem] = {}

    for i, cosmetic in enumerate(COSMETICS):
        if cosmetic is None:
            continue

        format = {"base_url": BASE_IMAGE_URL, "type": cosmetic.type, "image": cosmetic.id}
        rarity = RARITY[cosmetic.rarity]
        si = SteamItem(
            itemdefid=i + COSMETIC_ITEMDEF_ID_START + 1,
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
            granted_manually=True,
            background_color=rarity.color,
            name_color=rarity.color,
            price="1;VLV25",  # Change this if needed
            auto_stack=True,
        )
        if isinstance(cosmetic.name, dict):
            populate_localized(si, "name", cosmetic.name)
        if isinstance(cosmetic.description, dict):
            populate_localized(si, "name", cosmetic.description)
        cosmetic_items[i] = si

    rarity_chest = {
        k: SteamItem(
            itemdefid=i,
            type="generator",
            bundle=";".join(
                f"{cobj.itemdefid}x1"
                for ci, cobj in cosmetic_items.items()
                if cast(Cosmetic, COSMETICS[ci]).rarity == k
            ),
            name=f"{v.name} Chest Generator",
            description=f"{v.name} Chest Generator",
            icon_url=f"{BASE_IMAGE_URL}/cosmetics/chest.png",
            icon_url_large=f"{BASE_IMAGE_URL}/cosmetics/chest_large.png",
            tradable=False,
            marketable=False,
            granted_manually=True,
            background_color="FFFFFF",
            name_color="FFFFFF",
        )
        for i, (k, v) in enumerate(RARITY.items(), CHEST_GENERATOR_ITEMDEF_ID + 1)
    }

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
                granted_manually=True,
                background_color="FFFFFF",
                name_color="FFFFFF",
                auto_stack=True,
            ),
            SteamItem(
                itemdefid=CHEST_GENERATOR_ITEMDEF_ID,
                type="generator",
                bundle=";".join(f"{c.itemdefid}x{RARITY[i].weight}" for i, c in rarity_chest.items()),
                name="Chest Generator",
                description="Cosmetic Chest Generator",
                icon_url=f"{BASE_IMAGE_URL}/cosmetics/chest.png",
                icon_url_large=f"{BASE_IMAGE_URL}/cosmetics/chest_large.png",
                tradable=False,
                marketable=False,
                exchange=f"{CHEST_ITEMDEF_ID}x1",
                granted_manually=True,
                background_color="FFFFFF",
                name_color="FFFFFF",
            ),
            *rarity_chest.values(),
            *cosmetic_items.values(),
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
        f.write("    local map = {}")

        for itemdefid, c in enumerate(COSMETICS, COSMETIC_ITEMDEF_ID_START + 1):
            if c is None:
                continue

            tabledef: list[str] = []
            if c.image != c.id:
                tabledef.append(f"image = {c.image!r}")
            if c.offset_x:
                tabledef.append(f"offsetX = {c.offset_x!r}")
            if c.offset_y:
                tabledef.append(f"offsetY = {c.offset_y!r}")
            if c.rarity:
                tabledef.append(f"rarity = {c.rarity!r}")

            f.write(f"    defineCosmetic({c.type!r}, {c.id!r}, {c.name!r}, {{{', '.join(tabledef)}}})\n")
            f.write(f"    map[{c.id!r}] = {itemdefid!r} map[{itemdefid!r}] = {c.id!r}\n")

        f.write("    return map\nend\n")


if __name__ == "__main__":
    main(find_game_root())
