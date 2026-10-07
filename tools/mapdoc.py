#!/usr/bin/env python3
"""Генерирует docs/MAP.md — карту проекта: модули, их назначение, функции, где лежат данные."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from analyze import split_top
from modules import MODULES
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out = ['# Карта проекта (создаётся автоматически: `python3 tools/mapdoc.py`)\n',
       'Скрипты игры образуют **цепочку наследования**: каждый файл `extends` предыдущий, вершина — `main.gd`. '
       'Порядок — в `scripts/CHAIN.txt`. Поэтому любая функция доступна из любого модуля; '
       'если модуль вызывает функцию из модуля ниже по цепочке, нужна «заглушка» — её создаёт `tools/stubs.py`.\n']
desc = {m[0]: m[2] for m in MODULES}
chain = [l.strip() for l in open(os.path.join(ROOT, 'scripts/CHAIN.txt'), encoding='utf-8') if l.strip()]
out.append('## Цепочка\n')
for p in chain:
    name = os.path.basename(p)[:-3]
    txt = open(os.path.join(ROOT, p), encoding='utf-8').read()
    lines, items = split_top(txt)
    f = [i['name'] for i in items if i['kind'] == 'func']
    c = [i['name'] for i in items if i['kind'] == 'const']
    v = [i['name'] for i in items if i['kind'] == 'var']
    first = txt.split('\n')[0].lstrip('# ').strip()
    out.append('### `%s`  (%d строк)\n%s\n' % (p, len(lines), first))
    if f:
        stubs = txt.count('# --- конец заглушек')
        out.append('Функции (%d): %s\n' % (len(f), ', '.join('`%s`' % n for n in f if n)))
    if c:
        out.append('Константы (%d): %s\n' % (len(c), ', '.join('`%s`' % n for n in c)))
    if v:
        out.append('Переменные (%d): %s\n' % (len(v), ', '.join('`%s`' % n for n in v[:60]) + (' …' if len(v) > 60 else '')))
out.append('## Классы (`scripts/classes/`)\n')
for fn in sorted(os.listdir(os.path.join(ROOT, 'scripts/classes'))):
    txt = open(os.path.join(ROOT, 'scripts/classes', fn), encoding='utf-8').read()
    ext = re.search(r'^extends (\w+)', txt, re.M)
    out.append('- `%s` — extends %s, %d строк' % (fn, ext.group(1) if ext else '?', txt.count('\n')))
open(os.path.join(ROOT, 'docs/MAP.md'), 'w', encoding='utf-8').write('\n'.join(out) + '\n')
print('docs/MAP.md обновлён')
