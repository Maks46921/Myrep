#!/usr/bin/env python3
"""Большой прогон баланса технологий: быстрый симулятор (tests/dev/tech_fast.gd) по всем странам + аудит вариантов «или».

  GODOT=/путь/к/godot python3 tools/tech_report.py [-j 8] [--full]   -> docs/TECH_BALANCE.md

--full дополнительно гонит полные игры (tests/dev/tech_bal.gd) на нескольких странах и зёрнах: влияние технологий на ВВП.
"""
import argparse, concurrent.futures as cf, os, re, statistics, subprocess, sys, time
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT = os.environ.get('GODOT') or 'godot'
ALL = 'DE FR NL BE LU AT CH CZ DK ES IT NO PL PT SE GB IE SI SK HU FI HR RS BA ME MK AL XK BG RO GR EE LV LT'.split()


def run(cmd, tmo=900):
    return subprocess.run([GODOT, '--headless', '--path', ROOT] + cmd, capture_output=True, text=True, cwd=ROOT, timeout=tmo, errors='replace').stdout


def fast(cc):
    return [l for l in run(['--script', 'tests/dev/tech_fast.gd', '--', 'country=' + cc]).split('\n') if l.startswith('FAST|')]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-j', type=int, default=8)
    ap.add_argument('--full', action='store_true')
    ap.add_argument('-o', default=os.path.join(ROOT, 'docs/TECH_BALANCE.md'))
    a = ap.parse_args()
    t0 = time.time()
    rows = []
    with cf.ThreadPoolExecutor(a.j) as ex:
        for r in ex.map(fast, ALL):
            rows += [x.split('|')[1:] for x in r]
    data = {}
    for cc, st, y, tiers, spd, cap, g, val, gdp in rows:
        data.setdefault((st, int(y)), []).append((cc, int(tiers), float(spd), float(cap), float(g), float(val), float(gdp)))
    out = ['# Баланс технологий (создаётся автоматически: `tools/tech_report.py`)\n',
           'Быстрый симулятор исследований (`tests/dev/tech_fast.gd`): 34 страны × 5 стратегий × 100 лет, ИИ-выбор технологий, пассивное изучение от соседей. '
           'Из 70 изучаемых технологий (по одной на уровень ветки) показана доля изученных; «рост+» — суммарная прибавка к росту ВВП от технологий, п.п./год.\n']
    sts = ['скупая', 'обычная', 'усиленная', 'максимум', 'усиленная без свободы слова']
    desc = {'скупая': 'образование ×0,5, без сооружений', 'обычная': 'образование ×1, без сооружений', 'усиленная': 'образование ×1,5, центры и кампусы',
            'максимум': 'образование ×2, все сооружения', 'усиленная без свободы слова': 'как «усиленная», но закон о СМИ — государственный контроль'}
    out.append('## Доля изученных технологий и скорость\n')
    out.append('| Стратегия | 25 лет | 50 лет | 75 лет | 100 лет | скорость (ср.) на 50-м | потолок (ср.) на 50-м | рост+ на 100-м (мин / ср / макс) |')
    out.append('|---|---|---|---|---|---|---|---|')
    summary = {}
    for st in sts:
        cells = []
        for y in (25, 50, 75, 100):
            v = data.get((st, y), [])
            tr = [x[1] for x in v]
            cells.append('%.0f%% (%d–%d)' % (statistics.mean(tr) / 70.0 * 100.0, min(tr), max(tr)) if tr else '—')
            summary[(st, y)] = statistics.mean(tr) / 70.0 if tr else 0.0
        v50 = data.get((st, 50), [])
        v100 = data.get((st, 100), [])
        g = [x[4] for x in v100]
        out.append('| %s | %s | %.1f | %.1f | %.2f / %.2f / %.2f |' % (st + ' — ' + desc[st], ' | '.join(cells), statistics.mean([x[2] for x in v50]), statistics.mean([x[3] for x in v50]), min(g), statistics.mean(g), max(g)))
    out.append('\n## Страны: разброс на 100-м году (стратегия «обычная»)\n')
    v = sorted(data.get(('обычная', 100), []), key=lambda x: -x[1])
    out.append('Больше всего изучено: ' + ', '.join('%s %d' % (x[0], x[1]) for x in v[:6]) + '. Меньше всего: ' + ', '.join('%s %d' % (x[0], x[1]) for x in v[-6:]) + '.\n')
    out.append('Различие между странами объясняют свобода слова (потолок скорости) и пассивное изучение от соседей.\n')
    # аудит вариантов
    aud = run(['--script', 'tests/dev/tech_audit.gd', '--', 'country=DE'])
    out.append('## Варианты «или»: как часто вариант лучший для 34 стран и 10 условных ситуаций (ИИ-оценка)\n')
    out.append('```')
    for ln in aud.split('\n'):
        if ' | ' in ln or ln.startswith('групп'):
            out.append(ln)
    out.append('```\n')
    # проверка допусков
    checks = []
    if summary[('обычная', 100)] > 0.80 or summary[('обычная', 100)] < 0.35:
        checks.append('«обычная» к 100-му году вне 35–80%%: %.0f%%' % (summary[('обычная', 100)] * 100))
    if summary[('усиленная', 100)] < summary[('обычная', 100)] + 0.05:
        checks.append('вложения в науку почти не дают выигрыша')
    if summary[('максимум', 100)] > 0.95:
        checks.append('«максимум» закрывает почти всё дерево')
    out.append('## Допуски\n' + ('\n'.join('- ✗ ' + c for c in checks) if checks else '- ✓ все допуски соблюдены'))
    if a.full:
        out.append('\n## Полные игры\n')
        out.append('См. `tests/dev/tech_bal.gd` (параметры edu=, bld=, years=, seed=, notech).')
    open(a.o, 'w', encoding='utf-8').write('\n'.join(out) + '\n')
    print('готово за %.0f с -> %s' % (time.time() - t0, a.o))
    print('\n'.join(checks) if checks else 'допуски соблюдены')


if __name__ == '__main__':
    main()
