import glob
import pathlib

import PIL.Image
import colour
import numpy

from util import find_game_root

from numpy.typing import NDArray

COLORS = 128
MEDIAN_CUT_IN_RGB = False  # If True, perform Median Cut in RGB instead of Oklab


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


def median_cut(bucket: list[NDArray[numpy.float32]]):
    if len(bucket) == 0:
        raise ValueError("Bucket is empty")

    target_channel = -1
    target_index = -1
    best_range = -1

    for i, arr in enumerate(bucket):
        image_range: NDArray[numpy.float32] = arr.max(0) - arr.min(0)
        target_channel = image_range.argmax(0)

        image_range_max: int = image_range.max().item()
        if image_range_max > best_range:
            best_range = image_range_max
            target_index = i

    image_numpy_flatten = bucket.pop(target_index)
    sorted_pixels = image_numpy_flatten[image_numpy_flatten[:, target_channel].argsort()]
    sorted_pixels = sorted_pixels.astype(numpy.float32)
    cut_index = sorted_pixels.shape[0] // 2
    bucket.append(sorted_pixels[:cut_index])
    bucket.append(sorted_pixels[cut_index:])


def average_image_array(bucket: list[NDArray[numpy.float32]]):
    for pixels in bucket:
        pmean: NDArray[numpy.float32] = pixels.astype(numpy.float32).mean(0)
        yield pmean


def make_palette(image: NDArray[numpy.float32], n: int):
    bucket = [image.reshape(-1, 3)]

    while len(bucket) < n:
        median_cut(bucket)

    return numpy.vstack(list(average_image_array(bucket)), dtype=numpy.float32)


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
    input_flat = merged_input.reshape(-1, 4)
    input_rgb = input_flat[input_flat[:, 3] > 0][:, :3]
    print("Generating palette with", COLORS, "colors in", "RGB" if MEDIAN_CUT_IN_RGB else "Oklab")

    if MEDIAN_CUT_IN_RGB:
        output_rgb = make_palette(input_rgb, COLORS)
    else:
        input_oklab = rgb2oklab(input_rgb)
        output_oklab = make_palette(input_oklab, COLORS)
        output_rgb = oklab2rgb(output_oklab)

    print("Saving")
    output = numpy_float32_to_pil(output_rgb.reshape(1, -1, 3))
    output.save(MAIN_DIR / "assets" / "palette1.png")


if __name__ == "__main__":
    main()
