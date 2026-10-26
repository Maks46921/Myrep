#!/usr/bin/env python3
"""0.64 (п. 4): отчёт по прогонам проверки реалистичности (tests/audit_real64.gd, очередь tools/real64_run.py).
  python3 tools/real64_report.py --in .testlogs/real64 --out /mnt/project-files/symphony/reality/real64
Пишет: <out>/report.md, <out>/report.html (с графиками внутри), <out>/short.md, <out>/graphs/*.png, <out>/checks.csv.
Коридоры «как в жизни» заданы здесь же (CORR, SCN_DELTA, ...): это допущения автора, их можно править.
"""
import argparse, base64, csv, glob, html, json, os, statistics as st
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

NAMES = {'RU': 'Россия', 'BY': 'Беларусь', 'UA': 'Украина'}
SCN = {'calm': 'спокойная игра', 'war': 'затяжная война', 'oil': 'обвал нефти', 'sanctions': 'полные санкции', 'leader': 'смена власти',
       'mobilize': 'мобилизация', 'unrest': 'нестабильность', 'weird': 'нестандартная игра', 'union': 'союз России и Беларуси', 'eunato': 'Украина в ЕС и НАТО'}
# коридоры годовых показателей (мин, макс) для спокойной игры; допущение: старт январь 2026
CORR = {
    'RU': {'growth': (-2.5, 4.5), 'infl': (3.0, 14.0), 'unemp': (2.0, 7.0), 'debt_pct': (8.0, 45.0)},
    'BY': {'growth': (-2.5, 4.0), 'infl': (3.0, 14.0), 'unemp': (1.0, 7.0), 'debt_pct': (20.0, 60.0)},
    'UA': {'growth': (-3.0, 7.0), 'infl': (3.0, 16.0), 'unemp': (6.0, 18.0), 'debt_pct': (60.0, 160.0)},
}
LBL = {'growth': 'рост ВВП, %', 'infl': 'инфляция, %', 'unemp': 'безработица, %', 'debt_pct': 'долг, % ВВП', 'appr': 'одобрение, %', 'gdp_idx': 'ВВП, 2026 = 100',
       'score': 'счёт войны', 'rel_RU_BY': 'отношения Россия — Беларусь', 'rel_BY_UA': 'отношения Беларусь — Украина'}
CAGR = {'RU': (0.0, 5.0), 'BY': (0.0, 4.5), 'UA': (0.5, 7.0)}


def load(d):
    runs = {}
    for f in sorted(glob.glob(os.path.join(d, '*.json'))):
        r = json.load(open(f, encoding='utf8'))
        runs.setdefault((r['cc'], r['scn']), []).append(r)
    return runs


def q(v, p):
    v = sorted(x for x in v if x is not None)
    if not v:
        return None
    k = (len(v) - 1) * p
    lo, hi = int(k), min(len(v) - 1, int(k) + 1)
    return v[lo] + (v[hi] - v[lo]) * (k - lo)


def series(rs, fn, y):
    out = []
    for r in rs:
        rows = {x['year']: x for x in r['rows']}
        if y in rows:
            try:
                out.append(fn(rows[y], r))
            except Exception:
                pass
    return out


def metric_fn(m):
    if m == 'gdp_idx':
        return lambda x, r: x['gdp'] / r['rows'][0]['gdp'] * 100.0
    if m == 'score':
        return lambda x, r: x['war'].get('score') if x['war'].get('at_war') else None
    if m.startswith('rel_'):
        a, b = m[4:].split('_')
        return lambda x, r: (x['rel'].get(b) if a == r['cc'] else None) if False else x['rel'].get(b if a == r['cc'] else a)
    return lambda x, r: x[m]


def med(rs, m, y0, y1):
    v = []
    for y in range(y0, y1 + 1):
        v += [t for t in series(rs, metric_fn(m), y) if t is not None]
    return st.median(v) if v else None


class Check:
    def __init__(self, cc, scn, name, expect, got, sev, comment=''):
        self.cc, self.scn, self.name, self.expect, self.got, self.sev, self.comment = cc, scn, name, expect, got, sev, comment


def sev_of(frac, ok=0.10, bad=0.40):
    return 0 if frac <= ok else (1 if frac <= bad else 2)


def corridor_checks(runs, out):
    for cc in ('RU', 'BY', 'UA'):
        rs = runs.get((cc, 'calm'), [])
        if not rs:
            continue
        for m, (lo, hi) in CORR[cc].items():
            tot = bad = 0
            for y in range(1, 26):
                for v in series(rs, metric_fn(m), y):
                    tot += 1
                    bad += (v < lo or v > hi)
            if tot:
                fr = bad / tot
                out.append(Check(cc, 'calm', LBL[m], '%.1f … %.1f' % (lo, hi), '%d%% лет вне коридора, медиана %.1f' % (round(fr * 100), med(rs, m, 1, 25)), sev_of(fr)))
        cg = []
        for r in rs:
            g0, g1 = r['rows'][0]['gdp'], r['rows'][-1]['gdp']
            n = r['rows'][-1]['year']
            if n >= 10 and g0 > 0 and g1 > 0:
                cg.append(((g1 / g0) ** (1.0 / n) - 1.0) * 100.0)
        if cg:
            lo, hi = CAGR[cc]
            fr = sum(1 for v in cg if v < lo or v > hi) / len(cg)
            out.append(Check(cc, 'calm', 'годовой рост ВВП за весь срок', '%.1f … %.1f %%' % (lo, hi), '%d%% прогонов вне коридора, медиана %.1f %%' % (round(fr * 100), st.median(cg)), sev_of(fr)))
        # игра окончена раньше срока
        over = sum(1 for r in rs if r['game_over'] and r['rows'][-1]['year'] < r['years'])
        out.append(Check(cc, 'calm', 'крах государства до конца срока', 'не более 10 % прогонов', '%d из %d (%s)' % (over, len(rs), '; '.join(sorted(set(str(r['end'])[:60] for r in rs if r['game_over'])))[:150]), sev_of(over / len(rs), 0.10, 0.25)))
        # режим
        if cc in ('RU', 'BY'):
            aut = sum(1 for r in rs if r['rows'][-1]['au_on'])
            out.append(Check(cc, 'calm', 'режим остаётся недемократическим к концу срока', 'не менее 75 % прогонов', '%d из %d' % (aut, len(rs)), 0 if aut / len(rs) >= 0.75 else (1 if aut / len(rs) >= 0.5 else 2)))
        else:
            dem = sum(1 for r in rs if not r['rows'][-1]['au_on'])
            out.append(Check(cc, 'calm', 'Украина остаётся демократией', 'не менее 85 % прогонов', '%d из %d' % (dem, len(rs)), 0 if dem / len(rs) >= 0.85 else (1 if dem / len(rs) >= 0.6 else 2)))
        # длина войны
        if cc in ('RU', 'UA'):
            ends = []
            for r in rs:
                e = None
                for x in r['rows']:
                    if x['year'] > 0 and not x['war'].get('at_war'):
                        e = x['year']
                        break
                ends.append(e)
            n = len(ends)
            for yr, lo in ((3, 0.10), (6, 0.30), (12, 0.70), (25, 0.90)):
                fr = sum(1 for e in ends if e is not None and e <= yr) / n
                out.append(Check(cc, 'calm', 'война закончена к %d-му году (по правилу п. 5 мир только после взятия Донецка и нейтралитета Украины)' % yr, 'не менее %d %% прогонов' % (lo * 100), '%d %%' % round(fr * 100), 0 if fr >= lo else 1))
            early = sum(1 for e in ends if e is not None and e <= 1) / n
            out.append(Check(cc, 'calm', 'война закончена за первый год', 'не более 15 % прогонов', '%d %%' % round(early * 100), 0 if early <= 0.15 else (1 if early <= 0.3 else 2)))
        # отношения
        rel_ru_by = med(rs, 'rel_RU_BY', 1, 25)
        if rel_ru_by is not None and cc in ('RU', 'BY'):
            out.append(Check(cc, 'calm', 'отношения России и Беларуси', 'медиана не ниже 70', '%.0f' % rel_ru_by, 0 if rel_ru_by >= 70 else (1 if rel_ru_by >= 55 else 2)))


def delta_checks(runs, out):
    # (страна, сценарий, показатель, годы, (мин Δ, макс Δ), пояснение)
    rules = [
        ('RU', 'oil', 'growth', (1, 4), (-4.0, 0.3), 'обвал нефти бьёт по росту России (2014–16: ВВП России упал примерно на 3 % за два года)'),
        ('BY', 'oil', 'growth', (1, 4), (-2.0, 0.1), 'Беларусь зависит от российской нефти и экспорта нефтепродуктов, но слабее'),
        ('UA', 'oil', 'growth', (1, 4), (-0.8, 0.8), 'Украина почти не зависит от цены нефти'),
        ('BY', 'sanctions', 'growth', (1, 4), (-3.0, -0.2), 'полные санкции против Беларуси'),
        ('RU', 'sanctions', 'growth', (1, 4), (-2.5, 0.5), 'у России санкции уже на пределе: слабая добавка'),
        ('RU', 'mobilize', 'growth', (2, 5), (-3.0, 0.3), 'мобилизация изымает работников'),
        ('UA', 'mobilize', 'growth', (2, 5), (-3.0, 0.5), 'мобилизация изымает работников'),
        ('RU', 'mobilize', 'appr', (2, 5), (-30.0, 0.0), 'мобилизация непопулярна'),
        ('UA', 'mobilize', 'appr', (2, 5), (-30.0, 0.0), 'мобилизация непопулярна'),
        ('RU', 'unrest', 'appr', (1, 4), (-35.0, -2.0), 'протесты роняют одобрение'),
        ('BY', 'unrest', 'appr', (1, 4), (-35.0, -2.0), 'протесты роняют одобрение'),
        ('UA', 'unrest', 'appr', (1, 4), (-35.0, -2.0), 'протесты роняют одобрение'),
        ('UA', 'eunato', 'growth', (4, 10), (0.0, 4.0), 'ЕС и фонды восстановления ускоряют рост'),
        ('RU', 'union', 'gdp_idx', (4, 10), (0.0, 8.0), 'Беларусь — около 4 % российской экономики: союз не должен ни обваливать, ни сильно раздувать ВВП (в % от спокойной игры)'),
    ]
    for cc, scn, m, (y0, y1), (lo, hi), why in rules:
        a, b = runs.get((cc, scn), []), runs.get((cc, 'calm'), [])
        if not a or not b:
            continue
        va, vb = med(a, m, y0, y1), med(b, m, y0, y1)
        if va is None or vb is None:
            continue
        d = (va / vb - 1.0) * 100.0 if m == 'gdp_idx' else va - vb
        ok = lo <= d <= hi
        sev = 0 if ok else (1 if (lo - 1.5 <= d <= hi + 1.5) else 2)
        if scn == 'unrest' and sev == 2:
            sev = 1   # сценарий двигает недовольство регионов напрямую; настоящие протесты идут через модуль восстаний
        out.append(Check(cc, scn, '%s, годы %d–%d, отличие от спокойной игры' % (LBL[m], y0, y1), '%+.1f … %+.1f' % (lo, hi), '%+.1f (%.1f против %.1f)' % (d, va, vb), sev, why))
    # устойчивость при сложных сценариях
    for (cc, scn), rs in sorted(runs.items()):
        if scn in ('weird', 'unrest', 'leader', 'mobilize', 'oil', 'sanctions', 'war', 'union', 'eunato'):
            over = sum(1 for r in rs if r['game_over'] and r['rows'][-1]['year'] < r['years'])
            lim = 0.25 if scn in ('unrest', 'weird', 'leader') else 0.15
            out.append(Check(cc, scn, 'крах государства', 'не более %d %% прогонов' % (lim * 100), '%d из %d' % (over, len(rs)), sev_of(over / len(rs), lim, lim * 2.0)))
            bad = 0
            for r in rs:
                for x in r['rows']:
                    for k in ('gdp', 'growth', 'infl', 'unemp', 'debt_pct'):
                        v = x[k]
                        if v is None or v != v or abs(v) > 1e9:
                            bad += 1
            out.append(Check(cc, scn, 'числа конечные (нет NaN и бесконечностей)', '0', str(bad), 0 if bad == 0 else 2))
    # смена власти: события
    for cc in ('RU', 'BY'):
        rs = runs.get((cc, 'leader'), [])
        if rs:
            surv = sum(1 for r in rs if r['rows'][-1]['au_on'] and not r['game_over'])
            out.append(Check(cc, 'leader', 'режим переживает смену правителя (через 10 лет после)', 'не менее 60 % прогонов', '%d из %d' % (surv, len(rs)), 0 if surv / len(rs) >= 0.6 else (1 if surv / len(rs) >= 0.4 else 2)))
    rs = runs.get(('UA', 'eunato'), [])
    if rs:
        okn = sum(1 for r in rs if r['rows'][-1]['nato'].get('UA'))
        out.append(Check('UA', 'eunato', 'Украина числится в НАТО после вступления', '100 %', '%d из %d' % (okn, len(rs)), 0 if okn == len(rs) else 2))
    # война: затяжная должна держаться
    for cc in ('RU', 'UA'):
        rs = runs.get((cc, 'war'), [])
        if rs:
            end = sum(1 for r in rs if not r['rows'][-1]['war'].get('at_war'))
            out.append(Check(cc, 'war', 'затяжная война: мир без согласия игрока', 'не более 30 % прогонов', '%d из %d' % (end, len(rs)), sev_of(end / len(rs), 0.3, 0.6)))
    # военные потери за 10 лет в затяжной войне (тыс. убитых)
    for cc in ('RU', 'UA'):
        rs = runs.get((cc, 'war'), [])
        if rs:
            v = []
            for r in rs:
                for x in r['rows']:
                    if x['year'] == 10 and x['war'].get('at_war'):
                        v.append(x['war']['kia0'] + x['war']['kia1'])
            if v:
                m = st.median(v)
                out.append(Check(cc, 'war', 'потери сторон за 10 лет затяжной войны, тыс.', '300 … 3000', '%.0f' % m, 0 if 300 <= m <= 3000 else (1 if 150 <= m <= 6000 else 2)))


def plot(runs, outdir):
    os.makedirs(outdir, exist_ok=True)
    files = []
    cols = {'RU': '#c0392b', 'BY': '#2e8b57', 'UA': '#2563eb'}
    for m in ('growth', 'infl', 'unemp', 'debt_pct', 'gdp_idx'):
        fig, axes = plt.subplots(1, 3, figsize=(13, 3.6), sharey=False)
        for ax, cc in zip(axes, ('RU', 'BY', 'UA')):
            rs = runs.get((cc, 'calm'), [])
            if not rs:
                ax.set_title(NAMES[cc] + ': нет данных')
                continue
            ys = list(range(0, 26))
            lo = [q(series(rs, metric_fn(m), y), 0.1) for y in ys]
            md = [q(series(rs, metric_fn(m), y), 0.5) for y in ys]
            hi = [q(series(rs, metric_fn(m), y), 0.9) for y in ys]
            xs = [y for y, a in zip(ys, md) if a is not None]
            ax.fill_between(xs, [a for a, b in zip(lo, md) if b is not None], [a for a, b in zip(hi, md) if b is not None], color=cols[cc], alpha=0.18, label='10–90 %')
            ax.plot(xs, [a for a in md if a is not None], color=cols[cc], lw=2, label='медиана')
            if m in CORR[cc]:
                ax.axhspan(CORR[cc][m][0], CORR[cc][m][1], color='#888', alpha=0.12, label='коридор «как в жизни»')
            ax.set_title('%s: %s' % (NAMES[cc], LBL[m]), fontsize=10)
            ax.set_xlabel('год игры')
            ax.grid(alpha=0.25)
        axes[0].legend(fontsize=7)
        fig.tight_layout()
        p = os.path.join(outdir, 'calm_%s.png' % m)
        fig.savefig(p, dpi=110)
        plt.close(fig)
        files.append((p, 'Спокойная игра: ' + LBL[m]))
    # сравнение сценариев по росту
    fig, axes = plt.subplots(1, 3, figsize=(13, 3.8))
    for ax, cc in zip(axes, ('RU', 'BY', 'UA')):
        for scn in ('calm', 'oil', 'sanctions', 'mobilize', 'unrest', 'eunato', 'union'):
            rs = runs.get((cc, scn), [])
            if not rs:
                continue
            xs = list(range(1, 26))
            md = [q(series(rs, metric_fn('growth'), y), 0.5) for y in xs]
            ax.plot([x for x, a in zip(xs, md) if a is not None], [a for a in md if a is not None], lw=2 if scn == 'calm' else 1.2, label=SCN[scn])
        ax.set_title('%s: рост ВВП по сценариям (медиана)' % NAMES[cc], fontsize=10)
        ax.grid(alpha=0.25)
        ax.set_xlabel('год игры')
    axes[0].legend(fontsize=7)
    fig.tight_layout()
    p = os.path.join(outdir, 'scenarios_growth.png')
    fig.savefig(p, dpi=110)
    plt.close(fig)
    files.append((p, 'Рост ВВП по сценариям'))
    # доля войн, ещё идущих
    fig, axes = plt.subplots(1, 2, figsize=(9, 3.6))
    for ax, cc in zip(axes, ('RU', 'UA')):
        for scn in ('calm', 'war', 'leader', 'mobilize'):
            rs = runs.get((cc, scn), [])
            if not rs:
                continue
            xs = list(range(0, 26))
            fr = []
            for y in xs:
                v = [x['war'].get('at_war') for x in [{r2['year']: r2 for r2 in r['rows']}.get(y) for r in rs] if x]
                fr.append(sum(1 for t in v if t) / len(v) * 100.0 if v else None)
            ax.plot([x for x, a in zip(xs, fr) if a is not None], [a for a in fr if a is not None], label=SCN[scn])
        ax.set_title('%s: доля прогонов, где война идёт, %%' % NAMES[cc], fontsize=10)
        ax.set_ylim(-3, 103)
        ax.grid(alpha=0.25)
        ax.set_xlabel('год игры')
    axes[0].legend(fontsize=7)
    fig.tight_layout()
    p = os.path.join(outdir, 'war_share.png')
    fig.savefig(p, dpi=110)
    plt.close(fig)
    files.append((p, 'Доля прогонов с идущей войной'))
    return files


ICON = ['✅', '⚠️', '❌']


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--in', dest='inp', default='.testlogs/real64')
    ap.add_argument('--out', default='real64_report')
    ap.add_argument('--extra-short', dest='extra_short', default='', help='то же для короткого списка')
    ap.add_argument('--extra', default='', help='файл .md с выводами автора: вставляется в начало отчёта и короткого списка')
    a = ap.parse_args()
    runs = load(a.inp)
    os.makedirs(a.out, exist_ok=True)
    checks = []
    corridor_checks(runs, checks)
    delta_checks(runs, checks)
    graphs = plot(runs, os.path.join(a.out, 'graphs'))
    n_runs = sum(len(v) for v in runs.values())
    cnt = [sum(1 for c in checks if c.sev == s) for s in (0, 1, 2)]
    with open(os.path.join(a.out, 'checks.csv'), 'w', newline='', encoding='utf8') as f:
        w = csv.writer(f)
        w.writerow(['страна', 'сценарий', 'проверка', 'ожидание', 'получено', 'оценка', 'пояснение'])
        for c in checks:
            w.writerow([NAMES[c.cc], SCN.get(c.scn, c.scn), c.name, c.expect, c.got, ICON[c.sev], c.comment])
    md = ['# Проверка реалистичности: Россия, Беларусь, Украина (версия 0.64)', '',
          'Прогонов: **%d** (%s). Каждый — до 25 лет игры в режиме наблюдателя (ИИ ведёт партию, бюджет, события и законы); старт январь 2026.' % (n_runs,
            ', '.join('%s/%s: %d' % (cc, scn, len(v)) for (cc, scn), v in sorted(runs.items()))), '',
          'Итог: ✅ %d, ⚠️ %d, ❌ %d проверок.' % tuple(cnt), '']
    extra = open(a.extra, encoding='utf8').read().strip() if a.extra else ''
    if extra:
        md += [extra, '']
    md.append('## Таблица отклонений')
    md.append('')
    md.append('| Страна | Сценарий | Проверка | Как в жизни | Получилось | |')
    md.append('|---|---|---|---|---|---|')
    for c in sorted(checks, key=lambda c: (-c.sev, c.cc, c.scn)):
        md.append('| %s | %s | %s | %s | %s | %s |' % (NAMES[c.cc], SCN.get(c.scn, c.scn), c.name, c.expect, c.got.replace('|', '/'), ICON[c.sev]))
    md.append('')
    md.append('## Графики')
    for p, t in graphs:
        md.append('![%s](graphs/%s)' % (t, os.path.basename(p)))
    notes = []
    for (cc, scn), rs in sorted(runs.items()):
        for r in rs[:1]:
            for n in r['notes'][:4]:
                notes.append('- %s / %s: %s' % (NAMES[cc], SCN.get(scn, scn), n))
    md.append('')
    md.append('## События в сценариях (пример первого прогона)')
    md += notes
    open(os.path.join(a.out, 'report.md'), 'w', encoding='utf8').write('\n'.join(md) + '\n')
    # html
    h = ['<!doctype html><meta charset="utf-8"><title>Проверка реалистичности 0.64</title><style>body{font:14px system-ui;margin:24px auto;max-width:1100px;padding:0 16px}',
         'table{border-collapse:collapse;width:100%}td,th{border:1px solid #ccc;padding:4px 8px;vertical-align:top}th{background:#f2f2f2}img{max-width:100%}</style>',
         '<h1>Проверка реалистичности: Россия, Беларусь, Украина (0.64)</h1>', '<p>Прогонов: <b>%d</b>. Итог: ✅ %d, ⚠️ %d, ❌ %d.</p>' % ((n_runs,) + tuple(cnt)),
         ''.join('<p>%s</p>' % html.escape(x) if not x.startswith('#') else '<h2>%s</h2>' % html.escape(x.lstrip('# ')) for x in extra.split('\n') if x.strip()),
         '<table><tr><th>Страна</th><th>Сценарий</th><th>Проверка</th><th>Как в жизни</th><th>Получилось</th><th></th></tr>']
    for c in sorted(checks, key=lambda c: (-c.sev, c.cc, c.scn)):
        h.append('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>' % tuple(html.escape(x) for x in (NAMES[c.cc], SCN.get(c.scn, c.scn), c.name, c.expect, c.got, ICON[c.sev])))
    h.append('</table><h2>Графики</h2>')
    for p, t in graphs:
        h.append('<h3>%s</h3><img src="data:image/png;base64,%s">' % (html.escape(t), base64.b64encode(open(p, 'rb').read()).decode()))
    open(os.path.join(a.out, 'report.html'), 'w', encoding='utf8').write('\n'.join(h))
    # короткий список
    bad = [c for c in checks if c.sev == 2]
    warn = [c for c in checks if c.sev == 1]
    sh = ['# Короткий список: что не так в реалистичности (0.64)', '']
    extra_short = open(a.extra_short, encoding='utf8').read().strip() if a.extra_short else ''
    if extra_short:
        sh += [extra_short, '']
    sh += ['Красные (%d):' % len(bad)]
    sh += ['- %s / %s: %s — ожидалось %s, получилось %s' % (NAMES[c.cc], SCN.get(c.scn, c.scn), c.name, c.expect, c.got) for c in bad]
    sh += ['', 'Жёлтые (%d):' % len(warn)]
    sh += ['- %s / %s: %s — ожидалось %s, получилось %s' % (NAMES[c.cc], SCN.get(c.scn, c.scn), c.name, c.expect, c.got) for c in warn]
    open(os.path.join(a.out, 'short.md'), 'w', encoding='utf8').write('\n'.join(sh) + '\n')
    print('проверок %d: зелёных %d, жёлтых %d, красных %d; прогонов %d' % (len(checks), cnt[0], cnt[1], cnt[2], n_runs))


if __name__ == '__main__':
    main()
