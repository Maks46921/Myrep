#!/usr/bin/env python3
"""Единый запуск тестов Symphony.

  tools/test.py quick                 быстрая проверка (~1 мин)
  tools/test.py full                  все тесты по всем странам (38)
  tools/test.py agents head -c DE,FR  выбранные тесты и страны
  tools/test.py golden --update       пересоздать эталоны (после ОСОЗНАННОГО изменения поведения)
  tools/test.py --list                список тестов
Флаги: -c CC,CC  страны; -j N  параллельность; -v  показать вывод упавших; --en  английская версия (en/).
"""
import argparse, os, re, subprocess, sys, time, concurrent.futures as cf

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOGS = os.path.join(ROOT, '.testlogs')
TEST_DIR = 'tests/'      # v54_1: --en -> en/tests/ (английская версия, собирается tools/i18n.py build)
ALL = 'DE FR NL BE LU AT CH CZ DK ES IT NO PL PT SE GB IE SI SK HU FI HR RS BA ME MK AL XK BG RO GR EE LV LT MD BY UA RU'.split()

# имя: (скрипт, доп.аргументы, таймаут, нужен ли seed-эталон)
TESTS = {
    'stubs':  ('-', [], 30),
    'load':   ('t_load.gd', [], 60),
    'smoke':  ('smoke.gd', [], 120),
    'fx':     ('t_fx.gd', [], 90),
    'fx2':    ('t_fx2.gd', [], 90),
    'cov':    ('t_cov.gd', [], 90),
    'head':   ('t_head.gd', [], 120),
    'start':  ('t_start.gd', [], 90),
    'agents': ('t_agents.gd', [], 150),
    'emit':   ('t_emit.gd', [], 90),
    'map':    ('t_map.gd', [], 90),
    'goods':  ('t_goods.gd', [], 90),
    'opts':   ('t_opts.gd', [], 150),
    'week':   ('t_week.gd', [], 200),
    'time':   ('t_time.gd', [], 60),
    'hybrid': ('t_hybrid.gd', [], 90),
    'opp':    ('t_opp.gd', [], 300),
    'ai':     ('t_ai.gd', [], 600),
    'budget': ('t_budget.gd', [], 90),
    'council': ('t_council.gd', [], 90),
    'coal':   ('t_coal.gd', ['coal=1'], 150),
    'world':  ('t_world.gd', [], 200),
    'far':    ('t_far.gd', [], 120),
    'fed':    ('t_fed.gd', [], 240),
    'adm':    ('t_adm.gd', [], 240),
    'quit':   ('t_quit.gd', [], 120),
    'war':    ('t_war.gd', [], 400),
    'warpol': ('t_warpol.gd', [], 300),
    'fleet':  ('t_fleet.gd', [], 200),
    'soc':    ('t_soc.gd', [], 300),
    'cult':   ('t_cult.gd', [], 240),
    'build2': ('t_build2.gd', [], 240),
    'tech':   ('t_tech.gd', [], 300),
    'techbal': ('t_techbal.gd', [], 240),
    'revolt': ('t_revolt.gd', [], 400),
    'realism': ('t_realism.gd', [], 400),
    'diplo2': ('t_diplo2.gd', [], 400),
    'events': ('t_events.gd', [], 400),
    'army':   ('t_army.gd', [], 400),
    'fpai': ('t_fpai.gd', [], 400),
    'agents2': ('t_agents2.gd', [], 400),
    'menu':   ('shot_menu.gd', [], 150),    # меню выбора страны (карта + карточка), нужен xvfb-run
    'width':  ('audit_width.gd', [], 120),  # элементы шире окна при 1366x768, нужен xvfb-run
    'click':  ('shot_click.gd', [], 120),
    'socclick': ('shot_socclick.gd', [], 120),
    'fedclick': ('shot_fedclick.gd', [], 120),
    'warclick': ('shot_warclick.gd', [], 150),   # реальные щелчки мышью, нужен xvfb-run
    'golden': ('t_golden.gd', ['seed=7', 'fedev=0', 'socev=0', 'exev=0', 'milev=0', 'revev=0', 'rlev=0', 'bldev=0'], 200),
    'long':   ('t_long.gd', [], 400),
    # v55_3: большой тест (скриншоты и находки — .testlogs/big/, отчёт — tools/big_report.py)
    'big_ui':   ('t_big.gd', ['part=ui'], 1500),    # все экраны, окна, слои карты, кнопки; нужен xvfb-run
    'big_mech': ('t_big.gd', ['part=mech'], 1500),  # все события и варианты, законы, меры, сохранения
    'big_bal':  ('t_big.gd', ['part=bal'], 900),    # 20 лет под управлением ИИ
}
BIG6 = ['DE', 'FR', 'GB', 'PL', 'UA', 'RU']
PROFILES = {
    'quick': [('stubs', ['-']), ('load', ['LU']), ('smoke', ['LU', 'DE']), ('fx2', ALL), ('cov', ['DE', 'LU', 'CH']), ('agents', ['LU']), ('emit', ['DE', 'PL', 'CH']), ('goods', ['DE', 'LU', 'NO']), ('opts', ['DE', 'LU']), ('time', ['DE']), ('hybrid', ['DE', 'GB']), ('opp', ['DE', 'LU']), ('budget', ['DE', 'GB']), ('council', ['DE', 'PL', 'NL']), ('coal', ['DE', 'PL']), ('far', ['DE', 'GB']), ('week', ['DE']), ('fed', ['DE', 'LU']), ('adm', ['DE', 'LU', 'FI']), ('quit', ['DE', 'CH', 'NL']), ('war', ['DE', 'LU', 'FI']), ('warpol', ['DE', 'HU']), ('fleet', ['DE', 'SK']), ('soc', ['DE', 'LU']), ('cult', ['DE', 'UA']), ('build2', ['DE', 'FI']), ('tech', ['DE', 'LU']), ('techbal', ['DE', 'PL']), ('revolt', ['DE', 'ES']), ('realism', ['DE', 'RS']), ('diplo2', ['DE', 'PL']), ('events', ['DE', 'GB']), ('fpai', ['DE', 'PL']), ('world', ['RU', 'BY', 'DE']), ('agents2', ['LU', 'DE']), ('army', ['DE', 'LU', 'FI']), ('fedclick', ['DE']), ('socclick', ['DE']), ('warclick', ['DE', 'IT']), ('map', ['DE', 'LU']), ('width', ['FR', 'CH']), ('menu', ['DE', 'LU']), ('golden', ['LU', 'FR'])],
    # v55_3: перед выпуском версии — большой тест на 6 странах (и ещё раз с --en)
    'big':   [('big_ui', BIG6), ('big_mech', BIG6), ('big_bal', BIG6), ('war', BIG6), ('revolt', BIG6), ('fed', BIG6), ('quit', BIG6), ('cult', BIG6), ('build2', BIG6), ('events', BIG6), ('golden', BIG6)],
    'full':  [('stubs', ['-'])] + [(t, ALL) for t in TESTS if t not in ('load', 'stubs') and not t.startswith('big_')],
}
BAD = re.compile(r'SCRIPT ERROR|Parse Error|^ERROR:|FAIL|Invalid (call|access|get|set)|Nonexistent|Cannot (call|infer|get)')
RULES = [  # (regex, функция-проверка значения -> текст ошибки или None)
    (r'проблем (\d+)', lambda v: 'проблем %s' % v if int(v) > 0 else None),
    (r'\bbad (\d+)', lambda v: 'bad %s' % v if int(v) > 0 else None),
    (r'находок (\d+)', lambda v: None),
    (r'NaN (\d+)', lambda v: 'NaN %s' % v if int(v) > 0 else None),
    (r'^NAN ', lambda v: 'NaN в состоянии'),
    (r'расхождение с прежней моделью: макс ([\d.]+)', lambda v: 'агенты расходятся с моделью групп на %s п.п.' % v if float(v) > 1.0 else None),
    (r'группы: макс откл\. ([\d.]+)', lambda v: 'рейтинг группы != среднее агентов (%s)' % v if float(v) > 0.01 else None),
    (r'отношение ([\d.]+)', lambda v: 'полукруг: точки слипаются (%s)' % v if float(v) < 1.0 else None),
    (r'(regional_econ false|регион-состояние false|регионов 0\b)', lambda v: 'покрытие: %s' % v),
]


def run_stubs():
    t0 = time.time()
    p = subprocess.run([sys.executable, os.path.join(ROOT, 'tools', 'stubs.py'), '--check'], capture_output=True, text=True)
    errs = [] if p.returncode == 0 else [l for l in (p.stdout + p.stderr).split('\n') if l.strip()][:3]
    return 'stubs', '-', errs, time.time() - t0, p.stdout + p.stderr


SLOW = {"RU": 3.0, "UA": 1.3}


def run_one(test, cc, update):
    if test == 'stubs':
        return run_stubs()
    script, extra, tmo = TESTS[test]
    tmo = tmo * SLOW.get(cc, 1.0)       # v50: у России 89 субъектов — прогон заметно дольше
    tmo = tmo * float(os.environ.get('SYM_TMULT', '1'))  # 0.56: медленная машина — SYM_TMULT=3
    gui = test in ('click', 'width', 'menu', 'fedclick', 'socclick', 'warclick', 'big_ui')
    cmd = [os.path.join(ROOT, 'tools', 'godot.sh')] + (['--rendering-driver', 'opengl3'] if gui else ['--headless']) + ['--path', ROOT, '--script', TEST_DIR + script, '--', 'country=' + cc] + extra
    if gui:
        cmd = ['xvfb-run', '-a', '-s', '-screen 0 %s' % ('1366x768x24' if test == 'width' else '1700x900x24')] + cmd
    t0 = time.time()
    import threading
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, cwd=ROOT, errors='replace')
    buf = []
    fatal = [None]

    def reader():
        for line in proc.stdout:
            buf.append(line)
            if fatal[0] is None and re.search(r'SCRIPT ERROR|Parse Error', line):
                fatal[0] = time.time()
    th = threading.Thread(target=reader, daemon=True)
    th.start()
    killed = ''
    while proc.poll() is None:
        time.sleep(0.2)
        if time.time() - t0 > tmo:
            killed = '\nFAIL: таймаут %ds' % tmo
        elif fatal[0] is not None and time.time() - fatal[0] > 1.5:
            killed = '\nFAIL: скрипт упал с ошибкой (процесс остановлен)'
        if killed:
            proc.kill()
            break
    proc.wait()
    th.join(timeout=2)
    out = ''.join(buf) + killed
    rc = 1 if killed else proc.returncode
    out = '\n'.join(l for l in out.split('\n') if not l.startswith('Godot Engine'))
    errs = []
    if rc != 0:
        errs.append('код возврата %s' % rc)
    for ln in out.split('\n'):
        if BAD.search(ln) and 'ERR_CANT_OPEN' not in ln:
            errs.append(ln.strip()[:160])
    for rx, fn in RULES:
        for m in re.finditer(rx, out, re.M):
            e = fn(m.group(1) if m.groups() else m.group(0))
            if e:
                errs.append(e)
    if test == 'golden':
        gp = os.path.join(ROOT, 'tests', 'golden', cc + '.txt')
        if update:
            os.makedirs(os.path.dirname(gp), exist_ok=True)
            open(gp, 'w', encoding='utf-8').write(out.strip() + '\n')
        elif not os.path.exists(gp):
            errs.append('нет эталона tests/golden/%s.txt (tools/test.py golden --update)' % cc)
        else:
            ref = open(gp, encoding='utf-8').read().strip().split('\n')
            cur = out.strip().split('\n')
            if ref != cur:
                for a, b in zip(ref, cur):
                    if a != b:
                        errs.append('эталон: было «%s» стало «%s»' % (a[:90], b[:90]))
                        break
                else:
                    errs.append('эталон: разное число строк')
    os.makedirs(LOGS, exist_ok=True)
    open(os.path.join(LOGS, '%s%s_%s.log' % ('en_' if TEST_DIR != 'tests/' else '', test, cc)), 'w', encoding='utf-8').write(out)
    return test, cc, errs, time.time() - t0, out


def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument('what', nargs='*')
    ap.add_argument('-c', default='')
    ap.add_argument('-j', type=int, default=os.cpu_count() or 2)
    ap.add_argument('-v', action='store_true')
    ap.add_argument('--update', action='store_true')
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--en', action='store_true')
    ap.add_argument('-h', '--help', action='store_true')
    a = ap.parse_args()
    if a.en:
        global TEST_DIR
        TEST_DIR = 'en/tests/'
    if a.help or (not a.what and not a.list):
        print(__doc__)
        return 0
    if a.list:
        for t, (s, e, tm) in TESTS.items():
            print('%-8s %s %s' % (t, s, ' '.join(e)))
        print('профили:', ', '.join(PROFILES))
        return 0
    plan = []
    for w in a.what:
        if w in PROFILES:
            plan += PROFILES[w]
        elif w in TESTS:
            plan.append((w, None))
        else:
            print('неизвестный тест/профиль:', w); return 2
    jobs = []
    for t, ccs in plan:
        lst = ['-'] if t == 'stubs' else (a.c.split(',') if a.c else (ccs or ALL))
        for cc in lst:
            jobs.append((t, cc))
    t0 = time.time()
    res = {}
    fails = []
    with cf.ThreadPoolExecutor(max_workers=a.j) as ex:
        futs = [ex.submit(run_one, t, cc, a.update) for t, cc in jobs]
        for i, f in enumerate(cf.as_completed(futs), 1):
            t, cc, errs, dt, out = f.result()
            res[(t, cc)] = (errs, dt)
            mark = '✗' if errs else '✓'
            print('[%d/%d] %s %-7s %s %.0fс' % (i, len(jobs), mark, t, cc, dt), flush=True)
            if errs:
                fails.append((t, cc, errs, out))
    print('\n=== Сводка (%.0f с) ===' % (time.time() - t0))
    tests = [t for t in TESTS if any(k[0] == t for k in res)]
    ccs = [c for c in ALL if any(k[1] == c for k in res)]
    if any(k[1] == '-' for k in res) and not ccs:
        ccs = ['-']
    print('%-8s' % '' + ' '.join('%-3s' % c[:2] if False else c for c in ccs))
    for t in tests:
        row = '%-8s' % t
        for c in ccs:
            r = res.get((t, c)) or (res.get((t, '-')) if t == 'stubs' and c == ccs[0] else None)
            row += ' ' + (' - ' if r is None else (' ✗ ' if r[0] else ' ✓ '))
        print(row)
    if fails:
        print('\n--- Ошибки ---')
        for t, cc, errs, out in sorted(fails):
            print('%s %s:' % (t, cc))
            for e in errs[:4]:
                print('    ' + e)
            if a.v:
                print('\n'.join('    | ' + l for l in out.split('\n')[-15:]))
        print('\nЛоги: %s' % LOGS)
        return 1
    print('\nВсе %d проверок пройдены.' % len(jobs))
    return 0


if __name__ == '__main__':
    sys.exit(main())
