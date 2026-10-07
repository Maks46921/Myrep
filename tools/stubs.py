#!/usr/bin/env python3
"""Заглушки цепочки наследования.

GDScript не позволяет базовому классу вызывать функцию, которая определена только в наследнике.
Поэтому в каждом модуле цепочки (scripts/CHAIN.txt) есть блок «заглушек» — пустых копий функций,
реализованных в модулях НИЖЕ по цепочке. Реальная функция их переопределяет.

  tools/stubs.py          пересоздать блоки заглушек (запускать после добавления/переименования функций)
  tools/stubs.py --check  только проверить, что блоки актуальны (код возврата 1, если нет)
"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from analyze import split_top

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BEGIN = '# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---'
END = '# --- конец заглушек ---'
ident = re.compile(r'(?<![\w.$@&^%"\'])([A-Za-z_]\w*)')


def strip_code(s):
    s = re.sub(r'"(?:\\.|[^"\\])*"', '""', s)
    s = re.sub(r"'(?:\\.|[^'\\])*'", "''", s)
    return re.sub(r'#.*', '', s)


def signature(lines, it):
    out, d = [], 0
    for ln in lines[it['start']:it['end']]:
        out.append(ln)
        c = strip_code(ln)
        d += c.count('(') + c.count('[') + c.count('{') - c.count(')') - c.count(']') - c.count('}')
        if d == 0 and c.rstrip().endswith(':'):
            break
    return '\n'.join(out).rstrip()


SIMPLE = {'int': '0', 'float': '0.0', 'bool': 'false', 'String': '""', 'StringName': '&""', 'Array': '[]', 'Dictionary': '{}',
          'Vector2': 'Vector2.ZERO', 'Vector2i': 'Vector2i.ZERO', 'Color': 'Color.WHITE', 'Rect2': 'Rect2()',
          'PackedStringArray': 'PackedStringArray()', 'PackedFloat32Array': 'PackedFloat32Array()',
          'PackedInt32Array': 'PackedInt32Array()', 'PackedVector2Array': 'PackedVector2Array()', 'Variant': 'null'}


def default_return(sig):
    m = re.search(r'->\s*(.+?)\s*:\s*(?:#.*)?$', sig.replace('\n', ' '))
    if not m:
        return 'return null'
    t = m.group(1).strip()
    if t == 'void':
        return 'pass'
    if t in SIMPLE:
        return 'return ' + SIMPLE[t]
    if re.match(r'Array\[(.+)\]$', t):
        return 'var r: %s = []\n\treturn r' % t
    return 'return null'


def load_chain():
    paths = [l.strip() for l in open(os.path.join(ROOT, 'scripts/CHAIN.txt'), encoding='utf-8') if l.strip()]
    mods = []
    for p in paths:
        full = os.path.join(ROOT, p)
        txt = open(full, encoding='utf-8').read()
        # убрать старый блок заглушек
        txt = re.sub(r'# --- заглушки.*?' + re.escape(END) + r'\n*', '', txt, flags=re.S)
        lines, items = split_top(txt)
        funcs = [it for it in items if it['kind'] == 'func']
        mods.append({'path': p, 'full': full, 'text': txt, 'lines': lines, 'funcs': funcs})
    return mods


def main():
    check = '--check' in sys.argv
    mods = load_chain()
    owner = {}
    sig = {}
    for i, m in enumerate(mods):
        for f in m['funcs']:
            if f['name'] in owner:
                print('функция %s определена дважды: %s и %s' % (f['name'], mods[owner[f['name']]]['path'], m['path']))
                return 2
            owner[f['name']] = i
            sig[f['name']] = signature(m['lines'], f)
    need = [dict() for _ in mods]
    for i, m in enumerate(mods):
        for f in m['funcs']:
            toks = set()
            for ln in m['lines'][f['start']:f['end']]:
                toks.update(ident.findall(strip_code(ln)))
            for t in toks:
                if t in owner and t != f['name'] and owner[t] > i:
                    # заглушка нужна самому раннему вызывающему модулю
                    prev = [j for j in range(len(mods)) if t in need[j]]
                    if prev and prev[0] <= i:
                        continue
                    for j in prev:
                        del need[j][t]
                    need[i][t] = sig[t]
    stale = []
    for i, m in enumerate(mods):
        txt = m['text']
        if need[i]:
            parts = [BEGIN]
            for n in sorted(need[i]):
                parts.append(need[i][n] + '\n\t' + default_return(need[i][n]).replace('\n', '\n\t'))
            parts.append(END)
            block = '\n\n\n'.join(parts) + '\n\n\n'
        else:
            block = ''
        lines = txt.split('\n')
        k = next(j for j, l in enumerate(lines) if l.startswith('extends'))
        # вставить после extends и пустых/служебных строк (preload-const в начале файла нет)
        head = '\n'.join(lines[:k + 1]) + '\n\n'
        rest = '\n'.join(lines[k + 1:]).lstrip('\n')
        new = head + block + rest
        if new != open(m['full'], encoding='utf-8').read():
            stale.append(m['path'])
            if not check:
                open(m['full'], 'w', encoding='utf-8').write(new)
    if check:
        if stale:
            print('Заглушки устарели в: ' + ', '.join(stale) + '\nЗапустите tools/stubs.py')
            return 1
        print('Заглушки актуальны (%d функций, %d заглушек)' % (len(owner), sum(len(n) for n in need)))
        return 0
    print('Обновлено файлов: %d; заглушек всего: %d' % (len(stale), sum(len(n) for n in need)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
