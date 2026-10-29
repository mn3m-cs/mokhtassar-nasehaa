#!/usr/bin/env python3
"""Compose issue #128's full-size review sheet (requires Pillow)."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
CASES = ('Index', 'Section and counter', 'Source dialog', 'Night mode',
         'Daily reminders', 'Search')


def main():
    # Each original 1080 x 1920 image is pasted without resizing.
    sheet = Image.new('RGB', (2160, 6 * 2000), 'white')
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.truetype('DejaVuSans.ttf', 36)
    for i, case in enumerate(CASES):
        y = i * 2000
        draw.text((24, y + 16), f'{i:02} Before (main)', fill='black', font=font)
        draw.text((1104, y + 16), f'{i:02} After: {case}', fill='black', font=font)
        before = ROOT / 'review' / '128' / 'before' / f'{i:02}.png'
        after = ROOT / 'metadata' / 'android' / 'ar' / 'images' / 'phoneScreenshots' / f'{i:02}.png'
        for x, path in ((0, before), (1080, after)):
            with Image.open(path) as image:
                if image.size != (1080, 1920):
                    raise ValueError(f'{path}: expected 1080 x 1920, got {image.size}')
                sheet.paste(image, (x, y + 80))
    sheet.save(ROOT / 'review' / '128' / 'before-after.png')


if __name__ == '__main__':
    main()
