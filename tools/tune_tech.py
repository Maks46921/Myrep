#!/usr/bin/env python3
"""Подбор множителей эффектов технологий «или» так, чтобы варианты одной группы были сопоставимы по ИИ-оценке.

  python3 tools/tune_tech.py [итераций=4]

Каждый шаг: аудит (tests/dev/tech_audit.gd) -> средняя оценка вариантов -> множитель к эффектам (tools/tech_scale.json) -> tools/gen_tech.py.
Множители ограничены [0,6; 1,8] и применяются с демпфированием; вручную правятся лишь те варианты, которые остаются перекошенными.
"""
import json, os, re, subprocess, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT = os.environ.get('GODOT') or 'godot'
SC = os.path.join(ROOT, 'tools/tech_scale.json')


def audit():
    out = subprocess.run([GODOT, '--headless', '--path', ROOT, '--script', 'tests/dev/tech_audit.gd', '--', 'country=DE'], capture_output=True, text=True, cwd=ROOT).stdout
    rows = {}
    groups = []
    for ln in out.split('\n'):
        m = re.match(r'AUD (\S+) (\S+) (\S+)', ln)
        if m:
            rows[m.group(1)] = (float(m.group(2)), float(m.group(3)))
        if ' | ' in ln or ln.startswith('групп'):
            groups.append(ln)
    br = {}
    for ln in out.split('\n'):
        m = re.match(r'BR (\d+) (\S+)', ln)
        if m:
            br[int(m.group(1))] = float(m.group(2))
    return rows, groups, br


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 4
    sc = json.load(open(SC, encoding='utf-8')) if os.path.exists(SC) else {}
    for it in range(n):
        rows, groups, br = audit()
        # группы: id отличаются буквой a/b/c в конце
        by = {}
        for i in rows:
            by.setdefault(re.sub(r'[abc]$', '', i), []).append(i)
        for g, ids in by.items():
            vals = [rows[i][0] for i in ids]
            mean = sum(vals) / len(vals)
            for i in ids:
                v = max(rows[i][0], 0.15)
                f = (mean / v) ** 0.7
                sc[i] = round(min(2.0, max(0.5, sc.get(i, 1.0) * f)), 3)
        # между ветками: приводим суммарную ценность к среднему (военная — узкая специализация, цель 90%)
        if br:
            mean_b = sum(br.values()) / len(br)
            for b, v in br.items():
                tgt = mean_b * (0.9 if b == 4 else 1.0)
                f = (tgt / max(v, 0.1)) ** 0.6
                sc['_b%d' % b] = round(min(1.6, max(0.6, sc.get('_b%d' % b, 1.0) * f)), 3)
        json.dump(sc, open(SC, 'w', encoding='utf-8'), ensure_ascii=False, indent=0, sort_keys=True)
        subprocess.run([sys.executable, os.path.join(ROOT, 'tools/gen_tech.py')], cwd=ROOT, capture_output=True)
        print('итерация', it + 1, groups[-1] if groups else '')
    rows, groups, br = audit()
    print('\n'.join(groups))
    print('ветки:', br)


if __name__ == '__main__':
    main()
