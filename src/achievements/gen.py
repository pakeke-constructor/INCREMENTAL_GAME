
import os
from PIL import Image

os.makedirs('output', exist_ok=True)


for filename in os.listdir('input'):
    if filename.endswith('.png'):
        # Open the image
        img = Image.open(os.path.join('input', filename))
        
        # Resize to 128x128
        img_resized = img.resize((128, 128), Image.NEAREST)
        
        # Save resized image
        img_resized.save(os.path.join('output', filename))
        
        # Convert to grayscale and save
        img_gray = img_resized.convert('L')
        base_name = filename.rsplit('.', 1)[0]
        img_gray.save(os.path.join('output', f'{base_name}_grayscale.png'))



