import asyncio
import collections.abc
import pathlib
import os
import shutil

from make_cosmetics import COSMETICS, COSMETIC_IMAGE_FORMAT, COSMETIC_IMAGE_LARGE_FORMAT
from util import find_game_root

CONCURRENT_PROCESS = max(os.cpu_count() or 1, 1)
COSMETIC_TYPE_MAP = {"HAT": "hats", "AVATAR": "cats", "BACKGROUND": "backgrounds"}

magick = shutil.which("magick")
if magick is None:
    raise RuntimeError("ImageMagick not found")


async def create_icon(root: pathlib.Path, fmt: str, costype: str, image: str, scale: float):
    assert magick, "ImageMagick not found"

    source = root / "src/cosmetics" / COSMETIC_TYPE_MAP[costype] / f"{image}.png"
    dest = os.path.normpath(fmt % {"base_url": str(root / ".cosmetics"), "type": costype, "image": image})
    process = await asyncio.create_subprocess_exec(
        magick,
        str(source),
        "-sample",
        f"{int(scale * 100)}%",
        dest,
    )

    if (await process.wait()) != 0:
        raise RuntimeError(f"magick exited with code {process.returncode}")


async def main(root: pathlib.Path):
    for path in COSMETIC_TYPE_MAP.keys():
        os.makedirs(root / ".cosmetics/cosmetics" / path, exist_ok=True)

    semaphore = asyncio.Semaphore(CONCURRENT_PROCESS)

    async def run_max_concurrent(awaitable: collections.abc.Awaitable[None]):
        async with semaphore:
            await awaitable

    tasks = [
        *[create_icon(root, COSMETIC_IMAGE_FORMAT, c.type, c.image, 10) for c in COSMETICS if c is not None],
        *[create_icon(root, COSMETIC_IMAGE_LARGE_FORMAT, c.type, c.image, 96) for c in COSMETICS if c is not None],
    ]
    tasks2 = [run_max_concurrent(t) for t in tasks]
    await asyncio.gather(*tasks2)


if __name__ == "__main__":
    asyncio.run(main(find_game_root()))
