import sys

import httpx
import tqdm

from make_cosmetics import BASE_IMAGE_URL, COSMETICS, COSMETIC_IMAGE_FORMAT, COSMETIC_IMAGE_LARGE_FORMAT


async def validate(client: httpx.AsyncClient, url: str):
    response = await client.head(url)
    match response.status_code:
        case 200:
            ctype = response.headers.get("Content-Type")
            if ctype != "image/png":
                print(f"'{url}' says the content type is '{ctype}', but expected 'image/png'")
                return False
            return True
        case 404:
            print(f"'{url}' says \"not found\"")
        case _:
            print(f"'{url}' says \"HTTP {response.status_code}\"")
    return False


async def main():
    success = True

    async with httpx.AsyncClient() as client:
        with tqdm.tqdm(total=len(COSMETICS) * 2, unit="image") as pbar:
            for cosmetic in filter(None, COSMETICS):
                format = {"base_url": BASE_IMAGE_URL, "type": cosmetic.type, "image": cosmetic.id}

                if not await validate(client, COSMETIC_IMAGE_FORMAT % format):
                    success = False
                pbar.update()
                if not await validate(client, COSMETIC_IMAGE_LARGE_FORMAT % format):
                    success = False
                pbar.update()

    if not success:
        print("Some images were failed to be validated")

    return int(not success)


if __name__ == "__main__":
    import asyncio

    sys.exit(asyncio.run(main()))
