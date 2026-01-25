# Note: Run apply_palette first then this.

import collections
import glob
import pathlib

import PIL.Image
import numpy
import tqdm

from util import find_game_root

from numpy.typing import NDArray

# Configurable thing
DRY_RUN = False  # Set to true to only list assets to be processed.
# End of Configurable thing

OFFSETS = [
    (-1, -1),
    (-1, 0),
    (-1, 1),
    (0, -1),
    (0, 1),
    (1, -1),
    (1, 0),
    (1, 1),
]
TRANSPARENT_BLACK = numpy.array([0, 0, 0, 0], numpy.uint8)
SCRIPT_FILE = pathlib.Path(__file__)


def alpha_bleeding(image_orig: NDArray[numpy.uint8]):
    """Modifies the image to ensure no alpha bleed when rendered with straight alpha.

    Based on https://github.com/EgoMoose/alpha-bleed/blob/main/src/alpha_bleed.rs algorithm

    Args:
        image_orig (NDArray[numpy.uint8]): 2D RGBA image.

    Returns:
        NDArray[numpy.uint8]: Fixed 2D RGBA image.
    """

    image = image_orig.copy()
    image_hr = range(image.shape[0])
    image_wr = range(image.shape[1])

    visited = image[:, :, 3] > 0
    can_sample = visited.copy()
    # Note: These tuple stores position in (y, x)
    pixel_queue = collections.deque[tuple[int, int]]()
    mutated_pixels = collections.deque[tuple[int, int]]()

    x: int
    y: int
    for y, x in numpy.argwhere(~visited):
        has_opaque_neighbor = bool(numpy.any(image[y - 1 : y + 2, x - 1 : x + 2, 3] > 0))

        if has_opaque_neighbor:
            visited[y, x] = True
            pixel_queue.append((y, x))

        image[y, x] = TRANSPARENT_BLACK

    while True:
        queue_length = len(pixel_queue)
        if queue_length == 0:
            break

        for _ in range(queue_length):
            y, x = pixel_queue.popleft()
            pixel = numpy.array([0, 0, 0], numpy.uint16)
            contributing = 0

            for ox, oy in OFFSETS:
                x_neighbor = x + ox
                y_neighbor = y + oy
                if x_neighbor in image_wr and y_neighbor in image_hr:
                    if can_sample[y_neighbor, x_neighbor]:
                        pixel += image[y_neighbor, x_neighbor, :3]
                        contributing += 1
                    elif not visited[y_neighbor, x_neighbor]:
                        visited[y_neighbor, x_neighbor] = True
                        pixel_queue.append((y_neighbor, x_neighbor))

            image[y, x, :3] = pixel // max(contributing, 1)
            mutated_pixels.append((y, x))

        while len(mutated_pixels) > 0:
            can_sample[mutated_pixels.popleft()] = True

    return image


def transform_images(pathglob: str, recursive: bool = True):
    MAIN_DIR = find_game_root()
    tobeglob = MAIN_DIR / pathglob
    files = glob.glob(str(tobeglob), recursive=recursive)
    success = 0
    failed = 0
    skip = 0

    print("Processing", len(files), "files on", tobeglob)
    for file in tqdm.tqdm(files, unit="image"):
        tqdm.tqdm.write(file)

        if DRY_RUN:
            success = success + 1
            continue

        # Process
        try:
            with PIL.Image.open(file) as image_pil:
                if image_pil.mode != "RGBA":
                    tqdm.tqdm.write("ℹ️ Skipped")
                    skip += 1
                    continue

                image_numpy = numpy.array(image_pil, numpy.uint8)

            if numpy.all(image_numpy[:, :, 3] > 0):
                tqdm.tqdm.write("ℹ️ Skipped")
                skip += 1
                continue

            image_unbleed = alpha_bleeding(image_numpy)

            # Sanity check (non-fully-transparent pixel shouldn't be touched)
            image_unbleed_opaque = numpy.astype(image_unbleed[:, :, :3] * (image_unbleed[:, :, 3:4] > 0), numpy.int16)
            image_numpy_opaque = numpy.astype(image_numpy[:, :, :3] * (image_numpy[:, :, 3:4] > 0), numpy.int16)
            diff = numpy.sum((image_numpy_opaque - image_unbleed_opaque) ** 2)
            if diff != 0:
                raise RuntimeError(f"Opaque pixels are touched (diff = {diff})")

            # Ok, save.
            image_pil_unbleed = PIL.Image.fromarray(image_unbleed)
            image_pil_unbleed.save(file)

            tqdm.tqdm.write("✅ Success")
            success += 1
        except Exception as e:
            tqdm.tqdm.write(f"❌ Failed ({type(e).__name__}): {str(e)}")
            failed += 1

    print(success, "successful,", failed, "failed,", skip, "skipped.")


if __name__ == "__main__":
    transform_images("src/**/*.png")
    transform_images("assets/images/**/*.png")
