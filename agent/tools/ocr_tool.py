import pytesseract
from PIL import Image

def run_ocr(image_path: str):
    try:
        img = Image.open(image_path)
        text = pytesseract.image_to_string(img)
        return text
    except Exception:
        return "[OCR Error] Could not read image."
