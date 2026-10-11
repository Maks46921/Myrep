#!/usr/bin/env python3
"""v49: непризнанные образования на карте — Приднестровье (PMR), ДНР (DNR), ЛНР (LNR).
Не играбельны (нет в COUNTRY_CODES и CDATA), но есть в WORLD (мировая симуляция, карта, справка) с полями
unrec=True, patron (кто контролирует/поддерживает), claim (чьей территорией признаны международно).
Записывает data/world.dat (WORLD), WORLD_CAPS и WORLD_CCOL в scripts/data/data_core.gd. Идемпотентно."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "newc"))
import datio, gdconst

DC = "scripts/data/data_core.gd"


def project(lat, lon):
    return [round(25.7085 * lon + 154.29, 1), round(-38.6135 * lat + 2192.0, 1)]


ENT = {
    "PMR": dict(name="Приднестровье", short="ПМР", cap="Тирасполь", latlon=(46.84, 29.63), pop=0.36, gdp=1.1, debt=0.4, growth=-4.0, infl=9.0,
                unemp=4.0, deficit=6.0, stab=50.0, appr=55.0, leader="Вадим Красносельский", gov="президент В. Красносельский (партия «Обновление»)",
                patron="RU", claim="MD", ccol=(0.60, 0.34, 0.30), pc=0.45, dev=40.0,
                desc="Непризнанная Приднестровская Молдавская Республика на левом берегу Днестра (с 1992 г. — после войны с Молдовой). "
                     "Международно признана частью Молдовы. Под охраной российской Оперативной группы войск; живёт на льготном газе и торговле с ЕС "
                     "через Молдову. С января 2025 г., после остановки транзита газа через Украину, — тяжёлый энергетический кризис."),
    "DNR": dict(name="ДНР", short="ДНР", cap="Донецк", latlon=(48.02, 37.80), pop=2.0, gdp=4.5, debt=0.0, growth=0.0, infl=8.0,
                unemp=8.0, deficit=15.0, stab=35.0, appr=45.0, leader="Денис Пушилин", gov="глава Д. Пушилин («Единая Россия»)",
                patron="RU", claim="UA", ccol=(0.52, 0.30, 0.34), pc=0.35, dev=30.0,
                desc="Непризнанная «Донецкая Народная Республика» на занятой Россией части Донецкой области Украины. С 2014 г. — под контролем "
                     "пророссийских сил, в 2022 г. Россия объявила её своим субъектом (присоединение не признано почти никем). "
                     "Международно признана территорией Украины. Линия фронта на карте — приблизительная, на конец 2025 г."),
    "LNR": dict(name="ЛНР", short="ЛНР", cap="Луганск", latlon=(48.57, 39.33), pop=1.4, gdp=2.5, debt=0.0, growth=0.0, infl=8.0,
                unemp=8.0, deficit=15.0, stab=40.0, appr=45.0, leader="Леонид Пасечник", gov="глава Л. Пасечник («Единая Россия»)",
                patron="RU", claim="UA", ccol=(0.48, 0.32, 0.40), pc=0.32, dev=28.0,
                desc="Непризнанная «Луганская Народная Республика»: почти вся Луганская область Украины, занятая Россией. С 2014 г. — под "
                     "контролем пророссийских сил, в 2022 г. Россия объявила её своим субъектом (не признано). Международно признана территорией Украины."),
}


def main():
    wp = "data/world.dat"
    W = datio.loadn(wp)
    caps = gdconst.get(DC, "WORLD_CAPS")
    ccol = gdconst.get(DC, "WORLD_CCOL")
    for code, e in ENT.items():
        rid = "%s-%s" % (code, code)
        reg = {"id": rid, "code": code, "name": e["name"], "short": e["short"], "popm": e["pop"], "pc": e["pc"], "dev": e["dev"],
               "unrest": 45.0, "auto": 100.0, "infra": 35.0, "edu": 55.0, "health": 40.0, "env": 40.0, "loy": 60.0, "desc": e["desc"],
               "sh": [0.7, 0.1, 0.05, 0.05, 0.05, 0.05, 0.0, 0.0, 0.0, 0.0]}
        W[code] = {"name": e["name"], "short": e["short"], "cap": e["cap"], "pop": e["pop"], "gdp": e["gdp"], "debt": e["debt"], "growth": e["growth"],
                   "infl": e["infl"], "unemp": e["unemp"], "def": e["deficit"], "stab": e["stab"], "appr": e["appr"], "gov": e["gov"],
                   "gov_party": e["gov"], "pot": 1.0, "ecb_w": 0.0, "stance": {"eu": -0.8, "aus": 0.6, "trd": 0.2, "brd": 0.6, "nuk": 0.0},
                   "desc": e["desc"], "leader": e["leader"], "pn": ["Власть", "Др.", "", "", "", "", "", "", "", ""], "seats": [1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                   "regions": [reg], "eu": False, "euro": False, "unrec": True, "patron": e["patron"], "claim": e["claim"]}
        x, y = project(*e["latlon"])
        caps[code] = {"__v": [x, y]}
        ccol[code] = {"__c": [e["ccol"][0], e["ccol"][1], e["ccol"][2], 1.0]}
    datio.dump(wp, W)
    gdconst.put(DC, "WORLD_CAPS", caps)
    gdconst.put(DC, "WORLD_CCOL", ccol)
    print("образования:", ", ".join(ENT))


if __name__ == "__main__":
    main()
