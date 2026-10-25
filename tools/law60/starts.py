# Действующий порядок в 38 странах для новых тем: стартовый вариант (индекс) и значение ползунка.
EU = "DE FR NL BE LU AT CZ DK ES IT PL PT SE IE SI SK HU FI HR BG RO GR EE LV LT".split()

START_IDX = {}   # tid -> {cc: idx}


def S(tid, idx, ccs):
    d = START_IDX.setdefault(tid, {})
    for c in ccs.split() if isinstance(ccs, str) else ccs:
        d[c] = idx


S("death_penalty", 2, "BY")
S("death_penalty", 1, "RU")
S("gun_law", 3, "CH")
S("drugs_law", 1, "PT CZ ES IT")
S("drugs_law", 2, "DE LU NL")
S("drugs_law", 3, "RU BY")
S("same_sex", 2, "AT BE DK FI FR DE IE LU NL NO PT ES SE CH GB SI EE GR")
S("same_sex", 1, "CZ IT HR LV ME")
S("same_sex", 3, "HU SK BG BY RU")
S("abortion_law", 2, "PL")
S("euthanasia", 2, "NL BE LU ES CH AT DE")
S("compulsory_vote", 2, "BE LU")
S("e_voting", 1, "EE RU")
S("foreign_agents", 2, "RU BY")
S("foreign_agents", 1, "HU")
S("net_censor", 3, "RU BY")
S("net_censor", 2, "DE FR")
S("data_protection", 1, EU + ["NO", "CH", "GB"])
S("data_protection", 2, "RU BY")
S("ai_reg", 1, EU)
S("sov_fund", 1, "NO RU")
S("strike_law", 1, "FR")
S("strike_law", 2, "RU")
S("strike_law", 3, "BY")
S("unions", 1, "FR AT NL BE")
S("unions", 2, "DE")
S("nuclear_power", 3, "DE ES CH")
S("nuclear_power", 2, "BE UA")
S("nuclear_power", 1, "FR FI SE PL CZ HU SK SI RO BG NL GB RU")

# ползунки: действующее значение по странам (иначе значение по умолчанию из темы)
PARAM_REF = {
    "vote_age": {"AT": 16, "GR": 17},
    "crim_age": {"GB": 10, "CH": 10, "IE": 12, "NL": 12, "FR": 13, "GR": 15, "PL": 15, "CZ": 15, "DK": 15, "SE": 15, "NO": 15, "FI": 15,
                 "LU": 18, "PT": 16, "BE": 18, "BY": 14, "HU": 14},
    "wealth_tax": {"NO": 1.0, "ES": 1.0, "CH": 0.5},
    "work_hours": {"FR": 35, "DE": 38, "NL": 38, "BE": 38, "AT": 38, "NO": 37, "DK": 37, "FI": 37, "IE": 39, "CH": 42},
    "quota": {"FR": 50, "ES": 40, "BE": 50, "PT": 40, "PL": 35, "SI": 35, "HR": 40, "ME": 30, "RS": 40, "BA": 40, "MK": 40, "AL": 30,
              "XK": 30, "IE": 30, "GR": 40, "IT": 40, "MD": 40, "UA": 40},
    "parental_leave": {"DE": 14, "SE": 16, "NO": 12, "FI": 7, "DK": 12, "EE": 18, "LT": 12, "LV": 12, "PL": 12, "CZ": 36, "SK": 36, "HU": 36,
                       "BG": 24, "RO": 24, "HR": 12, "SI": 12, "AT": 24, "NL": 6, "BE": 4, "LU": 12, "FR": 6, "ES": 4, "PT": 5, "IT": 5,
                       "GR": 9, "IE": 7, "GB": 9, "CH": 4, "RU": 18, "BY": 36, "UA": 36, "MD": 24, "RS": 12, "BA": 12, "ME": 12,
                       "MK": 9, "AL": 12, "XK": 9},
}

# где у страны уже есть своя тема с тем же смыслом — новая общая тема в этой стране убирается
REMOVE = {}


def R(ids, ccs):
    for c in ccs.split():
        REMOVE.setdefault(c, [])
        for i in ids.split():
            if i not in REMOVE[c]:
                REMOVE[c].append(i)


R("drugs_law", "AL CH CZ IT LU NL SE SI")
R("public_media", "AT CZ DK FI IE IT LV PL")
R("same_sex", "BA EE LT LV PL RO UA")
R("state_language", "BE BY CH EE ES FI IE LU MD ME MK XK UA NO SK")
R("asylum_law", "AT CH FI GB IE LT NL NO")
R("forest_hunt", "EE FI LT LV PT")
R("euthanasia", "FR GB SI")
R("visa_policy", "GB PT")
R("ai_reg", "GB")
R("abortion_law", "HR HU")
R("nuclear_power", "PL RO SI BG HU")
R("capital_gains", "SE")
R("surveillance", "SE")
