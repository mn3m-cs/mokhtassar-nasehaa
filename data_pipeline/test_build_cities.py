import unittest

import build_cities


def row(geonames_id, name, code, population, feature="PPL", lat="30.0", lng="31.0", alternates=""):
    columns = [""] * 19
    columns[0] = geonames_id
    columns[1] = name
    columns[2] = name
    columns[3] = alternates
    columns[4] = lat
    columns[5] = lng
    columns[7] = feature
    columns[8] = code
    columns[14] = str(population)
    return columns


class SelectionTest(unittest.TestCase):
    def test_capitals_are_always_kept(self):
        self.assertTrue(build_cities.selected(row("1", "Vaduz", "LI", 5000, "PPLC")))

    def test_thresholds_follow_the_country_group(self):
        self.assertTrue(build_cities.selected(row("1", "Tanta", "EG", 150_000)))
        self.assertFalse(build_cities.selected(row("1", "Small", "EG", 149_999)))
        self.assertTrue(build_cities.selected(row("1", "Konya", "TR", 700_000)))
        self.assertFalse(build_cities.selected(row("1", "Small", "TR", 699_999)))
        self.assertTrue(build_cities.selected(row("1", "Lyon", "FR", 2_000_000)))
        self.assertFalse(build_cities.selected(row("1", "Lyon", "FR", 1_999_999)))


class EntriesTest(unittest.TestCase):
    def test_places_without_an_arabic_name_are_dropped_and_the_rest_sorted(self):
        rows = [
            row("3", "Riyadh", "SA", 1, lat="24.68772", lng="46.72185"),
            row("1", "Cairo", "EG", 1, lat="30.06263", lng="31.24967"),
            row("2", "Nowhere", "EG", 1),
            row("4", "Alexandria", "EG", 1, lat="31.20176", lng="29.91582"),
        ]
        cities = {"1": "القاهرة", "3": "الرياض", "4": "الإسكندرية"}
        countries = {"EG": "مصر", "SA": "السعودية"}

        self.assertEqual(
            build_cities.entries(rows, cities, countries),
            [
                ["الرياض", "السعودية", "SA", 24.6877, 46.7219],
                ["الإسكندرية", "مصر", "EG", 31.2018, 29.9158],
                ["القاهرة", "مصر", "EG", 30.0626, 31.2497],
            ],
        )

    def test_the_same_name_twice_in_one_country_is_kept_once(self):
        rows = [row("1", "A", "EG", 1), row("2", "B", "EG", 1)]
        cities = {"1": "القاهرة", "2": "القاهرة"}

        self.assertEqual(len(build_cities.entries(rows, cities, {"EG": "مصر"})), 1)


class FallbackNameTest(unittest.TestCase):
    def test_an_english_match_is_kept_only_when_geonames_has_the_same_name(self):
        algiers = row("1", "Algiers", "DZ", 1, alternates="Alger,ئالجىر,الجزائر,الجزائر العاصمة")
        tangier = row("2", "Tangier", "MA", 1, alternates="Tanger,تنجه,طنجة")

        self.assertEqual(build_cities.fallback_name(algiers, "الجزائر العاصمة"), "الجزائر العاصمة")
        self.assertIsNone(build_cities.fallback_name(tangier, "جماعة بني شيكر"))

    def test_spelling_differences_between_the_sources_still_match(self):
        dushanbe = row("1", "Dushanbe", "TJ", 1, alternates="Dushanbe,دوشنبه")

        self.assertEqual(build_cities.fallback_name(dushanbe, "دوشنبة"), "دوشنبة")

    def test_a_single_arabic_alternate_is_used_without_a_match(self):
        ras = row("1", "Ras Al Khaimah", "AE", 1, alternates="RAK,راس الخيمة")
        hufuf = row("2", "Al Hufuf", "SA", 1, alternates="الهفوف,هفوف")

        self.assertEqual(build_cities.fallback_name(ras, None), "راس الخيمة")
        self.assertIsNone(build_cities.fallback_name(hufuf, None))


if __name__ == "__main__":
    unittest.main()
