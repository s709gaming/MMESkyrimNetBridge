"""Ignore only display translation wrappers in existing gameplay contracts."""
import re
def unlocalize(source):
    return re.sub(r'MMELocalization\.Text\(("(?:\\.|[^"\\])*")\)',r'\1',source)
