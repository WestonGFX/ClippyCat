import os
import logging
from PIL import Image, ImageDraw, ImageFont

def create_icon():
    try:
        icon = Image.new('RGBA', (128, 128), color=(0, 0, 0, 0))
        draw = ImageDraw.Draw(icon)
        draw.rounded_rectangle([(20, 10), (108, 118)], radius=10, fill='dodgerblue', outline='white', width=2)
        draw.polygon([(45, 10), (55, 0), (65, 10)], fill='dodgerblue', outline='white')
        draw.polygon([(75, 10), (85, 0), (95, 10)], fill='dodgerblue', outline='white')
        draw.line([(35, 35), (93, 35)], fill='white', width=2)
        draw.line([(35, 55), (93, 55)], fill='white', width=2)
        draw.line([(35, 75), (93, 75)], fill='white', width=2)
        draw.line([(35, 95), (70, 95)], fill='white', width=2)
        return icon
    except Exception as e:
        logging.exception("Failed to create icon: %s", e)
        raise

try:
    icon = create_icon()
    # Get the absolute path to the src directory and icon file
    current_dir = os.path.dirname(os.path.abspath(__file__))
    icon_path = os.path.join(current_dir, 'clippycat_icon.png')
    icon.save(icon_path)
    print(f"Icon saved to: {icon_path}")
except Exception as e:
    logging.exception("Failed to save icon: %s", e)
    raise