#!/usr/bin/env python3
"""Check the Play listing locally: python3 fastlane/validate_metadata.py."""

import struct
import unittest
from pathlib import Path

METADATA = Path(__file__).resolve().parent / 'metadata' / 'android'
LIMITS = {'title': 30, 'short_description': 80, 'full_description': 4000}


def validate_text(text, limit):
    """Count listing characters, ignoring only the file's final line ending."""
    value = text.removesuffix('\n')
    if not value.strip():
        raise ValueError('Listing text must not be empty')
    if value != value.strip():
        raise ValueError('Listing text has leading or trailing whitespace')
    if len(value) > limit:
        raise ValueError(f'{len(value)} characters exceeds {limit}')
    return len(value)


class StoreMetadataTest(unittest.TestCase):
    def test_listing_limits(self):
        for locale in ('ar', 'en-US'):
            for field, limit in LIMITS.items():
                with self.subTest(locale=locale, field=field):
                    count = validate_text(
                        (METADATA / locale / f'{field}.txt').read_text(), limit
                    )
                    print(f'{locale}/{field}: {count}/{limit}')

    def test_approved_arabic_and_english_titles(self):
        expected = {
            ('ar', 'title'): 'أذكار وأدعية - مختصر النصيحة',
            ('ar', 'short_description'):
                'أذكار الصباح والمساء والأدعية من «مختصر النصيحة» للشيخ محمد أحمد إسماعيل المقدم',
            ('en-US', 'title'): 'Adhkar & Dua: Mukhtasar Nasiha',
        }
        for (locale, field), value in expected.items():
            with self.subTest(locale=locale, field=field):
                self.assertEqual(
                    (METADATA / locale / f'{field}.txt').read_text().rstrip('\n'),
                    value,
                )

    def test_six_matching_phone_screenshots_at_full_size(self):
        for locale in ('ar', 'en-US'):
            folder = METADATA / locale / 'images' / 'phoneScreenshots'
            self.assertEqual(
                sorted(p.name for p in folder.iterdir()),
                [f'{i:02}.png' for i in range(6)],
            )
            for path in sorted(folder.iterdir()):
                with self.subTest(locale=locale, image=path.name):
                    data = path.read_bytes()
                    self.assertEqual(data[:8], b'\x89PNG\r\n\x1a\n')
                    self.assertEqual(struct.unpack('>II', data[16:24]), (1080, 1920))
                    self.assertEqual(
                        data,
                        (METADATA / 'ar' / 'images' / 'phoneScreenshots' / path.name).read_bytes(),
                    )

    def test_validator_accepts_boundary_and_rejects_overflow(self):
        self.assertEqual(validate_text('أ' * 80 + '\n', 80), 80)
        for text in ('أ' * 81, '', '\n', ' title', 'title \n'):
            with self.subTest(text=text), self.assertRaises(ValueError):
                validate_text(text, 80)


if __name__ == '__main__':
    unittest.main()
