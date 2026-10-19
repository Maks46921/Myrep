#!/usr/bin/env python3
# 0.56: отчёт по симуляции 38 стран × 30 лет (.testlogs/sim30_XX.tsv) и сверка стартовых опросов игры с реальными опросами 2026.
import csv, glob, os, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = sys.argv[1] if len(sys.argv) > 1 else '/mnt/project-files/symphony/reports/0.56'
CAP = 35.0
def load(path):
    rows, hdr = [], None
    for line in open(path, encoding='utf-8'):
        c = line.rstrip('\n').split('\t')
        if c[0] == 'year': hdr = c; continue
        if hdr is None or c[0] == 'END': continue
        rows.append(c)
    return hdr, rows
data = {}
for f in sorted(glob.glob(os.path.join(ROOT, '.testlogs/sim30_*.tsv'))):
    cc = os.path.basename(f)[6:8]
    h, rows = load(f)
    if not h: continue
    parties = h[10:]
    yearly, elec = [], []
    for r in rows:
        try:
            vals = [float(x) for x in r[-len(parties):]] if r[0] != 'ELECTION' else [float(x) for x in r[-len(parties):]]
        except ValueError:
            continue
        if r[0] == 'ELECTION':
            elec.append((int(r[1]), vals, r[8]))
        else:
            yearly.append((int(r[0]), vals, r))
    data[cc] = {'parties': parties, 'yearly': yearly, 'elec': elec, 'hdr': h}
polls = {}
pf = os.path.join(OUT, 'polls_2026.tsv')
if os.path.exists(pf):
    for r in csv.DictReader(open(pf, encoding='utf-8'), delimiter='\t'):
        polls.setdefault(r['country'], {})[int(r['slot'])] = (float(r['poll_pct']), r['game_party'])
L = ['# Симуляция 38 стран × 30 лет и сверка с опросами 2026', '', 'Сводка по `.testlogs/sim30_XX.tsv`: годовые доли партий (национальный расчёт по текущему настроению) и итоги выборов. Все страны играет ИИ-событий (выбор первого варианта), игрок не вмешивается.', '']
L += ['## 1. Потолок партии (35% по умолчанию, в демократиях не выше 60%) и предел сдвига за выборы (10 п.п.)', '',
      '| Страна | Макс. доля за 30 лет | Партия | Год | Макс. сдвиг между выборами, п.п. | Партия | Выборов | Конец игры |', '|---|---|---|---|---|---|---|---|']
over = []
for cc, d in data.items():
    mx, mp, my = 0.0, '', 0
    for y, v, _ in d['yearly']:
        for i, x in enumerate(v):
            if x > mx: mx, mp, my = x, d['parties'][i], y
    sw, sp = 0.0, ''
    prev = None
    for y, v, _ in d['elec']:
        if prev is not None:
            for i, x in enumerate(v):
                if abs(x - prev[i]) > sw: sw, sp = abs(x - prev[i]), d['parties'][i]
        prev = v
    last = d['yearly'][-1][0] if d['yearly'] else 0
    L.append('| %s | %.1f | %s | %d | %.1f | %s | %d | %s |' % (cc, mx, mp, my, sw, sp, len(d['elec']), 'год %d' % last))
    if mx > 45.0: over.append((cc, mp, mx))
L += ['', 'Выше 45% за 30 лет: ' + (', '.join('%s %s %.1f%%' % o for o in over) if over else 'нет'), '']
# сверка стартовых долей
L += ['## 2. Старт игры против реальных опросов 2026', '', 'Разница = игра − реальность (п.п.). Берутся партии с долей выше 3% в игре или в опросе. Опросы собраны по пересказам в новостях, слабые места помечены в `polls_2026_notes.md`.', '',
      '| Страна | Партия | Игра | Опрос | Разница |', '|---|---|---|---|---|']
tot_abs, n = {}, 0
for cc, d in data.items():
    start = None
    for y, v, _ in d['yearly']:
        if y == 0: start = v
    if start is None: continue
    pl = polls.get(cc)
    if not pl: continue
    s_sum = sum(abs(start[i] - pl.get(i, (0, ''))[0]) for i in range(len(start))) / 2.0
    tot_abs[cc] = s_sum
    for i, x in enumerate(start):
        pv = pl.get(i, (0.0, ''))[0]
        if x >= 3.0 or pv >= 3.0:
            L.append('| %s | %s | %.1f | %.1f | %+.1f |' % (cc, d['parties'][i], x, pv, x - pv))
L += ['', '### Расхождение по странам (половина суммы модулей разностей, п.п.)', '', '| Страна | Расхождение |', '|---|---|']
for cc, v in sorted(tot_abs.items(), key=lambda kv: -kv[1]):
    L.append('| %s | %.1f |' % (cc, v))
# --- причины конца игры (игрок ничего не делает, на каждое событие выбирается первый вариант) ---
reasons = {}
ends = {}
for f in sorted(glob.glob(os.path.join(ROOT, '.testlogs/sim30_*.tsv'))):
    cc = os.path.basename(f)[6:8]
    last = open(f, encoding='utf-8').read().strip().split('\n')[-1].split('\t')
    if last[0] == 'END':
        kv = dict(x.split('=', 1) for x in last[1:] if '=' in x)
        ends[cc] = kv
L += ['', '## 3. Чем закончились 30 лет', '', 'Игрок ничего не делает, на каждое событие выбирается первый вариант, так что конец игры раньше срока — не ошибка, а следствие бездействия. Случайность не фиксируется, поэтому повторный прогон даёт другой исход.', '',
      '| Страна | Месяцев сыграно | Конец игры | Причина |', '|---|---|---|---|']
for cc in sorted(ends):
    kv = ends[cc]
    L.append('| %s | %s | %s | %s |' % (cc, kv.get('turn', '?'), 'да' if kv.get('game_over') == 'true' else 'нет', kv.get('reason', '') if kv.get('game_over') == 'true' else ''))
    if kv.get('game_over') == 'true':
        reasons[kv.get('reason', '?')[:40]] = reasons.get(kv.get('reason', '?')[:40], 0) + 1
L += ['', 'Сводка причин: ' + '; '.join('%s — %d' % (k, v) for k, v in sorted(reasons.items(), key=lambda kv: -kv[1])) if reasons else 'Все игры дошли до конца.', '']
# --- правые популисты: поведение ---
PAT = [('DE', 'АдГ'), ('AT', 'FPÖ'), ('FR', 'Национальное объединение'), ('GB', 'Reform UK'), ('NL', 'Партия свободы'), ('PT', 'Chega'), ('BE', 'Vlaams Belang'), ('RO', 'AUR'), ('SE', 'Шведские демократы'), ('IT', 'Fratelli'), ('CH', 'SVP')]
L += ['## 4. Правые популисты (АдГ и похожие): как ведут себя в симуляции', '',
      'Старт — доля в игре на начало (год 0); минимум и максимум — по годовым данным за все годы игры; рост при кризисе — прирост доли за год, в котором безработица выросла на 0,5 п.п. и больше (среднее по таким годам), в остальные годы — среднее изменение за год.', '',
      '| Страна | Партия | Старт | Мин. | Макс. | Конец | Рост за год при росте безработицы | Среднее изменение в остальные годы |', '|---|---|---|---|---|---|---|---|']
for cc, key in PAT:
    d = data.get(cc)
    if not d: continue
    idx = [i for i, n in enumerate(d['parties']) if key in n]
    if not idx: continue
    i = idx[0]
    ys = d['yearly']
    ser = [(y, v[i], float(r[4])) for y, v, r in ys]
    if len(ser) < 3: continue
    cr, ot = [], []
    for k in range(1, len(ser)):
        du = ser[k][2] - ser[k - 1][2]
        dv = ser[k][1] - ser[k - 1][1]
        (cr if du >= 0.5 else ot).append(dv)
    L.append('| %s | %s | %.1f | %.1f | %.1f | %.1f | %s | %s |' % (cc, d['parties'][i][:40], ser[0][1], min(s[1] for s in ser), max(s[1] for s in ser), ser[-1][1],
             ('%+.1f (лет: %d)' % (sum(cr) / len(cr), len(cr))) if cr else 'нет таких лет', ('%+.1f' % (sum(ot) / len(ot))) if ot else '—'))
fdp = os.path.join(OUT, 'fdp_case.md')
if os.path.exists(fdp):
    L += ['', open(fdp, encoding='utf-8').read()]
open(os.path.join(OUT, 'sim30_report.md'), 'w', encoding='utf-8').write('\n'.join(L) + '\n')
print('written', len(data), 'countries')
