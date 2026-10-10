#!/usr/bin/env python3
"""Отчёт о финалах: для каждой страны прогоняет партию «без действий игрока» (passive) и «автопилот» (auto)
и пишет docs/FINALS.md: на каком месяце и почему закончилась игра.
Запуск: GODOT=/путь/к/godot python3 tools/finals.py [месяцев=120] [-j 4] [--seeds 1,2]"""
import os, re, subprocess, sys, concurrent.futures as cf, collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ALL = "DE FR NL BE LU AT CH CZ DK ES IT NO PL PT SE GB IE SI SK HU FI HR RS BA ME MK AL XK BG RO GR EE LV LT".split()

def run(cc, mode, months, seed):
    cmd = [os.path.join(ROOT, 'tools', 'godot.sh'), '--headless', '--path', ROOT, '--script', 'tests/dev/finals.gd', '--',
           'country=' + cc, 'months=%d' % months, 'mode=' + mode, 'seed=%d' % seed]
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=1500).stdout
    except subprocess.TimeoutExpired:
        return (cc, mode, seed, None)
    for line in out.splitlines():
        if line.startswith('FINAL|'):
            return (cc, mode, seed, line.split('|')[1:])
    return (cc, mode, seed, None)

def main():
    months = 120
    jobs = 4
    seeds = [3]
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == '-j':
            jobs = int(args[i + 1]); i += 1
        elif args[i] == '--seeds':
            seeds = [int(x) for x in args[i + 1].split(',')]; i += 1
        elif args[i].isdigit():
            months = int(args[i])
        i += 1
    todo = [(cc, mode, months, sd) for cc in ALL for mode in ('passive', 'auto') for sd in seeds]
    res = []
    with cf.ThreadPoolExecutor(jobs) as ex:
        futs = [ex.submit(run, *t) for t in todo]
        for k, f in enumerate(futs):
            r = f.result()
            res.append(r)
            print('[%d/%d] %s %s seed %d: %s' % (k + 1, len(todo), r[0], r[1], r[2], (r[3][3] if r[3] else 'нет результата')), flush=True)
    lines = ['# Отчёт о финалах (за %d месяцев)' % months, '',
             'Режимы: «без действий» — игрок только выбирает первый вариант в событиях; «автопилот» — включён автобаланс бюджета.', '',
             '| Страна | Режим | Месяц конца | Причина | ВВП | Долг % | Рейтинг | Конфликтов |', '|---|---|---|---|---|---|---|---|']
    stat = collections.Counter()
    for cc, mode, sd, r in sorted(res, key=lambda x: (ALL.index(x[0]), x[1], x[2])):
        if not r:
            lines.append('| %s | %s | — | нет результата | | | | |' % (cc, mode)); continue
        _, _, m, why, gdp, debt, appr, conf = r
        lines.append('| %s | %s | %s | %s | %s | %s | %s | %s |' % (cc, mode, m if why != 'дожила до лимита' else '—', why, gdp, debt, appr, conf))
        stat[(mode, why.split('.')[0][:60])] += 1
    lines += ['', '## Сводка по причинам', '']
    for (mode, why), n in sorted(stat.items()):
        lines.append('- %s: %s — %d' % (mode, why, n))
    open(os.path.join(ROOT, 'docs', 'FINALS.md'), 'w').write('\n'.join(lines) + '\n')
    print('Записано docs/FINALS.md')

if __name__ == '__main__':
    main()
