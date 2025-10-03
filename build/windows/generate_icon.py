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

    cmd = [magick, CURRENT_DIR / ".." / "icon_main_replace_this_only.png"]
    for size in ICON_SIZES:
        cmd.extend(("(", "-clone", "0", "-scale", f"{size}x{size}", ")"))
    cmd.append("icon.ico")
    subprocess.run(cmd).check_returncode()


if __name__ == "__main__":
    main()
