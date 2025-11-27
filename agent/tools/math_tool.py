import re

def calc(expr: str):
    # Allow ONLY math characters
    if not re.match(r"^[0-9+\-*/().\s]+$", expr):
        return "MathTool can only calculate numeric math expressions."
    
    try:
        return str(eval(expr))
    except Exception:
        return "Invalid math expression."
