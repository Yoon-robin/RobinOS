"""Writes tokens.json and tailwind.css from robin-ui.css, so the three never drift.

    python brand-kit/tokens.py

robin-ui.css is the one place a value is written. This reads its two token blocks (dark:
`:root, [data-theme="dark"]`, light: `[data-theme="light"]`) and writes
  - tokens.json   {"dark": {...}, "light": {...}} for anything that is not CSS
  - tailwind.css  a Tailwind v4 @theme that points utilities at the --rk- variables
and puts icons.svg into index.html (between the two "icons" comments).
"""
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
css = open(os.path.join(HERE, 'robin-ui.css'), encoding='utf-8').read()


def block(selector):
    start = css.index(selector + ' {')
    body = css[css.index('{', start) + 1:css.index('\n}', start)]
    body = re.sub(r'/\*.*?\*/', '', body, flags=re.S)
    return {m.group(1): m.group(2).strip() for m in re.finditer(r'--rk-([a-z0-9-]+):\s*([^;]+);', body)}


dark = block(':root, [data-theme="dark"]')
light = {**dark, **block('[data-theme="light"]')}
with open(os.path.join(HERE, 'tokens.json'), 'w', encoding='utf-8', newline='\n') as f:
    json.dump({'dark': dark, 'light': light}, f, ensure_ascii=False, indent=2)
    f.write('\n')

colour = [k for k, v in dark.items() if v.startswith('#') or v.startswith('rgb(')]
radius = {'r-chip': 'chip', 'r': 'control', 'r-toast': 'toast', 'r-card': 'card', 'r-win': 'window'}
lines = [
    '/* tailwind.css — Tailwind v4: the kit\'s tokens as utilities (bg-rk-card, text-rk-soft,',
    '   border-rk-line, rounded-rk-control ...). Written by tokens.py from robin-ui.css; do not edit.',
    '',
    '     @import "tailwindcss";',
    '     @import "./brand-kit/robin-ui.css";',
    '     @import "./brand-kit/tailwind.css";',
    '',
    '   The utilities read the --rk- variables, so data-theme="light" turns them with the rest. */',
    '@theme inline {',
]
lines += [f'  --color-rk-{k}: var(--rk-{k});' for k in colour]
lines += [f'  --radius-rk-{name}: var(--rk-{k});' for k, name in radius.items()]
lines += ['  --font-rk: var(--rk-font);', '  --font-rk-mono: var(--rk-mono);', '  --ease-rk: var(--rk-ease);', '}', '']
with open(os.path.join(HERE, 'tailwind.css'), 'w', encoding='utf-8', newline='\n') as f:
    f.write('\n'.join(lines))
# the specimen carries the icons inline (a file opened from disk cannot <use> another file)
page = os.path.join(HERE, 'index.html')
html = open(page, encoding='utf-8').read()
icons = open(os.path.join(HERE, 'icons.svg'), encoding='utf-8').read().strip()
a, b = html.index('<!-- icons:start -->'), html.index('<!-- icons:end -->')
html = html[:a] + '<!-- icons:start -->\n' + icons + '\n' + html[b:]
with open(page, 'w', encoding='utf-8', newline='\n') as f:
    f.write(html)

print('tokens.json:', len(dark), 'dark,', len(block('[data-theme="light"]')), 'light overrides; tailwind.css:', len(colour), 'colours')
