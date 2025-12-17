# Note: Run this first then unbleed.

import glob
import pathlib

import PIL.Image
import colour
import numpy
import tqdm

from util import find_game_root

from numpy.typing import NDArray

# Configurable thing
DRY_RUN = False  # Set to true to only list assets to be processed.
QUANTIZE_IN_RGB = False  # If True, quantize in RGB instead of Oklab
PALETTE_PATH = "assets/palette.png"  # Relative to main.lua
BLACKLIST = [  # List of assets to be excluded
    "src/modules/vignette/vignette.png",
]
# End of Configurable thing

MAIN_DIR = find_game_root()


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


def get_input_palette(path: str | pathlib.Path):
    pal_pil = PIL.Image.open(path).convert("RGBA")
    pal_np = pil_to_numpy_float32(pal_pil).reshape(-1, 4)
    # Only select non-fully-transparent color, discarding the alpha
    pal_rgb = numpy.unique(pal_np[pal_np[:, 3] > 0][:, :3], axis=0)
    return pal_rgb


def quantize_image_smolsize(img: NDArray[numpy.float32], palette: NDArray[numpy.float32]):
    dist = img.reshape(-1, 3)[:, None, :] - palette[None, :, :]
    # Squared Euclidean distances to all palette colors
    dist2 = numpy.sum(dist**2, axis=2)  # (H*W, N)

    # Find nearest palette color index for each pixel
    nearest_idx = numpy.argmin(dist2, axis=1)  # (H*W,)

    # Map back
    quantized = palette[nearest_idx].reshape(img.shape)

    return quantized


_blacklist = set(map(pathlib.Path, BLACKLIST))


def filter_blacklist(file: str):
    try:
        pathobj = pathlib.Path(file).relative_to(MAIN_DIR)
        return pathobj not in _blacklist
    except ValueError:
        return True


def transform_images(pathglob: str, pal: NDArray[numpy.float32], recursive: bool = True):
    tobeglob = MAIN_DIR / pathglob
    files = list(filter(filter_blacklist, glob.glob(str(tobeglob), recursive=recursive)))
    success = 0
    failed = 0

    print("Processing", len(files), "files on", tobeglob)
    for file in tqdm.tqdm(files, unit="image"):
        tqdm.tqdm.write(file)

        if DRY_RUN:
            success = success + 1
            continue

        # Process
        try:
            with PIL.Image.open(file) as image_pil:
                image_numpy = pil_to_numpy_float32(image_pil.convert("RGBA"))

            if QUANTIZE_IN_RGB:
                quantized = quantize_image_smolsize(image_numpy[:, :, :3], pal)
            else:
                input_oklab = rgb2oklab(image_numpy[:, :, :3])
                pal_oklab = rgb2oklab(pal)
                quantized_oklab = quantize_image_smolsize(input_oklab, pal_oklab)
                quantized = oklab2rgb(quantized_oklab)

            # Ok, save.
            quantized_rgba = numpy.dstack((quantized, image_numpy[:, :, 3]))
            image_pil_palletted = numpy_float32_to_pil(quantized_rgba)
            image_pil_palletted.save(file)

            tqdm.tqdm.write("✅ Success")
            success += 1
        except Exception as e:
            tqdm.tqdm.write(f"❌ Failed ({type(e).__name__}): {str(e)}")
            failed += 1

    print(success, "successful,", failed, "failed.")


if __name__ == "__main__":
    pal = get_input_palette(MAIN_DIR / PALETTE_PATH)
    transform_images("src/**/*.png", pal)
    transform_images("assets/images/**/*.png", pal)
