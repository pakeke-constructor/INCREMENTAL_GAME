import glob
import pathlib

import PIL.Image
import colour
import numpy

from util import find_game_root

from numpy.typing import NDArray

QUANTIZE_IN_RGB = False  # If True, quantize in RGB instead of Oklab
PALETTE_PATH = "assets/palette.png"  # Relative to main.lua


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


# Always return RGBA
def stack_images(*image: str):
    base = PIL.Image.open(image[0]).convert("RGBA")

    for img in image[1:]:
        other = PIL.Image.open(img).convert("RGBA")
        composite = PIL.Image.new("RGBA", (max(base.width, other.width), base.height + other.height))
        composite.paste(base)
        composite.paste(other, (0, base.height))
        base = composite

    return pil_to_numpy_float32(base)


def main():
    MAIN_DIR = find_game_root()
    print("Scanning assets/palette_tool")
    input_paths = sorted(glob.glob(str(MAIN_DIR / "assets" / "palette_tool" / "input*.png")))
    print("Found", len(input_paths), "input images.")
    print("Loading all images.")
    merged_input = stack_images(*input_paths)
    print("Loading palette.")
    pal = get_input_palette(MAIN_DIR / PALETTE_PATH)

    if QUANTIZE_IN_RGB:
        print("Quantizing in RGB")
        quantized = quantize_image_smolsize(merged_input[:, :, :3], pal)
    else:
        print("Quantizing in Oklab")
        input_oklab = rgb2oklab(merged_input[:, :, :3])
        pal_oklab = rgb2oklab(pal)
        quantized_oklab = quantize_image_smolsize(input_oklab, pal_oklab)
        quantized = oklab2rgb(quantized_oklab)

    quantized_rgba = numpy.dstack((quantized, merged_input[:, :, 3]))
    q_pil = numpy_float32_to_pil(quantized_rgba)
    print("Saving")
    q_pil.save(MAIN_DIR / "assets" / "assets_with_palette.png")


if __name__ == "__main__":
    main()
