

from PIL import Image, ImageDraw
import colorsys



def merge_vertically(images):
    h = 0
    w = 0
    buf = []
    for img in images:
        if isinstance(img, str):
            img = Image.open(img).convert('RGBA')
        buf.append(img)
        h += img.height
        w = max(w, img.width)

    hh = 0
    combined = Image.new('RGBA', (w,h))
    for b in buf:
        combined.paste(b, (0,hh))
        hh+=b.height
    
    combined.save("input_merged.png")


def compare_images(img1, img2, output_path):
    PAD = 30
    combined = Image.new('RGBA', (img1.width + img2.width + PAD, img1.height))
    combined.paste(img1, (0, 0))
    combined.paste(img2, (img1.width + PAD, 0))
    combined.save(output_path)


def contains_pink_or_purple(img):
    img = img.convert("RGB")
    pixels = img.getdata()
    
    ct = 0
    for r, g, b in pixels:
        r, g, b = [v / 255.0 for v in (r, g, b)]
        h, s, v = colorsys.rgb_to_hsv(r, g, b)
        h_deg = h * 360
        if 260 <= h_deg <= 340 and s > 0.25 and v > 0.2:
            ct += 1
    
    # if more than 6 pixels are pink/purple, dont include it.
    return ct > 6


def strip_nasty(img):
    SZE=16
    for y in range(0, img.height, SZE):
        for x in range(0, img.width, SZE):
            box = (x, y, x + SZE, y + SZE)
            
            region = img.crop(box)
            if contains_pink_or_purple(region):
                # fill with black
                draw = ImageDraw.Draw(img)
                draw.rectangle(box, fill=(0,0,0))




def save_palette(palette, name, num_colors_to_sort):
    H=30
    relevant_palette = palette[:num_colors_to_sort * 3]
    
    rgb_colors = []
    for i in range(num_colors_to_sort):
        r = relevant_palette[i * 3 + 0]
        g = relevant_palette[i * 3 + 1]
        b = relevant_palette[i * 3 + 2]
        rgb_colors.append((r, g, b))

    hsv_data = []
    for r, g, b in rgb_colors:
        r_norm, g_norm, b_norm = r / 255.0, g / 255.0, b / 255.0
        h, s, v = colorsys.rgb_to_hsv(r_norm, g_norm, b_norm)
        hsv_data.append(((h, s, v), (r, g, b)))
    
    def sortkey(tup):
        hsv = tup[0]
        h,s,v = hsv
        return h*4 + s/3 + v/2

    hsv_data.sort(key=sortkey)

    img = Image.new("RGB", (num_colors_to_sort, H))

    for i in range(num_colors_to_sort):
        r, g, b = hsv_data[i][1]
        draw = ImageDraw.Draw(img)
        box = (i,0,i+1,H-1)
        draw.rectangle(box, fill=(r,g,b))
        
    img.save(name)


def quantize_image(input_path, output_path, num_colors=256):
    img = Image.open(input_path)
    og_img = img
    has_alpha = img.mode in ('RGBA', 'LA') or 'transparency' in img.info
    alpha = img.getchannel('A') if has_alpha else None
    img = img.convert('RGB')

    print("num:",len(img.getcolors(maxcolors=10000)))
    copy = img.copy()
    # strip_nasty(copy)

    #method = Image.Quantize.MEDIANCUT
    method = Image.Quantize.MAXCOVERAGE
    quantized = copy.quantize(colors=num_colors, method=method)

    result = quantized.convert('RGBA')
    if alpha:
        result.putalpha(alpha)
    result.save(output_path)

    compare_images(og_img, result, "output_compared.png")
    palette = quantized.getpalette()
    save_palette(palette, "output_palette.png", num_colors)



def quantize_to_palette(input_path, output_path, palette_image_path):
    img = Image.open(input_path)
    has_alpha = img.mode in ('RGBA', 'LA') or 'transparency' in img.info
    alpha = img.getchannel('A') if has_alpha else None
    
    img = img.convert('RGB')
    
    # Load the palette from an existing palette image
    palette_img = Image.open(palette_image_path)
    if palette_img.mode != 'P':
        palette_img = palette_img.convert('P')
    
    method = Image.Quantize.MEDIANCUT
    #method = Image.Quantize.MAXCOVERAGE
    # Quantize to the loaded palette
    quantized = img.quantize(
        palette=palette_img,
        dither=Image.Dither.FLOYDSTEINBERG,
        method=method
    )
    
    result = quantized.convert('RGB', method)
    if alpha:
        result.putalpha(alpha)
    
    result.save(output_path)



def main1():
    merge_vertically(["input1.png", "input2.png", "input3.png"])
    quantize_to_palette("input_merged.png", "output_merged.png", "palette_1.png")


def main2():
    merge_vertically(["input1.png", "input2.png", "input3.png"])
    quantize_image("input_merged.png", "output_merged.png")


main2()

