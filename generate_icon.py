from PIL import Image, ImageDraw, ImageFont
import os

def create_icon():
    size = 1024
    img = Image.new('RGB', (size, size), color=(13, 148, 136)) # Teal color
    d = ImageDraw.Draw(img)
    
    try:
        # Try to use a common bold font
        font = ImageFont.truetype("arialbd.ttf", int(size * 0.7))
    except:
        try:
            font = ImageFont.truetype("segoeuib.ttf", int(size * 0.7))
        except:
            font = ImageFont.load_default()
            
    text = "G"
    
    # Get text bounding box for centering
    bbox = d.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    x = (size - text_width) / 2
    # Adjust y for visual centering, fonts often have extra space below
    y = (size - text_height) / 2 - (size * 0.1)
    
    d.text((x, y), text, fill=(255, 255, 255), font=font)
    
    assets_dir = r"c:\laragon\www\garden barbershop\garden_barbershop_finance\assets"
    if not os.path.exists(assets_dir):
        os.makedirs(assets_dir)
        
    img.save(os.path.join(assets_dir, "app_icon.png"))
    print("Icon created successfully.")

if __name__ == "__main__":
    create_icon()
