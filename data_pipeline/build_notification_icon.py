"""Builds the reminder notification's small icon from the app's monochrome logo.

The full wordmark «زاد الذاكر» is too wide to read at 24 dp, so the icon keeps
only its first word, «زاد», in the logo's own lettering: white on transparent,
as Android requires for a notification icon, filling the 24 dp square with a
1 dp margin.

Run from the repository root: python3 data_pipeline/build_notification_icon.py
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent / "alazkar"
SOURCE = ROOT / "assets" / "icons" / "icon-monochrome.png"
RES = ROOT / "android" / "app" / "src" / "main" / "res"
SIZES = {"mdpi": 24, "hdpi": 36, "xhdpi": 48, "xxhdpi": 72, "xxxhdpi": 96}
MARGIN_DP = 1
VISIBLE = 40


def first_word(logo):
    """The rightmost word of the wordmark: Arabic is read right to left."""
    alpha = logo.getchannel("A")
    left, top, right, bottom = alpha.getbbox()
    widest, word_left = 0, left
    gap_start = None
    for x in range(left, right):
        empty = all(alpha.getpixel((x, y)) <= VISIBLE for y in range(top, bottom))
        if empty and gap_start is None:
            gap_start = x
        if not empty and gap_start is not None:
            if x - gap_start > widest:
                widest, word_left = x - gap_start, x
            gap_start = None
    word = logo.crop((word_left, 0, right, logo.height))
    return word.crop(word.getchannel("A").getbbox())


def icon(word, size):
    inner = size - 2 * round(size * MARGIN_DP / 24)
    scale = min(inner / word.width, inner / word.height)
    glyph = word.resize((max(1, round(word.width * scale)), max(1, round(word.height * scale))), Image.LANCZOS)
    white = Image.new("RGBA", glyph.size, (255, 255, 255, 0))
    white.putalpha(glyph.getchannel("A"))
    out = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    out.alpha_composite(white, ((size - glyph.width) // 2, (size - glyph.height) // 2))
    return out


def main():
    word = first_word(Image.open(SOURCE).convert("RGBA"))
    for density, size in SIZES.items():
        path = RES / f"drawable-{density}" / "ic_notification.png"
        icon(word, size).save(path, optimize=True)
        print(f"wrote {path.relative_to(ROOT)} ({size}px)")


if __name__ == "__main__":
    main()
