import unittest

from PIL import Image

import build_notification_icon as builder


class NotificationIconTest(unittest.TestCase):
    def setUp(self):
        self.logo = Image.open(builder.SOURCE).convert("RGBA")
        self.word = builder.first_word(self.logo)

    def test_the_icon_keeps_only_the_first_word(self):
        logo_width = self.logo.getchannel("A").getbbox()
        logo_width = logo_width[2] - logo_width[0]

        self.assertLess(self.word.width, logo_width * 0.4)
        self.assertGreater(self.word.height, self.word.width)

    def test_each_size_is_white_and_fills_the_square_less_the_margin(self):
        for size in builder.SIZES.values():
            icon = builder.icon(self.word, size)
            left, top, right, bottom = icon.getchannel("A").getbbox()
            colours = {pixel[:3] for pixel in icon.getdata() if pixel[3] > 0}

            self.assertEqual(icon.size, (size, size))
            self.assertGreaterEqual(bottom - top, size * 20 / 24, size)
            self.assertEqual(colours, {(255, 255, 255)}, size)


if __name__ == "__main__":
    unittest.main()
