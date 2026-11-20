"""Checks the static GitHub Pages site in site/.

The site is the public face of a privacy-first app, so it must load nothing from other origins,
and every visible text must exist in Korean, English and Japanese.
"""
import re
import unittest
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SITE = ROOT / "site"
PAGES = ("index.html", "privacy.html")
LANGS = ("ko", "en", "ja")
APK_HREF = "download/mood-clicker.apk"
DASHES = re.compile("[\u2013\u2014]")
CURLY = re.compile("[\u2018\u2019\u201c\u201d]")
REMOTE = re.compile(r"^(?:[a-z][a-z0-9+.-]*:)?//", re.I)


class Tags(HTMLParser):
    """Collects every start tag with its attributes."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.tags = []

    def handle_starttag(self, tag, attrs):
        self.tags.append((tag, dict(attrs)))

    handle_startendtag = handle_starttag


def read(name):
    return (SITE / name).read_text(encoding="utf-8")


def tags(name):
    parser = Tags()
    parser.feed(read(name))
    return parser.tags


def text_blocks(name, lang):
    """Elements carrying lang=..., minus the html root and the switcher labels."""
    return [
        (tag, attrs) for tag, attrs in tags(name)
        if attrs.get("lang") == lang and tag != "html" and "lang-opt" not in (attrs.get("class") or "")
    ]


class SitePages(unittest.TestCase):
    def test_both_pages_exist(self):
        for name in PAGES:
            self.assertTrue((SITE / name).is_file(), name)

    def test_every_language_has_the_same_blocks(self):
        for name in PAGES:
            counts = {lang: len(text_blocks(name, lang)) for lang in LANGS}
            self.assertGreater(counts["ko"], 0, name)
            self.assertEqual(counts["ko"], counts["en"], f"{name}: {counts}")
            self.assertEqual(counts["ko"], counts["ja"], f"{name}: {counts}")

    def test_lang_blocks_use_the_same_tags_in_the_same_order(self):
        for name in PAGES:
            shapes = {lang: [tag for tag, _ in text_blocks(name, lang)] for lang in LANGS}
            self.assertEqual(sorted(shapes["ko"]), sorted(shapes["en"]), name)
            self.assertEqual(sorted(shapes["ko"]), sorted(shapes["ja"]), name)

    def test_the_switcher_offers_three_languages(self):
        for name in PAGES:
            offered = [a.get("data-set-lang") for _, a in tags(name) if "data-set-lang" in a]
            self.assertEqual(offered, list(LANGS), name)

    def test_download_button_is_the_same_origin_apk(self):
        hrefs = [a.get("href") for tag, a in tags("index.html") if tag == "a"]
        self.assertIn(APK_HREF, hrefs)
        self.assertTrue((SITE / "icon.png").is_file())

    def test_iphone_section_is_hidden_until_build_json_says_ios(self):
        page = read("index.html")
        self.assertIn('href="download/mood-clicker.ipa"', page)
        self.assertRegex(page, r'<button role="tab" id="tab-ios"[^>]* data-ios hidden>')
        self.assertRegex(page, r'<section class="deck" id="install-ios" data-ios hidden')
        self.assertIn("[hidden] { display: none !important; }", page)
        self.assertIn("data.ios === true", page)
        self.assertIn('each("[data-ios-off]"', page)
        for lang in LANGS:
            self.assertRegex(page, rf'data-ios-off lang="{lang}"')

    def test_iphone_guide_names_the_expiry_and_the_trust_steps(self):
        blocks = read("index.html").split('id="install-ios"')[1]
        for word in ("Sideloadly", "7"):
            self.assertIn(word, blocks)

    def test_index_links_the_privacy_page(self):
        hrefs = [a.get("href") for tag, a in tags("index.html") if tag == "a"]
        self.assertIn("privacy.html", hrefs)

    def test_index_reads_build_json_and_links_commits(self):
        page = read("index.html")
        self.assertIn('fetch("build.json"', page)
        self.assertIn('var REPO = "https://github.com/jshsakura/mood-clicker";', page)
        self.assertIn('REPO + "/commit/" + info.sha', page)
        self.assertIn("https://github.com/jshsakura/mood-clicker/releases", page)

    def test_nothing_loads_from_another_origin(self):
        for name in PAGES:
            for tag, attrs in tags(name):
                if tag in ("script", "img", "iframe", "source", "audio", "video"):
                    src = attrs.get("src") or ""
                    self.assertFalse(REMOTE.search(src), f"{name}: <{tag} src={src}>")
                if tag == "link" and attrs.get("rel") in ("stylesheet", "preload", "preconnect", "icon", "apple-touch-icon"):
                    href = attrs.get("href") or ""
                    self.assertFalse(REMOTE.search(href), f"{name}: <link href={href}>")
        css = [read(name) for name in PAGES] + [(SITE / "site.css").read_text(encoding="utf-8")]
        for text in css:
            self.assertNotRegex(text, r"@import\s+(url\()?['\"]?(https?:)?//")
            self.assertNotRegex(text, r"url\(\s*['\"]?(https?:)?//")
            self.assertNotIn("fonts.googleapis", text)

    def test_fonts_are_self_hosted(self):
        for font in ("Pretendard-Regular.otf", "Pretendard-Bold.otf", "Baloo2-ExtraBold.ttf"):
            self.assertTrue((SITE / "fonts" / font).is_file(), font)

    def test_no_dashes_or_curly_quotes(self):
        for path in sorted(SITE.rglob("*")):
            if path.suffix not in (".html", ".css", ".js"):
                continue
            text = path.read_text(encoding="utf-8")
            self.assertIsNone(DASHES.search(text), path.name)
            self.assertIsNone(CURLY.search(text), path.name)

    def test_flat_style(self):
        for path in [SITE / "site.css", SITE / "index.html", SITE / "privacy.html"]:
            text = path.read_text(encoding="utf-8")
            for banned in ("gradient(", "box-shadow", "text-shadow", "backdrop-filter", "filter: blur"):
                self.assertNotIn(banned, text, f"{path.name}: {banned}")

    def test_privacy_page_keeps_the_draft_notice_and_marks_translations(self):
        page = read("privacy.html")
        self.assertIn("not legal advice", page)
        self.assertIn("Korean text prevails", page)
        self.assertEqual(len(re.findall(r"<article lang=\"(ko|en|ja)\"", page)), 3)


if __name__ == "__main__":
    unittest.main()
