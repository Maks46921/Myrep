#!/usr/bin/env python3
# разбор верхнего уровня GDScript-файла на элементы
import re, sys, json
def split_top(src):
    lines = src.split('\n')
    items = []   # dict(kind,name,start,end)
    i = 0; n = len(lines)
    def depth_delta(s):
        d = 0; instr = None; j = 0
        while j < len(s):
            ch = s[j]
            if instr:
                if ch == '\\': j += 2; continue
                if ch == instr: instr = None
            else:
                if ch == '#': break
                if ch in '"\'': instr = ch
                elif ch in '([{': d += 1
                elif ch in ')]}': d -= 1
            j += 1
        return d
    cur = None
    depth = 0
    triple = False
    pend_comment_start = None
    for idx, ln in enumerate(lines):
        if depth == 0 and not triple and ln and not ln[0].isspace() and not ln.startswith('#'):
            m = re.match(r'(static\s+func|static\s+var|func|class|const|var|enum|signal|extends|class_name|@\w+)\b\s*([A-Za-z_]\w*)?', ln)
            if cur: cur['end'] = idx
            kind = m.group(1) if m else 'other'
            name = m.group(2) if m else ''
            if kind.startswith('static'):
                kind = 'func' if 'func' in kind else 'var'
                m2 = re.match(r'static\s+(?:func|var)\s+([A-Za-z_]\w*)', ln); name = m2.group(1) if m2 else name
            cur = {'kind': kind, 'name': name, 'start': idx, 'end': None}
            items.append(cur)
        if ln.count('"""') % 2 == 1: triple = not triple
        if not triple:
            depth += depth_delta(ln)
    if cur: cur['end'] = n
    return lines, items
if __name__ == '__main__':
    lines, items = split_top(open(sys.argv[1], encoding='utf-8').read())
    from collections import Counter
    print(len(lines), Counter(i['kind'] for i in items))
