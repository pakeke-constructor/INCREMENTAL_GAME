import os.path
import pathlib
import shutil
import subprocess

magick = shutil.which("magick")
if magick is None:
    raise Exception("ImageMagick 7 is missing")

CURRENT_DIR = pathlib.Path(os.path.dirname(__file__))
ICON_SIZES = [32, 48, 64, 128, 256]


def main():
    assert magick is not None

    subprocess.run(
        [
            magick,
            CURRENT_DIR / "icon_main_replace_this_only.png",
            "-scale",
            "32x32",
            CURRENT_DIR / ".." / "assets" / "icon.png",
        ]
    ).check_returncode()


if __name__ == "__main__":
    main()
