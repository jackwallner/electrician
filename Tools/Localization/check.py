#!/usr/bin/env python3
"""Checks Shared/Localizable.xcstrings against the Swift source.

Run from the repo root: python3 Tools/Localization/check.py

Fails (exit 1) when
  * a localizable literal in the source has no catalog key,
  * a catalog key is missing a language in LANGS,
  * a translation's format specifiers do not match its key,
  * a `return "..."` or a ternary of literals puts English on screen without
    String(localized:), or
  * a content-model label (frontTitle:, prompt:, explanation:, ...) is given a
    bare literal.

Literals count as localizable when they are the first argument of a SwiftUI
text API (Text, Button, Label, Section, navigationTitle, alert, ...) or of
String(localized:). Interpolations are compared loosely (%@, %lld and %lf match
each other), because the type of an interpolated expression is not visible
without the compiler.

Mark a literal that is not copy (an id, a stored tag, a support email line)
with `// l10n:ignore` on the same line.
"""
import json
import os
import re
import sys

ROOT = os.getcwd()
DIRS = ['Electrician', 'Shared']
LANGS = []
UI_FUNCS = {'Text', 'Button', 'Label', 'Section', 'Toggle', 'TextField', 'navigationTitle', 'accessibilityLabel',
            'alert', 'DatePicker', 'Stepper', 'Link', 'confirmationDialog', 'Picker', 'accessibilityHint',
            'SecureField', 'LabeledContent', 'LocalizedStringKey', 'accessibilityValue'}
# Model and view-parameter labels that carry sentences. A bare literal here is a leak.
COPY_LABELS = {'title', 'subtitle', 'prompt', 'explanation', 'summary', 'backTitle', 'backBody', 'frontTitle',
               'frontSubtitle', 'scenario', 'situation', 'detail', 'body', 'tip', 'tagline', 'caption', 'eyebrow',
               'message', 'badge', 'point', 'sourceLabel', 'authority', 'method', 'label', 'text'}
# Brand names and technical symbols that are the same in every language.
BRAND = {'ELECTRICIAN', 'Electrician', 'Electrician+', 'NEC', 'PSI', 'Pearson VUE', 'Prov'}
TECH = {'A', 'V', 'VA', 'kVA', 'kW', 'W', 'AWG', 'kcmil', 'HP', 'hp', 'in', 'ft', 'NEC', 'THHN', 'THWN', 'THWN-2',
        'XHHW', 'XHHW-2', 'EMT', 'NM', 'MC', 'AC', 'GFCI', 'AFCI', 'ID', 'PDF', 'PSI', 'CSV', 'RMC', 'IMC', 'FMC',
        'LFMC', 'PVC', 'UF', 'USE', 'SE', 'RHW', 'MI', 'OCPD', 'EGC', 'GEC', 'OK'}
IGNORE_MARK = 'l10n:ignore'


def parse_literal(src, i):
    """src[i] == '"'. Returns (end_index_after, segments) where segments are ('lit', str) or ('interp', expr)."""
    if src.startswith('"""', i):
        j = i + 3
        while True:
            k = src.index('"""', j)
            if src[k - 1] != '\\':
                return k + 3, None
            j = k + 1
    i += 1
    segs = []
    buf = ''
    while True:
        c = src[i]
        if c == '"':
            if buf:
                segs.append(('lit', buf))
            return i + 1, segs
        if c == '\\':
            n = src[i + 1]
            if n == '(':
                if buf:
                    segs.append(('lit', buf))
                    buf = ''
                depth = 1
                j = i + 2
                expr = ''
                while depth:
                    ch = src[j]
                    if ch == '"':
                        k, _ = parse_literal(src, j)
                        expr += src[j:k]
                        j = k
                        continue
                    if ch == '(':
                        depth += 1
                    elif ch == ')':
                        depth -= 1
                        if depth == 0:
                            break
                    expr += ch
                    j += 1
                segs.append(('interp', expr.strip()))
                i = j + 1
                continue
            if n == 'u':
                j = src.index('}', i)
                buf += chr(int(src[i + 3:j], 16))
                i = j + 1
                continue
            buf += {'n': '\n', 't': '\t', '"': '"', '\\': '\\', "'": "'", '0': '\0'}[n]
            i += 2
            continue
        buf += c
        i += 1


def scan(src):
    """Yields (line, fn, idx, label, prev, segs) for every string literal."""
    out = []
    stack = []  # [kind, fn, text since last comma, arg index]
    i = 0
    n = len(src)
    line = 1
    while i < n:
        c = src[i]
        if c == '\n':
            line += 1
        if src.startswith('//', i):
            j = src.find('\n', i)
            i = n if j < 0 else j
            continue
        if src.startswith('/*', i):
            j = src.index('*/', i)
            line += src[i:j].count('\n')
            i = j + 2
            continue
        if c == '"':
            end, segs = parse_literal(src, i)
            top = stack[-1] if stack else None
            fn = top[1] if top and top[0] == '(' else None
            argtxt = top[2] if top else ''
            m = re.match(r'\s*([A-Za-z_]\w*)\s*:\s*$', argtxt)
            pre = src[max(0, i - 40):i].rstrip()
            out.append({'line': line, 'fn': fn, 'idx': top[3] if top else 0, 'label': m.group(1) if m else None,
                        'argtxt': argtxt, 'prev': pre, 'segs': segs,
                        'start': i, 'src': src})
            line += src[i:end].count('\n')
            if stack:
                stack[-1][2] += src[i:end]
            i = end
            continue
        if c in '([':
            m = re.search(r'([A-Za-z_]\w*)\s*$', src[max(0, i - 60):i])
            stack.append([c, m.group(1) if (c == '(' and m) else '', '', 0])
            i += 1
            continue
        if c in ')]':
            if stack:
                e = stack.pop()
                if stack:
                    stack[-1][2] += e[0] + e[2] + c
            i += 1
            continue
        if c == ',' and stack:
            stack[-1][2] = ''
            stack[-1][3] += 1
            i += 1
            continue
        if stack:
            stack[-1][2] += c
        i += 1
    return out


def literal_text(segs):
    return ''.join(v for kind, v in segs if kind == 'lit')


def catalog_key(segs):
    has_interp = any(kind == 'interp' for kind, _ in segs)
    return ''.join((v.replace('%', '%%') if has_interp else v) if kind == 'lit' else '%@' for kind, v in segs)


def is_copy(segs):
    """True when the literal reads as English a person would see."""
    if segs is None:
        return True
    t = literal_text(segs)
    words = [w for w in re.findall(r'[A-Za-z]{2,}', t) if w not in TECH]
    if not words or t in BRAND:
        return False
    if re.fullmatch(r'[a-z][a-z0-9_.\-/:]*', t) or re.fullmatch(r'[a-z]+(?:[A-Z][a-z0-9]*)+', t):
        return False  # identifier, key or symbol name
    if ' ' not in t and re.search(r'[._@]', t) and not t[0].isupper():
        return False
    if t.startswith('http') or re.fullmatch(r'[\d./ ]+ ?(AWG|kcmil)', t):
        return False
    if re.fullmatch(r'[A-Z0-9_]{3,}', t) and '_' in t:
        return False
    return True


def loose(key):
    return re.sub(r'%(\d+\$)?(lld|@|lf)', '%*', key)


def specs(value, subs=None):
    found = []
    auto = 0
    for m in re.finditer(r'%(?:(\d+)\$)?(lld|@|lf|%)|%#@(\w+)@', value):
        if m.group(2) == '%':
            continue
        if m.group(3):
            found.append((subs[m.group(3)]['argNum'], 'lld'))
            continue
        if m.group(1):
            pos = int(m.group(1))
        else:
            auto += 1
            pos = auto
        found.append((pos, m.group(2)))
    return sorted(set(found))


def loose_specs(found):
    return sorted({pos for pos, _ in found})


def source_files():
    for d in DIRS:
        for dirpath, _, files in os.walk(os.path.join(ROOT, d)):
            for name in sorted(files):
                if name.endswith('.swift'):
                    yield os.path.join(dirpath, name)


def check_source(catalog_loose, problems):
    for path in source_files():
        src = open(path).read()
        lines = src.split('\n')
        rel = os.path.relpath(path, ROOT)
        for lit in scan(src):
            segs = lit['segs']
            text_line = lines[lit['line'] - 1]
            if IGNORE_MARK in text_line or segs is None:
                continue
            direct = re.fullmatch(r'\s*(?:[A-Za-z_]\w*\s*:\s*)?', lit['argtxt']) is not None
            fn, idx, label = lit['fn'], lit['idx'], lit['label']
            wrapped = fn == 'String' and lit['argtxt'].strip().startswith('localized')
            native = fn in UI_FUNCS and direct and idx == 0
            if wrapped or native:
                key = catalog_key(segs)
                if re.search(r'[A-Za-z]{2,}', literal_text(segs)) and loose(key) not in catalog_loose:
                    problems.append(f'{rel}:{lit["line"]}: no catalog key for "{key}"')
                continue
            if not is_copy(segs):
                continue
            prev = lit['prev']
            if label in COPY_LABELS and direct and fn not in ('URLQueryItem',):
                problems.append(f'{rel}:{lit["line"]}: bare literal for {label}: "{literal_text(segs)[:50]}"')
            elif re.search(r'(^|[^?])\breturn$', prev) and fn is None:
                problems.append(f'{rel}:{lit["line"]}: return "{literal_text(segs)[:50]}" reaches the screen without String(localized:)')
            elif re.search(r'[^?]\?$', prev) or (prev.endswith(':') and ' ? ' in text_line and label is None):
                if fn in UI_FUNCS or fn is None or fn in COPY_LABELS:
                    problems.append(f'{rel}:{lit["line"]}: ternary literal "{literal_text(segs)[:50]}" needs String(localized:)')


def check_catalog(catalog, problems):
    for key, entry in catalog.items():
        locs = entry.get('localizations', {})
        for lang in LANGS:
            loc = locs.get(lang)
            if loc is None:
                problems.append(f'"{key}": missing {lang}')
                continue
            want = loose_specs(specs(key))
            if 'variations' in loc:
                values = [u['stringUnit']['value'] for u in loc['variations']['plural'].values()]
                bad = [v for v in values if specs(v) and loose_specs(specs(v)) != want]
            else:
                value = loc['stringUnit']['value']
                bad = [] if loose_specs(specs(value, loc.get('substitutions'))) == want else [value]
            for v in bad:
                problems.append(f'"{key}" [{lang}]: format specifiers differ in "{v}"')
        for lang, loc in locs.items():
            units = [loc] + list(loc.get('variations', {}).get('plural', {}).values())
            for unit in units:
                value = unit.get('stringUnit', {}).get('value', '')
                for name in re.findall(r'%(?:\d+\$)?#@(\w+)@', value):
                    if name not in loc.get('substitutions', {}):
                        problems.append(f'"{key}" [{lang}]: plural token {name!r} has no substitution')
        if entry.get('extractionState') != 'manual':
            problems.append(f'"{key}": extractionState must be manual')


def main():
    catalog = json.load(open(os.path.join(ROOT, 'Shared', 'Localizable.xcstrings')))['strings']
    problems = []
    check_source({loose(k) for k in catalog}, problems)
    check_catalog(catalog, problems)
    for p in problems:
        print(p)
    print(f'{len(catalog)} keys, {len(LANGS)} languages, {len(problems)} problems')
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
