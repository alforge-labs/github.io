import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class HomepageFreeStartTest(unittest.TestCase):
    def test_free_start_copy_exists_in_both_languages(self):
        copy = read("homepage-copy.jsx")

        self.assertIn("freeStart", copy)
        self.assertIn("無料で検証を始める", copy)
        self.assertIn("Start validating for free", copy)
        self.assertIn("データは2023年まで", copy)
        self.assertIn("Data through 2023", copy)
        self.assertIn("最適化50回", copy)
        self.assertIn("50 optimization trials", copy)
        self.assertIn("Pine Script生成なし", copy)
        self.assertIn("No Pine Script export", copy)

    def test_free_start_component_is_rendered_after_hero(self):
        components = read("homepage-components.jsx")
        app = read("homepage-app.jsx")

        self.assertIn("function FreeStart", components)
        self.assertIn('className="free-start reveal"', components)
        self.assertIn("Object.assign(window, { NavBar, Hero, FreeStart", components)
        self.assertIn('href={`/${lang}/install.html`}', components)
        self.assertIn('href="#pricing"', components)

        hero_pos = app.index("<Hero t={t} lang={lang} />")
        free_start_pos = app.index("<FreeStart t={t} lang={lang} />")
        products_pos = app.index("<Products t={t} />")
        self.assertLess(hero_pos, free_start_pos)
        self.assertLess(free_start_pos, products_pos)

    def test_generated_pages_include_free_start_styles(self):
        template = read("templates/index.html.j2")
        ja_html = read("ja/index.html")
        en_html = read("en/index.html")

        self.assertIn(".free-start", template)
        self.assertIn(".free-start-steps", template)
        self.assertIn("free-start", ja_html)
        self.assertIn("free-start", en_html)


if __name__ == "__main__":
    unittest.main()
