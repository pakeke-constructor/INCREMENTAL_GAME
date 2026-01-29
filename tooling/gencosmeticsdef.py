import os
import os.path

from util import find_game_root

MAIN_DIR = find_game_root()


def write_cosmetic(path: str, type: str):
    for file in os.scandir(MAIN_DIR / path):
        if file.is_file():
            name, ext = os.path.splitext(file.name)
            if ext.lower() == ".png":
                print(
                    f"    Cosmetic(id={name!r}, name='{name.capitalize()}', description='', image={name!r}, type={type!r}),"
                )


print("COSMETICS = [")
write_cosmetic("src/cosmetics/backgrounds", "BACKGROUND")
write_cosmetic("src/cosmetics/cats", "AVATAR")
write_cosmetic("src/cosmetics/hats", "HAT")
print("]")
