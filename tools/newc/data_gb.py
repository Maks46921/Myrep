# -*- coding: utf-8 -*-
"""Великобритания (GB) — начало игры: январь 2026. Партия игрока: Лейбористская (Кир Стармер), 403 места из 650."""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import gb_base as B
import gb_laws as L
import gb_events as EV

_bias, _T, _loy = B.calibrate()
_bias = [[round(x, 3) for x in r] for r in _bias]


def _col(c):
    return {"__c": [c[0], c[1], c[2], 1]}


MINISTRIES = [{"name": n, "desc": B.MIN_BASE[i][0], "base": B.MIN_BASE[i][1]} for i, n in enumerate(B.MINISTRY_NAMES)]
PARTY_TRAITS = [dict(B.TRAITS[k]) for k in B.TRAIT_OF]
PARTY_LAW_DEMAND = [{}, {"tid": "human_rights", "idx": 2}, {"tid": "eu_policy", "idx": 1}, {"tid": "energy_policy", "idx": 2}, {"tid": "welfare_reform", "idx": 1},
                    {"tid": "state_structure", "idx": 3}, {}, {"tid": "state_structure", "idx": 1}, {"tid": "northern_ireland", "idx": 1}, {}]

MACRO = dict(B.MACRO)

D = {
    "PARTY_NAMES": B.PARTY_NAMES, "PARCH": B.PARCH, "PARTY_DESC": B.PARTY_DESC, "PARTY_COLORS": [_col(c) for c in B.PARTY_COLORS],
    "LEAN": B.LEAN, "HEMI_ORDER": B.HEMI_ORDER, "PARTY_LEADERS": B.PARTY_LEADERS, "PARTY_DEMANDS": B.party_demands(),
    "MINISTRIES": MINISTRIES, "PARTY_MINISTRIES": B.PARTY_MINISTRIES, "MIN_SPECIAL": B.MIN_SPECIAL, "PARTY_TRAITS": PARTY_TRAITS,
    "PARTY_LAW_DEMAND": PARTY_LAW_DEMAND, "MINISTER_NAMES": B.MINISTER_NAMES, "GOV_NAMES": B.GOV_NAMES,
    "REGIONS": B.regions_D(_loy), "REG_BIAS": _bias, "GROUP_WEIGHT": B.GROUP_WEIGHT, "GROUP_BASE": B.GROUP_BASE, "POLICY": B.POLICY,
    "MARKETS_OVR": B.MARKETS_OVR, "GOODS_OVR": B.GOODS_OVR,
    "DE_START_SEATS": B.SEATS_START, "DE_START_MIN": B.MIN_START, "DE_JOIN_ADJ": B.JOIN_ADJ, "SEATS": sum(B.SEATS_START),
    "REGIONAL_P": B.REGIONAL_P, "GDP0": B.GDP, "G_POT": B.G_POT, "G_NEU": B.G_NEU, "I_NEU": B.I_NEU, "I_TGT": B.I_TGT, "U_NEU": B.U_NEU,
    "RATE0": B.RATE0, "OTHER0": B.OTHER0, "UPPER": B.UPPER, "MACRO": MACRO, "TERMS": B.TERMS, "INFO": B.INFO, "COALITION0": [0], "ARCHS": B.ARCHS,
    "DE_TOPICS": L.TOPICS, "DE_PARAM": B.DE_PARAM, "DE_NEW_PARAMS": [], "DE_REMOVE": B.DE_REMOVE, "DE_FUND_ADD": list(L.FUND),
    "LAW_TAGS": {tid: {int(k): list(v) for k, v in vs.items()} for tid, vs in L.TAGS.items()},
    "EVENTS_C": EV.EVENTS_C, "NEWS_C": EV.NEWS_C, "EVENTS_SPECIAL": [],
}

E = [list(r) for r in B.E]

REG_EVENTS = EV.REG_EVENTS
ELEC = {"sys": "Мажоритарная система «первый получает всё» по 650 одномандатным округам", "turn": 0.60,
        "note": "Палата общин избирается на пять лет (последние выборы — 4 июля 2024 года), досрочный роспуск требует двух третей голосов или вотума недоверия. Палата лордов не избирается. Король — глава государства и не участвует в политике.",
        "head": "monarch"}
RAD_CUR = "Парламентская конституционная монархия"
MONARCHY = True

WORLD = {
    "name": "Великобритания", "cap": "Лондон", "latlon": [51.51, -0.13], "pop": 69.3, "gdp": 3400.0, "debt": 3300.0, "growth": 1.0, "infl": 3.4, "unemp": 5.1, "def": 4.5,
    "stab": 55, "appr": 22, "gov": "правительство Стармера: Лейбористская партия (большинство 403 места)", "gov_party": "Лейбористская партия", "pot": 1.3, "ecb_w": 0.0,
    "stance": {"eu": 0.3, "aus": 0.2, "trd": 0.6, "brd": -0.2, "nuk": 0.6},
    "desc": "Вторая по величине экономика Европы вне ЕС: Сити, фармацевтика, оборонная промышленность и университеты. После Брексита страна ищет «перезагрузку» отношений с Брюсселем, одновременно оставаясь ядерной державой и опорой НАТО в Европе. Внутри страны остры споры о миграции, NHS и росте Reform UK.",
    "leader": "Премьер-министр Великобритании", "pn": ["Lab", "Con", "LD", "Green", "Your Party", "SNP", "Др.", "Plaid", "NI", "Reform"],
    "eu": False, "euro": False,
    "likes": "бюджетная дисциплина, свободная торговля, поддержка Украины, надёжность в НАТО, договорённости с ЕС",
    "dislikes": "торговые барьеры, односторонние решения по миграции, нарушение договорённостей по Северной Ирландии",
    "open": 0.4, "stance0": 0.1, "ccol": [0.52, 0.46, 0.62, 1.0],
    "rel": {"DE": 72, "FR": 60, "NL": 75, "BE": 70, "LU": 70, "CH": 72, "AT": 66, "PL": 78, "CZ": 70, "DK": 80, "NO": 86, "SE": 80, "IT": 68, "ES": 66, "PT": 82, "IE": 66},
    "trade_x": {"DE": 65.0, "FR": 45.0, "NL": 50.0, "BE": 22.0, "LU": 4.0, "CH": 20.0, "AT": 6.0, "PL": 10.0, "CZ": 4.0, "DK": 8.0, "NO": 10.0, "SE": 12.0, "IT": 24.0, "ES": 24.0, "PT": 5.0, "IE": 50.0},
    "trade_m": {"DE": 85.0, "FR": 45.0, "NL": 70.0, "BE": 38.0, "LU": 3.0, "CH": 25.0, "AT": 6.0, "PL": 22.0, "CZ": 7.0, "DK": 10.0, "NO": 35.0, "SE": 12.0, "IT": 35.0, "ES": 32.0, "PT": 7.0, "IE": 36.0},
}
