#!/usr/bin/env python3
"""v49: заготовки Молдовы, Беларуси, Украины и России (структура — у готовой страны, список регионов обрезается до нужного числа,
торговля — грубая гравитационная оценка). Заготовка пишется, только если настоящего пакета data_<cc>.py ещё нет (или он тоже заготовка).
Авторы стран заменяют всё настоящими данными (docs/NEWC_SPEC.md)."""
import sys, os, json, math
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.join(HERE, "..", "..")
sys.path.insert(0, os.path.join(HERE, ".."))
import datio
R = lambda *a: list(a)
NEW = {
 "MD": ("CH", [("CHI", "Кишинёв", "Кишинёв", 0.66), ("BAL", "Бельцкий регион", "Бельцы", 0.33), ("NOR", "Север", "Север", 0.42),
               ("CEN", "Центр", "Центр", 0.62), ("SUD", "Юг", "Юг", 0.27), ("GAG", "АТО Гагаузия", "Гагаузия", 0.13)],
        dict(name="Молдова", cap="Кишинёв", latlon=(47.01, 28.86), pop=2.43, gdp=18.0, eu=False, euro=False, ccol=(0.55, 0.45, 0.70, 1.0))),
 "BY": ("PT", [("MSK", "Минск", "Минск", 2.0), ("MIO", "Минская область", "Минская обл.", 1.47), ("BRE", "Брестская область", "Брест", 1.31),
               ("GRO", "Гродненская область", "Гродно", 1.0), ("GOM", "Гомельская область", "Гомель", 1.36), ("MOG", "Могилёвская область", "Могилёв", 0.98),
               ("VIT", "Витебская область", "Витебск", 1.1)],
        dict(name="Беларусь", cap="Минск", latlon=(53.90, 27.56), pop=9.2, gdp=72.0, eu=False, euro=False, ccol=(0.45, 0.62, 0.42, 1.0))),
 "UA": ("FR", [("KYI", "Киев", "Киев", 2.9), ("NOR", "Север (Киевщина, Житомирщина, Черниговщина)", "Север", 3.4), ("LVI", "Львовская область", "Львов", 2.4),
               ("ZAH", "Прикарпатье и Закарпатье", "Карпаты", 3.6), ("VOL", "Волынь", "Волынь", 1.9), ("POD", "Подолье", "Подолье", 2.6),
               ("CEN", "Центр (Черкассы, Кропивницкий, Полтава)", "Центр", 3.2), ("KHA", "Слобожанщина (Харьков, Сумы)", "Харьков", 3.1),
               ("DNI", "Днепропетровская область", "Днепр", 3.0), ("ZAP", "Запорожская область", "Запорожье", 1.0), ("ODE", "Одесская область", "Одесса", 2.2),
               ("MYK", "Юг (Николаев, Херсон)", "Юг", 1.3), ("DON", "Донбасс (подконтрольная часть)", "Донбасс", 0.6)],
        dict(name="Украина", cap="Киев", latlon=(50.45, 30.52), pop=31.2, gdp=180.0, eu=False, euro=False, ccol=(0.86, 0.74, 0.30, 1.0))),
 "RU": ("ES", [("MOW", "Москва", "Москва", 13.1), ("MOS", "Московская область", "Подмосковье", 8.6), ("SPB", "Санкт-Петербург", "Петербург", 5.6),
               ("CEN", "Центральная Россия", "Центр", 17.3), ("SZA", "Северо-Запад", "Северо-Запад", 7.9), ("KGD", "Калининградская область", "Калининград", 1.0),
               ("YUG", "Юг России", "Юг", 14.5), ("KAV", "Северный Кавказ", "Кавказ", 10.2), ("KRY", "Крым и Севастополь", "Крым", 2.4),
               ("VOL", "Поволжье и Приуралье", "Поволжье", 21.5), ("TAB", "Татарстан и Башкортостан", "Татарстан", 7.9), ("URA", "Урал", "Урал", 12.3),
               ("SIB", "Сибирь", "Сибирь", 16.6), ("DVO", "Дальний Восток", "Дальний Восток", 7.8)],
        dict(name="Россия", cap="Москва", latlon=(55.75, 37.62), pop=146.0, gdp=2000.0, eu=False, euro=False, ccol=(0.70, 0.38, 0.36, 1.0))),
}


def main():
    W = datio.loadn(os.path.join(ROOT, "data", "world.dat"))
    allc = [c for c in W.keys() if c in datio.loadn(os.path.join(ROOT, "data", "world.dat"))] + [c for c in NEW if c not in W]
    for cc, (tmpl, regs, base) in NEW.items():
        path = os.path.join(HERE, "data_%s.py" % cc.lower())
        if os.path.exists(path) and "ЗАГОТОВКА" not in open(path, encoding="utf-8").read(200):
            print(cc, ": настоящий пакет уже есть — пропуск")
            continue
        d = datio.loadn(os.path.join(ROOT, "data", "countries", "%s.dat" % tmpl))
        TW = W[tmpl]
        for k in ("DIP_ORDER", "DIP_C", "DIP_LIKES"):
            d.pop(k)
        n = len(regs)
        assert len(d["REGIONS"]) >= n, (cc, tmpl)
        d["REGIONS"] = d["REGIONS"][:n]
        d["REG_BIAS"] = d["REG_BIAS"][:n]
        E = []
        for i, (code, name, short, popm) in enumerate(regs):
            r = d["REGIONS"][i]
            r["code"], r["name"], r["short"], r["popm"] = code, name, short, popm
            E.append(list(TW["regions"][i]["sh"]))
        d["INFO"]["pop"] = round(sum(x[3] for x in regs), 2)
        os.makedirs(os.path.join(HERE, "ph"), exist_ok=True)
        datio.dump(os.path.join(HERE, "ph", "%s_D.dat" % cc.lower()), d)
        json.dump(E, open(os.path.join(HERE, "ph", "%s_E.json" % cc.lower()), "w"))
        g = base["gdp"]
        tx, tm, rel = {}, {}, {}
        for o in allc:
            if o == cc:
                continue
            go = W[o]["gdp"] if o in W else NEW[o][2]["gdp"]
            v = round(0.08 * math.sqrt(g * go) * 0.3, 1)
            tx[o] = v; tm[o] = v; rel[o] = 50
        world = {"name": base["name"], "cap": base["cap"], "latlon": base["latlon"], "pop": base["pop"], "gdp": g, "debt": g * 0.4, "growth": 1.5, "infl": 4.0,
                 "unemp": 5.0, "def": 3.0, "stab": 55, "appr": 45, "gov": "заготовка", "gov_party": "заготовка", "pot": 1.5, "ecb_w": 0.0,
                 "stance": {"eu": 0.0, "aus": 0.2, "trd": 0.5, "brd": 0.2, "nuk": 0.0}, "desc": "Заготовка", "leader": "Президент",
                 "pn": ["П1", "П2", "П3", "П4", "П5", "П6", "Др.", "П8", "П9", "П10"], "eu": base["eu"], "euro": base["euro"], "likes": "заготовка", "dislikes": "заготовка",
                 "open": 0.6, "stance0": 0.0, "ccol": base["ccol"], "rel": rel, "trade_x": tx, "trade_m": tm}
        src = '''# ЗАГОТОВКА %s — заменить настоящими данными (docs/NEWC_SPEC.md)
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
D = datio.loadn(os.path.join(HERE, "ph", "%s_D.dat"))
E = json.load(open(os.path.join(HERE, "ph", "%s_E.json")))
WORLD = %s
REG_EVENTS = []
ELEC = {"sys": "Заготовка", "turn": 0.6, "note": "", "head": "direct", "title": "Президент", "title_n": "президента", "term": 5, "first": [2028, 10]}
RAD_CUR = "Президентская республика"
MONARCHY = False
''' % (cc, cc.lower(), cc.lower(), repr(world))
        open(path, "w", encoding="utf-8").write(src)
        print(cc, ": заготовка создана из", tmpl)


main()
