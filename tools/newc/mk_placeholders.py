#!/usr/bin/env python3
"""Создаёт «заготовки» data_gb.py / data_ie.py: структура взята у NL (12 регионов) и NO (8 регионов), коды регионов — Великобритании и Ирландии.
Автор страны заменяет содержимое настоящими данными (см. docs/NEWC_SPEC.md)."""
import sys, os, json
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.join(HERE, "..", "..")
sys.path.insert(0, os.path.join(HERE, ".."))
import datio
GBR = ["SCO", "WAL", "NIR", "NEE", "NWE", "YOR", "EMI", "WMI", "EOE", "LON", "SEE", "SWE"]
IER = ["BOR", "WES", "MLD", "MWE", "MEA", "DUB", "SEA", "SWT"]
def mk(cc, tmpl, codes, world):
    d = datio.loadn(os.path.join(ROOT, "data", "countries", "%s.dat" % tmpl))
    W = datio.loadn(os.path.join(ROOT, "data", "world.dat"))[tmpl]
    for k in ("DIP_ORDER", "DIP_C", "DIP_LIKES"): d.pop(k)
    E = []
    for i, r in enumerate(d["REGIONS"]):
        r["code"] = codes[i]
        E.append(list(W["regions"][i]["sh"]))
    os.makedirs(os.path.join(HERE, "ph"), exist_ok=True)
    datio.dump(os.path.join(HERE, "ph", "%s_D.dat" % cc.lower()), d)
    json.dump(E, open(os.path.join(HERE, "ph", "%s_E.json" % cc.lower()), "w"))
    src = '''# ЗАГОТОВКА %s — заменить настоящими данными (docs/NEWC_SPEC.md)
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
D = datio.loadn(os.path.join(HERE, "ph", "%s_D.dat"))
E = json.load(open(os.path.join(HERE, "ph", "%s_E.json")))
WORLD = %s
REG_EVENTS = []
ELEC = {"sys": "Заготовка", "turn": 0.65, "note": "", "head": "monarch"}
RAD_CUR = "Заготовка"
MONARCHY = %s
''' % (cc, cc.lower(), cc.lower(), repr(world), "True" if cc == "GB" else "False")
    open(os.path.join(HERE, "data_%s.py" % cc.lower()), "w", encoding="utf-8").write(src)
GBW = {"name": "Великобритания", "cap": "Лондон", "latlon": (51.51, -0.13), "pop": 69.3, "gdp": 3400.0, "debt": 3300.0, "growth": 1.0, "infl": 3.4, "unemp": 5.0, "def": 4.5, "stab": 55, "appr": 22,
       "gov": "правительство Стармера: Лейбористская партия", "gov_party": "Лейбористская партия", "pot": 1.3, "ecb_w": 0.0,
       "stance": {"eu": 0.3, "aus": 0.2, "trd": 0.6, "brd": -0.2, "nuk": 0.3},
       "desc": "Заготовка", "leader": "Премьер-министр Великобритании", "pn": ["Lab", "Con", "LD", "Green", "Reform", "SNP", "Др.", "Plaid", "DUP/SF", "Reform"],
       "eu": False, "euro": False, "likes": "заготовка", "dislikes": "заготовка", "open": 0.33, "stance0": 0.1, "ccol": (0.55, 0.48, 0.62, 1.0),
       "rel": {"DE": 70, "FR": 62, "NL": 75, "BE": 70, "LU": 70, "CH": 70, "AT": 65, "PL": 78, "CZ": 70, "DK": 80, "NO": 85, "SE": 80, "IT": 66, "ES": 66, "PT": 82, "IE": 66},
       "trade_x": {"DE": 65.0, "FR": 45.0, "NL": 50.0, "BE": 22.0, "LU": 4.0, "CH": 20.0, "AT": 6.0, "PL": 10.0, "CZ": 4.0, "DK": 8.0, "NO": 10.0, "SE": 12.0, "IT": 24.0, "ES": 24.0, "PT": 5.0, "IE": 50.0},
       "trade_m": {"DE": 85.0, "FR": 45.0, "NL": 70.0, "BE": 38.0, "LU": 3.0, "CH": 25.0, "AT": 6.0, "PL": 22.0, "CZ": 7.0, "DK": 10.0, "NO": 35.0, "SE": 12.0, "IT": 35.0, "ES": 32.0, "PT": 7.0, "IE": 36.0}}
IEW = {"name": "Ирландия", "cap": "Дублин", "latlon": (53.35, -6.26), "pop": 5.4, "gdp": 540.0, "debt": 220.0, "growth": 2.5, "infl": 2.0, "unemp": 4.6, "def": -2.0, "stab": 80, "appr": 38,
       "gov": "правительство Мартина: Фианна Фойл, Фине Гэл и независимые", "gov_party": "Фианна Фойл", "pot": 3.0, "ecb_w": 0.03,
       "stance": {"eu": 0.8, "aus": 0.2, "trd": 0.8, "brd": 0.3, "nuk": -0.4},
       "desc": "Заготовка", "leader": "Таосич — премьер-министр Ирландии", "pn": ["FF", "FG", "SF", "SD", "Lab", "Aontú", "Др.", "PBP", "Нез.", "Aontú"],
       "eu": True, "euro": True, "likes": "заготовка", "dislikes": "заготовка", "open": 0.85, "stance0": 0.05, "ccol": (0.35, 0.60, 0.45, 1.0),
       "rel": {"DE": 72, "FR": 78, "NL": 80, "BE": 80, "LU": 78, "CH": 68, "AT": 70, "PL": 70, "CZ": 68, "DK": 80, "NO": 75, "SE": 78, "IT": 72, "ES": 74, "PT": 78, "GB": 66},
       "trade_x": {"DE": 18.0, "FR": 10.0, "NL": 12.0, "BE": 22.0, "LU": 1.0, "CH": 8.0, "AT": 2.0, "PL": 3.0, "CZ": 1.2, "DK": 2.5, "NO": 1.0, "SE": 3.0, "IT": 7.0, "ES": 5.0, "PT": 1.0, "GB": 36.0},
       "trade_m": {"DE": 14.0, "FR": 8.0, "NL": 12.0, "BE": 8.0, "LU": 0.5, "CH": 4.0, "AT": 1.5, "PL": 3.0, "CZ": 1.0, "DK": 2.0, "NO": 3.0, "SE": 2.0, "IT": 4.5, "ES": 4.0, "PT": 1.0, "GB": 50.0}}
mk("GB", "NL", GBR, GBW)
mk("IE", "NO", IER, IEW)
print("заготовки созданы")
