#!/usr/bin/env python3
"""Validate Google Play listing copy under android/play-assets/metadata/android.

Checks every locale folder for Play's limits (title 30, short 80, full 4000),
the house rules (no em dashes, no prices, no Apple wording, no promo words in
the title, no medical claims), the 50 expected Play locales, and the closing
lines this app needs: the Google Play billing paragraph, the NFPA
non-affiliation note, the Android privacy and terms links, and in every
non-English listing a plain line saying the app is in English (the Android app
is not localized). Exit 1 on any failure.

Adapted from ~/sober scripts/validate-play-listing.py.

Usage: scripts/validate-play-listing.py [--root DIR]
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "android/play-assets/metadata/android"
LIMITS = {"title.txt": 30, "short_description.txt": 80, "full_description.txt": 4000}
# Play language codes accepted by the Publishing API (fastlane supply list).
PLAY_LANGS = set(
    "af am ar az-AZ be bg bn-BD ca cs-CZ da-DK de-DE el-GR en-AU en-CA en-GB en-IN "
    "en-SG en-US en-ZA es-419 es-ES es-US et eu-ES fa fi-FI fil fr-CA fr-FR gl-ES "
    "hi-IN hr hu-HU hy-AM id is-IS it-IT iw-IL ja-JP ka-GE km-KH kn-IN ko-KR ky-KG "
    "lo-LA lt lv mk-MK ml-IN mn-MN mr-IN ms ms-MY my-MM ne-NP nl-NL no-NO pl-PL "
    "pt-BR pt-PT rm ro ru-RU si-LK sk sl sr sv-SE sw ta-IN te-IN th tr-TR uk vi "
    "zh-CN zh-HK zh-TW zu".split()
)
ENGLISH = {"en-US", "en-GB", "en-AU", "en-CA", "en-IN"}
# The exact sentence each non-English listing uses to say the app is in English.
ENGLISH_NOTE = {
    "de-DE": "Die App ist auf Englisch.",
    "fr-FR": "L'application est en anglais.",
    "fr-CA": "L'application est en anglais.",
    "es-ES": "La aplicación está en inglés.",
    "es-419": "La app está en inglés.",
    "es-US": "La app está en inglés.",
    "pt-BR": "O app está em inglês.",
    "pt-PT": "A aplicação está em inglês.",
    "it-IT": "L'app è in inglese.",
    "nl-NL": "De app is in het Engels.",
    "sv-SE": "Appen är på engelska.",
    "no-NO": "Appen er på engelsk.",
    "da-DK": "Appen er på engelsk.",
    "fi-FI": "Sovellus on englanninkielinen.",
    "pl-PL": "Aplikacja jest w języku angielskim.",
    "cs-CZ": "Aplikace je v angličtině.",
    "sk": "Aplikácia je v angličtine.",
    "sl": "Aplikacija je v angleščini.",
    "hr": "Aplikacija je na engleskom jeziku.",
    "hu-HU": "Az alkalmazás angol nyelvű.",
    "ro": "Aplicația este în limba engleză.",
    "el-GR": "Η εφαρμογή είναι στα αγγλικά.",
    "tr-TR": "Uygulama İngilizcedir.",
    "ru-RU": "Приложение на английском языке.",
    "uk": "Додаток англійською мовою.",
    "ar": "التطبيق باللغة الإنجليزية.",
    "iw-IL": "האפליקציה באנגלית.",
    "hi-IN": "यह ऐप अंग्रेज़ी में है।",
    "bn-BD": "অ্যাপটি ইংরেজিতে।",
    "mr-IN": "हे ॲप इंग्रजीत आहे.",
    "ta-IN": "இந்த ஆப் ஆங்கிலத்தில் உள்ளது.",
    "te-IN": "ఈ యాప్ ఇంగ్లీష్‌లో ఉంది.",
    "kn-IN": "ಈ ಆ್ಯಪ್ ಇಂಗ್ಲಿಷ್‌ನಲ್ಲಿದೆ.",
    "ml-IN": "ഈ ആപ്പ് ഇംഗ്ലീഷിലാണ്.",
    "id": "Aplikasi ini berbahasa Inggris.",
    "ms": "Aplikasi ini dalam bahasa Inggeris.",
    "ms-MY": "Aplikasi ini dalam bahasa Inggeris.",
    "th": "แอปนี้เป็นภาษาอังกฤษ",
    "vi": "Ứng dụng bằng tiếng Anh.",
    "ja-JP": "アプリの表示言語は英語です。",
    "ko-KR": "앱은 영어로 제공됩니다.",
    "zh-CN": "本应用为英文界面。",
    "zh-TW": "本應用程式為英文介面。",
    "zh-HK": "此應用程式為英文介面。",
    "ca": "L'aplicació està en anglès.",
}
EXPECTED = ENGLISH | set(ENGLISH_NOTE)
TITLE_BANNED = re.compile(r"\b(free|best|top|#1|new|sale|gratis|gratuit|kostenlos|grátis)\b", re.I)
PRICE = re.compile(r"[$€£¥₹]\s?\d|\d[.,]\d\d\s?(?:€|zł|kr|lei|Kč|₺|₽|₴)|\b(?:USD|EUR|GBP)\s?\d")
APPLE = re.compile(r"\b(?:Apple|App Store|iPhone|iPad|iCloud|iOS)\b", re.I)
MEDICAL = re.compile(r"\b(treats?|cures?|diagnos\w*)\b", re.I)
URL_OK = re.compile(r"https://jackwallner\.github\.io/\S+")
PRIVACY_URL = "https://jackwallner.github.io/electrician/android-privacy.html"
TERMS_URL = "https://jackwallner.github.io/electrician/terms.html"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8").strip() if path.exists() else ""


def check(locale_dir: Path) -> list[str]:
    errs: list[str] = []
    loc = locale_dir.name
    if loc not in PLAY_LANGS:
        errs.append(f"unknown Play language code {loc}")
    if loc not in EXPECTED:
        errs.append(f"{loc} is not one of the 50 listing locales")
    for name, limit in LIMITS.items():
        p = locale_dir / name
        if not p.exists():
            errs.append(f"missing {name}")
            continue
        text = read(p)
        n = len(text)
        if n == 0 or n > limit:
            errs.append(f"{name} {n}/{limit}")
        if "\u2014" in text:
            errs.append(f"{name} has an em dash")
        if re.search("[\u00ad\u200b\ufeff]", text):
            errs.append(f"{name} has an invisible character")
        if m := PRICE.search(text):
            errs.append(f"{name} looks like it has a price: {m.group(0)!r}")
        if m := APPLE.search(URL_OK.sub("", text)):
            errs.append(f"{name} mentions Apple wording: {m.group(0)!r}")
        if m := MEDICAL.search(text):
            errs.append(f"{name} has a medical claim word: {m.group(0)!r}")
        if name != "full_description.txt" and "\n" in text:
            errs.append(f"{name} spans lines")
    title = read(locale_dir / "title.txt")
    if TITLE_BANNED.search(title):
        errs.append(f"title has a promo word: {title!r}")
    if "Electrician" not in title:
        errs.append(f"title drops the Electrician brand: {title!r}")
    full = read(locale_dir / "full_description.txt")
    if "Google Play" not in full:
        errs.append("full description lacks the Google Play billing paragraph")
    if "NFPA" not in full:
        errs.append("full description lacks the NFPA non-affiliation note")
    if PRIVACY_URL not in full or TERMS_URL not in full:
        errs.append("full description lacks the Android privacy or terms link")
    if "privacy-policy" in full or "stdeula" in full:
        errs.append("full description still has an iOS link")
    note = ENGLISH_NOTE.get(loc)
    if note and note not in full:
        errs.append(f"full description does not say the app is in English ({note!r})")
    return errs


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=Path, default=ROOT)
    args = ap.parse_args()
    bad = 0
    dirs = sorted(d for d in args.root.iterdir() if d.is_dir())
    for d in dirs:
        errs = check(d)
        t = read(d / "title.txt")
        s = read(d / "short_description.txt")
        f = read(d / "full_description.txt")
        status = "OK " if not errs else "BAD"
        print(f"{status} {d.name:7} t{len(t):>3} s{len(s):>3} f{len(f):>5}  {t}")
        for e in errs:
            print(f"      - {e}")
        bad += bool(errs)
    missing = sorted(EXPECTED - {d.name for d in dirs})
    for loc in missing:
        print(f"BAD {loc:7} missing locale folder")
    bad += len(missing)
    print(f"\n{len(dirs)} locales, {bad} with problems")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
