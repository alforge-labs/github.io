#!/usr/bin/env python3
"""SEO ビルドスクリプト: uv run python build.py

templates/*.html.j2 + seo.yaml から /ja/ と /en/ の HTML を生成し、
robots.txt と sitemap.xml も出力する。
"""
import json
import yaml
from pathlib import Path
from jinja2 import Environment, FileSystemLoader

PAGES = [
    "index",
    "install",
    "docs",
    "tutorial-strategy",
    "privacy",
    "terms",
]

# sitemap.xml から除外するページ（リダイレクト専用ページなど、独立した正規ページではないもの）。
# docs.html は install.html#commands への単純リダイレクトのため、sitemap に登録すると
# Google が「代替ページ（適切な canonical タグあり）」と判定してしまう。
SITEMAP_EXCLUDED_PAGES = {"docs"}

PAGE_FILE = {p: ("index.html" if p == "index" else f"{p}.html") for p in PAGES}


def page_url_path(page: str) -> str:
    """SEO 用 URL パス。

    index ページは末尾スラッシュのクリーン URL（``/{lang}/``）として扱い、
    それ以外は明示的な拡張子付き（``/{lang}/{file}.html``）とする。
    canonical / hreflang / sitemap でこの関数を共通利用することで、
    ``/{lang}/index.html`` と ``/{lang}/`` のような表記揺れを排除する。
    """
    return "" if page == "index" else PAGE_FILE[page]

CHANGEFREQ = {
    "index": ("weekly", 1.0),
    "docs": ("weekly", 0.9),
    "install": ("monthly", 0.8),
    "tutorial-strategy": ("monthly", 0.8),
    "privacy": ("yearly", 0.3),
    "terms": ("yearly", 0.3),
}


def build_json_ld(json_ld_type: str, base: str, lang: str, page: str, site_meta: dict) -> str:
    if json_ld_type == "home":
        offers = [
            {"@type": "Offer", "price": "0.00", "priceCurrency": "USD", "name": "Free"},
            {"@type": "Offer", "price": "9.00", "priceCurrency": "USD", "name": "Monthly"},
            {"@type": "Offer", "price": "99.00", "priceCurrency": "USD", "name": "Annual"},
            {"@type": "Offer", "price": "499.00", "priceCurrency": "USD", "name": "Lifetime"},
        ]
        data = {
            "@context": "https://schema.org",
            "@graph": [
                {
                    "@type": "WebSite",
                    "@id": f"{base}/",
                    "url": f"{base}/",
                    "name": "Alforge Labs",
                },
                {
                    "@type": "SoftwareApplication",
                    "name": "AlphaForge CLI",
                    "applicationCategory": "FinanceApplication",
                    "operatingSystem": "macOS, Linux, Windows",
                    "url": f"{base}/{lang}/",
                    "datePublished": site_meta.get("published_date", ""),
                    "dateModified": site_meta.get("modified_date", ""),
                    "offers": offers,
                },
            ],
        }
    else:
        # 内部ページ: BreadcrumbList
        page_file = PAGE_FILE[page]
        crumb_name = {
            "install": {"ja": "インストール", "en": "Installation"},
            "docs": {"ja": "ドキュメント", "en": "Documentation"},
            "tutorial-strategy": {"ja": "チュートリアル", "en": "Tutorial"},
            "privacy": {"ja": "プライバシーポリシー", "en": "Privacy Policy"},
            "terms": {"ja": "利用規約", "en": "Terms of Service"},
        }
        home_name = {"ja": "ホーム", "en": "Home"}
        data = {
            "@context": "https://schema.org",
            "@type": "BreadcrumbList",
            "itemListElement": [
                {
                    "@type": "ListItem",
                    "position": 1,
                    "name": home_name[lang],
                    "item": f"{base}/{lang}/",
                },
                {
                    "@type": "ListItem",
                    "position": 2,
                    "name": crumb_name.get(page, {}).get(lang, page),
                    "item": f"{base}/{lang}/{page_file}",
                },
            ],
        }
    return json.dumps(data, ensure_ascii=False, indent=2)


def make_ctx(site: dict, page: str, lang: str, data: dict) -> dict:
    base = site["base_url"]
    url_path = page_url_path(page)
    json_ld_type = data.get("json_ld_type", "breadcrumb")
    return {
        "lang": lang,
        "og_locale": "ja_JP" if lang == "ja" else "en_US",
        "canonical_url": f"{base}/{lang}/{url_path}",
        "hreflang_ja": f"{base}/ja/{url_path}",
        "hreflang_en": f"{base}/en/{url_path}",
        "hreflang_x_default": f"{base}/en/{url_path}",
        "og_image": site["og_image"],
        "twitter_site": site["twitter_site"],
        "robots": site.get("robots", "index, follow"),
        "json_ld": build_json_ld(json_ld_type, base, lang, page, site),
        **{k: v for k, v in data.items() if k != "json_ld_type"},
    }


def build() -> None:
    seo = yaml.safe_load(Path("seo.yaml").read_text(encoding="utf-8"))
    env = Environment(
        loader=FileSystemLoader("templates"),
        autoescape=False,
        keep_trailing_newline=True,
    )

    for page in PAGES:
        page_data = seo["pages"][page]
        for lang in ["ja", "en"]:
            tmpl = env.get_template(f"{page}.html.j2")
            ctx = make_ctx(seo["site"], page, lang, page_data[lang])
            out_dir = Path(lang)
            out_dir.mkdir(exist_ok=True)
            out_file = PAGE_FILE[page]
            (out_dir / out_file).write_text(tmpl.render(**ctx), encoding="utf-8")
            print(f"  ✓ {lang}/{out_file}")

    generate_robots(seo["site"]["base_url"])
    generate_sitemap(seo["site"]["base_url"], seo["site"])
    print("Build complete.")


def generate_robots(base_url: str) -> None:
    Path("robots.txt").write_text(
        f"User-agent: *\nAllow: /\nSitemap: {base_url}/sitemap.xml\n",
        encoding="utf-8",
    )
    print("  ✓ robots.txt")


def generate_sitemap(base_url: str, site: dict) -> None:
    modified = site.get("modified_date", "")
    lastmod_line = f"    <lastmod>{modified}</lastmod>\n" if modified else ""
    entries: list[str] = []
    for page in PAGES:
        if page in SITEMAP_EXCLUDED_PAGES:
            continue
        url_path = page_url_path(page)
        freq, priority = CHANGEFREQ[page]
        ja_url = f"{base_url}/ja/{url_path}"
        en_url = f"{base_url}/en/{url_path}"
        for loc, alt_ja, alt_en in [(ja_url, ja_url, en_url), (en_url, ja_url, en_url)]:
            entries.append(
                f"  <url>\n"
                f"    <loc>{loc}</loc>\n"
                f'    <xhtml:link rel="alternate" hreflang="ja" href="{alt_ja}"/>\n'
                f'    <xhtml:link rel="alternate" hreflang="en" href="{alt_en}"/>\n'
                f'    <xhtml:link rel="alternate" hreflang="x-default" href="{alt_en}"/>\n'
                f"{lastmod_line}"
                f"    <changefreq>{freq}</changefreq>\n"
                f"    <priority>{priority}</priority>\n"
                f"  </url>"
            )
    xml = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"\n'
        '        xmlns:xhtml="http://www.w3.org/1999/xhtml">\n'
        + "\n".join(entries)
        + "\n</urlset>\n"
    )
    Path("sitemap.xml").write_text(xml, encoding="utf-8")
    print("  ✓ sitemap.xml")


if __name__ == "__main__":
    build()
