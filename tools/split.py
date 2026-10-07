#!/usr/bin/env python3
# Одноразовый разрезатель: монолитный main.gd -> проект из файлов (цепочка наследования + классы + данные).
# usage: split.py <main.gd> <outdir>
import re, sys, os, shutil
sys.path.insert(0, os.path.dirname(__file__))
from analyze import split_top
from modules import MODULES, assign

src_path, out = sys.argv[1], sys.argv[2]
src = open(src_path, encoding='utf-8').read()
lines, items = split_top(src)

# --- ведущие комментарии принадлежат следующему элементу ---
starts = [it['start'] for it in items]
for k, it in enumerate(items):
    s = it['start']
    lo = items[k - 1]['start'] + 1 if k > 0 else 0
    while s - 1 >= lo and lines[s - 1].startswith('#'):
        s -= 1
    it['cstart'] = s
for k, it in enumerate(items):
    it['cend'] = items[k + 1]['cstart'] if k + 1 < len(items) else len(lines)


def text(it):
    t = lines[it['cstart']:it['cend']]
    while t and t[-1].strip() == '':
        t.pop()
    return '\n'.join(t)


def code_start(it):
    return it['start']


funcs = [it for it in items if it['kind'] == 'func']
consts = [it for it in items if it['kind'] == 'const']
vars_ = [it for it in items if it['kind'] == 'var']
classes = [it for it in items if it['kind'] == 'class']

# --- какой модуль у каждой функции ---
order = [m[0] for m in MODULES if m[1] == 'logic' or m[1] == 'ui' or m[1] == 'main']
owner = {}
for f in funcs:
    owner[f['name']] = assign(f['name'])
missing = [n for n, m in owner.items() if m is None]
if missing:
    print('НЕ РАСПРЕДЕЛЕНЫ (%d): %s' % (len(missing), ' '.join(missing)))
    sys.exit(1)
midx = {m: i for i, m in enumerate(order)}

ident = re.compile(r'(?<![\w.$@&^%"\'])([A-Za-z_]\w*)')


def strip_code(s):
    s = re.sub(r'"(?:\\.|[^"\\])*"', '""', s)
    s = re.sub(r"'(?:\\.|[^'\\])*'", "''", s)
    s = re.sub(r'#.*', '', s)
    return s


def signature(it):
    out_l = []
    d = 0
    for ln in lines[it['start']:it['end']]:
        out_l.append(ln)
        c = strip_code(ln)
        d += c.count('(') + c.count('[') + c.count('{') - c.count(')') - c.count(']') - c.count('}')
        if d == 0 and c.rstrip().endswith(':'):
            break
    return '\n'.join(out_l)


def default_return(sig):
    m = re.search(r'->\s*(.+?)\s*:\s*(?:#.*)?$', sig.replace('\n', ' '))
    if not m:
        return 'return null'
    t = m.group(1).strip()
    if t == 'void':
        return 'pass'
    simple = {'int': '0', 'float': '0.0', 'bool': 'false', 'String': '""', 'StringName': '&""', 'Array': '[]', 'Dictionary': '{}',
              'Vector2': 'Vector2.ZERO', 'Vector2i': 'Vector2i.ZERO', 'Color': 'Color.WHITE', 'Rect2': 'Rect2()',
              'PackedStringArray': 'PackedStringArray()', 'PackedFloat32Array': 'PackedFloat32Array()',
              'PackedInt32Array': 'PackedInt32Array()', 'PackedVector2Array': 'PackedVector2Array()', 'Variant': 'null'}
    if t in simple:
        return 'return ' + simple[t]
    m2 = re.match(r'Array\[(.+)\]$', t)
    if m2:
        return 'var r: %s = []\n\treturn r' % t
    return 'return null'


def func_body_tokens(it):
    toks = set()
    for ln in lines[it['start'] + 1:it['end']]:
        for t in ident.findall(strip_code(ln)):
            toks.add(t)
    # параметры значений по умолчанию в сигнатуре
    for t in ident.findall(strip_code(signature(it))):
        toks.add(t)
    return toks


# --- заглушки: что вызывается из модулей выше по цепочке ---
fobj = {f['name']: f for f in funcs}
stubs = {m: {} for m in order}   # модуль -> {имя: сигнатура}
for f in funcs:
    mi = midx[owner[f['name']]]
    for t in func_body_tokens(f):
        if t in fobj and t != f['name'] and midx[owner[t]] > mi:
            # заглушка нужна в самом раннем модуле, который зовёт функцию
            cur = None
            for m2 in order:
                if t in stubs[m2]:
                    cur = m2
            if cur is None or midx[cur] > mi:
                if cur is not None:
                    del stubs[cur][t]
                stubs[order[mi]][t] = signature(fobj[t])
# сами заглушки вызывают другие функции? нет — тело пустое

# --- вывод ---
shutil.rmtree(out, ignore_errors=True)
for d in ('scripts/classes', 'scripts/data', 'scripts/state', 'scripts/logic', 'scripts/ui'):
    os.makedirs(os.path.join(out, d))


def snake(n):
    return re.sub(r'(?<!^)(?=[A-Z])', '_', n).lower()


def write(path, body):
    with open(os.path.join(out, path), 'w', encoding='utf-8') as fh:
        fh.write(body.rstrip('\n') + '\n')


# классы
class_files = {}
for c in classes:
    m = re.match(r'class\s+(\w+)\s+extends\s+(\w+)\s*:', lines[c['start']])
    class_files[m.group(1)] = (m.group(2), c)
for name, (base, c) in class_files.items():
    body_lines = lines[c['start'] + 1:c['end']]
    ded = []
    for ln in body_lines:
        ded.append(ln[1:] if ln.startswith('\t') else ln)
    body = '\n'.join(ded).rstrip()
    pre = ''
    for other in class_files:
        if other != name and re.search(r'\b%s\b' % other, body):
            pre += 'const %s := preload("res://scripts/classes/%s.gd")\n' % (other, snake(other))
    lead = text(c).split('\n')
    comm = [l for l in lead[:lead.index(lines[c['start']])] if l.startswith('#')] if lines[c['start']] in lead else []
    write('scripts/classes/%s.gd' % snake(name), '\n'.join(comm) + ('\n' if comm else '') + 'extends %s\n' % base + pre + '\n' + body)

cls_consts = ''.join('const %s := preload("res://scripts/classes/%s.gd")\n' % (n, snake(n)) for n in class_files)

# данные
small = [c for c in consts if c['cend'] - c['cstart'] < 100]
mid = [c for c in consts if 100 <= c['cend'] - c['cstart'] < 1000]
big = [c for c in consts if c['cend'] - c['cstart'] >= 1000]
chain = []   # (path, extends_label)


def emit(path, head, body):
    chain.append(path)
    write(path, head + '\n' + body)


emit('scripts/data/data_core.gd', '# Справочные таблицы игры: группы, политика, уровни, рынки, цвета и т.п. (только const).\nextends Control\n' + cls_consts,
     '\n\n'.join(text(c) for c in small))
emit('scripts/data/data_content.gd', '# Крупные таблицы контента: события, законы, радикальные законы, карта мира.\nextends "res://%s"' % chain[-1],
     '\n\n'.join(text(c) for c in mid))
emit('scripts/data/data_countries.gd', '# Пакеты данных стран (генерируются tools/gen_data из Python-описаний).\nextends "res://%s"' % chain[-1],
     '\n\n'.join(text(c) for c in big))

up = [v for v in vars_ if v['name'][:1].isupper() or v['name'].startswith('_')]
low = [v for v in vars_ if v not in up]
emit('scripts/state/state_data.gd', '# Таблицы, которые страна подменяет при запуске (REGIONS, LEAN, PARTY_NAMES и др.).\nextends "res://%s"' % chain[-1],
     '\n\n'.join(text(v) for v in up))
emit('scripts/state/state.gd', '# Текущее состояние партии: показатели, законы, парламент, узлы интерфейса.\nextends "res://%s"' % chain[-1],
     '\n\n'.join(text(v) for v in low))

titles = {m[0]: m[2] for m in MODULES}
for m in order:
    kind = [x[1] for x in MODULES if x[0] == m][0]
    d = 'ui' if kind == 'ui' else 'logic'
    path = 'scripts/%s/%s.gd' % (d, m) if m != 'main' else 'main.gd'
    parts = []
    st = stubs[m]
    if st:
        parts.append('# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются ---')
        for n in sorted(st):
            parts.append(st[n].rstrip() + '\n\t' + default_return(st[n]).replace('\n', '\n\t'))
        parts.append('# --- конец заглушек ---')
    for f in funcs:
        if owner[f['name']] == m:
            parts.append(text(f))
    hdr = '# %s\nextends "res://%s"' % (titles[m], chain[-1])
    if m == 'main':
        hdr = '# ' + titles[m] + '\n' + '\n'.join(lines[1:6]) + '\nextends "res://%s"' % chain[-1]
    body = '\n\n\n'.join(parts)
    if m == 'main':
        write('main.gd', hdr + '\n\n' + body)
    else:
        write(path, hdr + '\n\n' + body)
        chain.append(path)
print('модулей: %d, функций: %d, заглушек: %d' % (len(order), len(funcs), sum(len(v) for v in stubs.values())))
open(os.path.join(out, 'scripts/CHAIN.txt'), 'w').write('\n'.join(chain) + '\nmain.gd\n')
