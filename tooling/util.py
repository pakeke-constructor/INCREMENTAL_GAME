import pathlib

import PIL.Image
import colour
import numpy

from numpy.typing import NDArray

PARENT_ITER_DIR = 4  # How many parent iteration to find main.lua
SCRIPT_FILE = pathlib.Path(__file__)


# Find main.lua
def find_main_lua():
    main_dir = None
    for i in range(PARENT_ITER_DIR):
        if (SCRIPT_FILE.parents[i] / "main.lua").is_file():
            main_dir = SCRIPT_FILE.parents[i]
            break
    if main_dir is None:
        raise RuntimeError("Cannot determine game project root")
    return main_dir


def rgb2oklab(rgb: NDArray[numpy.float32]):
    xyz = colour.sRGB_to_XYZ(rgb)
    oklab = colour.XYZ_to_Oklab(xyz)
    return oklab.astype(numpy.float32)


def oklab2rgb(oklab: NDArray[numpy.float32]):
    xyz = colour.Oklab_to_XYZ(oklab)
    rgb = colour.XYZ_to_sRGB(xyz)
    return rgb.astype(numpy.float32)


def pil_to_numpy_float32(img: PIL.Image.Image) -> NDArray[numpy.float32]:
    return numpy.array(img, numpy.uint8).astype(numpy.float32) / 255.0


def numpy_float32_to_pil(img: NDArray[numpy.float32]):
    u8 = (img * 255.0 + 0.5).clip(0.0, 255.0).astype(numpy.uint8)
    pil = PIL.Image.fromarray(u8)
    return pil
