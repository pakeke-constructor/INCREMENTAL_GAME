import argparse
import collections.abc

import colour  # pip install colour-science
import numpy
import PIL.Image

from typing import Literal
from numpy.typing import NDArray


def rgb2oklab(rgb: NDArray[numpy.float32]):
    xyz = colour.sRGB_to_XYZ(rgb)
    oklab = colour.XYZ_to_Oklab(xyz)
    return oklab.astype(numpy.float32)


def oklab2rgb(oklab: NDArray[numpy.float32]):
    xyz = colour.Oklab_to_XYZ(oklab)
    rgb = colour.XYZ_to_sRGB(xyz)
    return rgb.astype(numpy.float32)


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


def get_palette(image: NDArray[numpy.float32], n: int = 256):
    bucket = [image.reshape(-1, 3)]

    while len(bucket) < n:
        median_cut(bucket)

    cols = (numpy.vstack(list(average_image_array(bucket)), dtype=numpy.float32))
    print(cols)
    return cols


def get_palette_smart(image: NDArray[numpy.float32], n: int = 256):
    bucket = [image.reshape(-1, 3)]

    while len(bucket) < n:
        median_cut(bucket)

    cols = list(average_image_array(bucket))
    c = rgb2oklab(cols.pop())
    newcols = [c]
    while cols:
        best_i = 0
        best_dist = 0xfffffffffff
        for i,c1 in enumerate(cols):
            cc = rgb2oklab(c1)
            dist = numpy.linalg.norm(cc - c)
            if dist < best_dist:
                best_dist = dist
                best_i = i
        c = rgb2oklab(cols.pop(best_i))
        newcols.append(c)

    for i,c in enumerate(newcols):
        newcols[i] = oklab2rgb(c)

    cols = numpy.vstack(newcols, dtype=numpy.float32)
    
    return cols



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

    return base


def pil_to_numpy_float32(img: PIL.Image.Image) -> NDArray[numpy.float32]:
    return numpy.array(img, numpy.uint8).astype(numpy.float32) / 255.0


def numpy_float32_to_pil(img: NDArray[numpy.float32]):
    u8 = (img * 255.0 + 0.5).clip(0.0, 255.0).astype(numpy.uint8)
    pil = PIL.Image.fromarray(u8)
    return pil


class Args:
    input_merged: str | None
    palette: str | None
    colorspace: Literal["rgb", "oklab"]
    ncolors: int
    output_merged: str
    input: collections.abc.Sequence[str]


def main(args=None):
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("--input-merged", help="Where to store the merged input (optional)", default=None)
    parser.add_argument("--palette", help="Where to store the palette (optional)", default=None)
    parser.add_argument(
        "--colorspace", help="Which colorspace to use?", choices=["rgb", "oklab"], type=str.lower, default="rgb"
    )
    parser.add_argument("--ncolors", help="How many colors in the palette?", type=int, default=64)
    parser.add_argument("output_merged", help="Where to store the quantized merged output")
    parser.add_argument("input", nargs="+", help="Input image files")
    args = args or parser.parse_args(namespace=Args())

    input_merged = stack_images(*args.input)
    if args.input_merged:
        print("Writing merged input", args.input_merged)
        input_merged.save(args.input_merged)

    input_np = pil_to_numpy_float32(input_merged)
    input_rgb, input_alpha = input_np[:, :, :3], input_np[:, :, 3]

    print("Quantizing in", args.colorspace, "colorspace")
    match args.colorspace:
        case "rgb":
            pal_rgb = get_palette(input_rgb, args.ncolors)
            quantized_rgb = quantize_image_smolsize(input_rgb, pal_rgb)
        case "oklab":
            image_oklab = rgb2oklab(input_rgb)
            pal = get_palette(image_oklab, args.ncolors)
            pal_rgb = oklab2rgb(pal)
            quantized = quantize_image_smolsize(image_oklab, pal)
            quantized_rgb = oklab2rgb(quantized)
        case _:
            raise ValueError("invalid colorspace")

    if args.palette:
        print("Writing palette", args.palette)
        numpy_float32_to_pil(pal_rgb.reshape(1, -1, 3)).save(args.palette)

    quantized_rgba = numpy.dstack((quantized_rgb, input_alpha))
    quantized_pil = numpy_float32_to_pil(quantized_rgba)
    print("Writing output", args.output_merged)
    quantized_pil.save(args.output_merged)


if __name__ == "__main__":
    a = Args()
    a.input_merged = "output_merged.png"
    a.palette = "output_palette.png"
    a.colorspace = "oklab"
    a.ncolors = 64
    a.output_merged = "output_merged.png"
    a.input = ["input1.png", "input2.png", "input3.png", "input4.png", "input5.png"]

    # input_merged: str | None
    # palette: str | None
    # colorspace: Literal["rgb", "oklab"]
    # ncolors: int
    # output_merged: str
    # input: collections.abc.Sequence[str]

    main(a)

    #main()
