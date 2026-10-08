#!/usr/bin/env python3
"""Генерирует data/soc.dat: религии (REL), миграция (MIG), внешняя зависимость (EXD) по странам.
Религия: [католики, протестанты, православные, мусульмане, иудеи, восточные религии, нерелигиозные], доли в %, данные ориентировочные (2020-е).
Регионы без переопределения получают национальную структуру. Переопределение — словарь вера->доля %, остаток распределяется пропорционально."""
import json, os
F = ["cath", "prot", "orth", "musl", "jew", "east", "none"]
def v(c=0, p=0, o=0, m=0, j=0, e=0, n=0):
    return [c, p, o, m, j, e, n]
BASE = {
 "DE": v(24, 21, 2, 6.5, .2, 1.5, 44.8), "FR": v(47, 3, 1, 9, .7, 1, 38.3), "NL": v(19, 15, .5, 5, .1, 1.5, 58.9),
 "BE": v(52, 1, .5, 7, .3, .5, 38.7), "LU": v(66, 3, 3, 3, .2, .5, 24.3), "AT": v(56, 3.5, 7, 8, .1, 1, 24.4),
 "CH": v(34, 22, 2.5, 5.5, .3, 1, 34.7), "CZ": v(12, 2, 1, .2, 0, .5, 84.3), "DK": v(.7, 70, .3, 5.5, .1, .8, 22.6),
 "ES": v(62, 1.5, 1, 3.5, .1, 1, 30.9), "IT": v(74, 1.2, 3, 4, .1, 1, 16.7), "NO": v(3, 62, .5, 4, .1, 1.5, 28.9),
 "PL": v(85, .4, 1, .1, 0, .2, 13.3), "PT": v(80, 3, 1, .5, .1, .5, 14.9), "SE": v(1.5, 55, 2.5, 8, .1, 1.5, 31.4),
 "GB": v(9, 35.5, 1, 6.5, .5, 3.2, 44.3), "IE": v(69, 4.5, 1.8, 1.6, .1, 1.0, 22),
 "SI": v(55, 1, 2.5, 3.5, 0, .2, 37.8), "SK": v(60, 7, 1, 0.2, 0.05, 0.3, 31.45), "HU": v(42, 13, 0.3, 0.2, 0.1, 0.3, 44.1), "FI": v(0.3, 62, 1.1, 2.0, 0.03, 0.5, 34.07),
}
# переопределения по регионам (код региона из REGIONS)
OVR = {
 "DE": {"BY": {"cath": 48, "prot": 19, "musl": 5, "none": 25}, "BW": {"cath": 35, "prot": 28, "musl": 8, "none": 26}, "NW": {"cath": 40, "prot": 24, "musl": 9, "none": 24},
        "RP": {"cath": 46, "prot": 28, "musl": 5, "none": 20}, "SL": {"cath": 60, "prot": 17, "musl": 3, "none": 19}, "NI": {"cath": 17, "prot": 45, "musl": 4, "none": 32},
        "SH": {"cath": 6, "prot": 50, "musl": 3, "none": 40}, "HE": {"cath": 23, "prot": 37, "musl": 8, "none": 30}, "HH": {"cath": 10, "prot": 27, "musl": 9, "none": 52},
        "HB": {"cath": 10, "prot": 36, "musl": 9, "none": 44}, "BE": {"cath": 9, "prot": 14, "musl": 9, "none": 64}, "SN": {"cath": 3.5, "prot": 20, "musl": 1.5, "none": 74},
        "ST": {"cath": 3, "prot": 14, "musl": 1.5, "none": 80}, "TH": {"cath": 8, "prot": 24, "musl": 1.5, "none": 65}, "BB": {"cath": 3, "prot": 16, "musl": 2, "none": 78},
        "MV": {"cath": 3, "prot": 16, "musl": 1.5, "none": 79}},
 "FR": {"IDF": {"cath": 38, "musl": 15, "jew": 2.5, "none": 38}, "ARA": {"cath": 50, "musl": 8, "none": 37}, "PAC": {"cath": 45, "musl": 12, "jew": 1.5, "none": 38},
        "COR": {"cath": 80, "musl": 3, "none": 15}, "BRE": {"cath": 55, "musl": 3, "none": 40}, "GES": {"cath": 38, "prot": 6, "musl": 8, "none": 44},
        "HDF": {"cath": 45, "musl": 8, "none": 44}, "OCC": {"cath": 48, "musl": 8, "none": 40}, "NAQ": {"cath": 46, "prot": 4, "musl": 5, "none": 43}},
 "NL": {"NB": {"cath": 60, "prot": 5, "musl": 4, "none": 30}, "LI": {"cath": 62, "prot": 4, "musl": 4, "none": 29}, "ZH": {"cath": 12, "prot": 17, "musl": 8, "none": 61},
        "NH": {"cath": 14, "prot": 8, "musl": 8, "none": 68}, "GE": {"cath": 14, "prot": 26, "musl": 5, "none": 54}, "OV": {"cath": 17, "prot": 29, "musl": 4, "none": 49},
        "ZE": {"cath": 8, "prot": 44, "musl": 3, "none": 44}, "FR": {"cath": 7, "prot": 25, "musl": 2, "none": 65}, "GR": {"cath": 5, "prot": 18, "musl": 4, "none": 71}},
 "BE": {"BRU": {"cath": 28, "musl": 25, "none": 40, "jew": 1.5, "orth": 2}, "VLI": {"cath": 62, "musl": 5, "none": 31}, "LIE": {"cath": 55, "musl": 9, "none": 33},
        "WVL": {"cath": 66, "musl": 3, "none": 30}, "LUX": {"cath": 62, "musl": 2, "none": 34}, "ANT": {"cath": 46, "musl": 9, "none": 42}},
 "AT": {"WIE": {"cath": 36, "prot": 4, "orth": 12, "musl": 16, "none": 30}, "BGL": {"cath": 74, "prot": 12, "musl": 2, "none": 9}, "TIR": {"cath": 78, "prot": 2, "musl": 5, "none": 13},
        "VBG": {"cath": 66, "prot": 3, "musl": 10, "none": 18}, "KTN": {"cath": 70, "prot": 11, "musl": 3, "none": 14}, "NOE": {"cath": 68, "prot": 3, "musl": 4, "none": 22}},
 "CH": {"TIC": {"cath": 68, "prot": 5, "musl": 4, "none": 21}, "ZUR": {"cath": 24, "prot": 30, "musl": 6, "none": 37}, "ZEN": {"cath": 58, "prot": 11, "musl": 4, "none": 25},
        "LEM": {"cath": 32, "prot": 25, "musl": 5, "none": 36}, "NWS": {"cath": 22, "prot": 31, "musl": 5, "none": 40}, "OST": {"cath": 38, "prot": 24, "musl": 6, "none": 30}},
 "CZ": {"PHA": {"cath": 8, "none": 88, "musl": .3}, "JMO": {"cath": 22, "prot": 3, "none": 72}, "SMO": {"cath": 20, "prot": 3, "none": 74}, "VCH": {"cath": 7, "prot": 1.5, "none": 90},
        "SZC": {"cath": 6, "prot": 1, "none": 91}},
 "DK": {"HOV": {"prot": 63, "musl": 9, "none": 25}, "MID": {"prot": 77, "musl": 3.5, "none": 18}, "NOR": {"prot": 74, "musl": 3.5, "none": 20}},
 "ES": {"CAT": {"cath": 52, "musl": 6, "prot": 2, "none": 38}, "MAD": {"cath": 57, "musl": 5, "none": 34}, "AND": {"cath": 72, "musl": 3, "none": 24}, "GAL": {"cath": 75, "musl": 1, "none": 22},
        "PVN": {"cath": 51, "musl": 2, "none": 45}, "CYL": {"cath": 79, "musl": 2, "none": 18}, "CLM": {"cath": 80, "musl": 2, "none": 17}, "EXT": {"cath": 81, "musl": 1, "none": 17}, "BAL": {"cath": 56, "musl": 5, "none": 34}, "CAN": {"cath": 63, "musl": 3, "none": 31}},
 "IT": {"CAM": {"cath": 86, "musl": 3, "none": 9}, "PUG": {"cath": 86, "musl": 2, "none": 11}, "CAL": {"cath": 88, "musl": 2, "none": 8}, "SIC": {"cath": 84, "musl": 3, "none": 11},
        "SAR": {"cath": 82, "musl": 1, "none": 15}, "EMR": {"cath": 58, "musl": 6, "none": 33}, "TOS": {"cath": 62, "musl": 4, "none": 31}, "LOM": {"cath": 70, "musl": 5, "none": 22},
        "VEN": {"cath": 77, "musl": 5, "none": 16}, "LAZ": {"cath": 74, "musl": 4, "none": 18}},
 "NO": {"OSV": {"prot": 54, "musl": 8, "none": 34}, "AGD": {"prot": 72, "musl": 2, "none": 22}, "ROG": {"prot": 64, "musl": 4, "none": 27}, "VML": {"prot": 60, "musl": 3, "none": 32}},
 "PL": {"PK": {"cath": 94, "none": 5}, "LU": {"cath": 93, "orth": 2, "none": 5}, "PD": {"cath": 80, "orth": 12, "none": 8}, "MA": {"cath": 92, "none": 7}, "WP": {"cath": 85, "none": 13},
        "ZP": {"cath": 75, "none": 20, "orth": 2}, "DS": {"cath": 79, "none": 18}, "MZ": {"cath": 81, "none": 16}, "PM": {"cath": 81, "none": 16}, "LB": {"cath": 76, "none": 20}},
 "PT": {"NOR": {"cath": 87, "prot": 2, "none": 10}, "CEN": {"cath": 87, "none": 11}, "LIS": {"cath": 68, "prot": 4, "musl": 2, "none": 24}, "ALG": {"cath": 66, "none": 28, "musl": 1}},
 "GB": {"SCO": {"cath": 14, "prot": 32, "musl": 1.5, "none": 50}, "WAL": {"cath": 5, "prot": 33, "musl": 2.5, "none": 51}, "NIR": {"cath": 42, "prot": 42, "none": 14}, "LON": {"cath": 10, "prot": 30, "musl": 15, "east": 8, "jew": 1.5, "none": 33}, "WMI": {"musl": 10, "east": 6}, "YOR": {"musl": 7}, "NWE": {"musl": 7}},
 "IE": {"DUB": {"cath": 60, "musl": 2.5, "none": 28}, "BOR": {"cath": 76, "none": 17}, "WES": {"cath": 77, "none": 17}},
 "SE": {"STO": {"prot": 44, "musl": 11, "none": 38}, "SYD": {"prot": 53, "musl": 8, "none": 33}, "VSV": {"prot": 54, "musl": 8, "none": 32}, "NMS": {"prot": 60, "musl": 2, "none": 34}},
 "SI": {'OSR': {'cath': 45, 'orth': 3.5, 'musl': 5, 'none': 45}, 'POM': {'cath': 60, 'prot': 7, 'none': 30}, 'SAV': {'cath': 60, 'musl': 4, 'none': 33}, 'GOR': {'cath': 62, 'musl': 4, 'none': 31}, 'JVS': {'cath': 64, 'orth': 3, 'none': 30}, 'PRI': {'cath': 50, 'none': 44}},
 "SK": {'BA': {'cath': 44, 'prot': 5, 'orth': 1, 'musl': 0.5, 'none': 48}, 'TT': {'cath': 68, 'prot': 5, 'none': 25}, 'TN': {'cath': 66, 'prot': 6, 'none': 26}, 'NR': {'cath': 63, 'prot': 8, 'none': 27}, 'ZA': {'cath': 70, 'prot': 7, 'none': 21}, 'BB': {'cath': 46, 'prot': 13, 'none': 38}, 'PO': {'cath': 77, 'orth': 4, 'prot': 3, 'none': 14}, 'KE': {'cath': 57, 'prot': 9, 'orth': 1.5, 'none': 30}},
 "HU": {'BUD': {'cath': 30, 'prot': 9, 'jew': 0.6, 'musl': 0.5, 'east': 0.6, 'none': 59}, 'EAL': {'cath': 34, 'prot': 24, 'orth': 0.4, 'none': 41}, 'NYD': {'cath': 55, 'prot': 9, 'none': 35}, 'EMO': {'cath': 46, 'prot': 12, 'none': 41}, 'DDT': {'cath': 47, 'prot': 11, 'none': 41}},
 "FI": {'UUS': {'prot': 51, 'orth': 1.0, 'musl': 4.0, 'east': 0.8, 'none': 42.5}, 'POH': {'prot': 79, 'musl': 0.8, 'none': 19}, 'AHV': {'prot': 72, 'musl': 0.5, 'none': 26}, 'LAP': {'prot': 73, 'orth': 0.8, 'musl': 0.6, 'none': 25}, 'PPO': {'prot': 72, 'musl': 0.8, 'none': 26}, 'ISU': {'prot': 67, 'orth': 2.8, 'musl': 0.9, 'none': 29}, 'KAA': {'prot': 64, 'orth': 2.0, 'musl': 1.2, 'none': 32}},
}
ORIGINS = ["ЕС и Западная Европа", "Восточная Европа и Балканы", "Ближний Восток и Северная Африка", "Африка южнее Сахары", "Южная и Восточная Азия", "Америка и прочие"]
OFAITH = [v(.35, .25, .03, .02, .01, .01, .33), v(.25, .03, .45, .12, 0, 0, .15), v(.02, .01, .05, .85, .01, 0, .06), v(.20, .30, .05, .32, 0, .03, .10), v(.02, .03, 0, .30, 0, .50, .15), v(.45, .30, .01, .01, .01, .02, .20)]
OSKILL = [.75, .5, .4, .35, .65, .7]
OINTEG = [.8, .6, .4, .35, .55, .75]
ODIST = [.1, .3, .7, .6, .5, .2]
MIG = {  # in0 — чистая иммиграция на 1000 жителей в год, out0 — эмиграция, mix — доли происхождения
 "DE": (7, 3, [.22, .28, .28, .04, .14, .04]), "FR": (4, 2, [.17, .12, .30, .25, .10, .06]), "NL": (6, 2.5, [.25, .2, .2, .1, .15, .1]),
 "BE": (6, 2.5, [.3, .15, .25, .15, .1, .05]), "LU": (20, 8, [.55, .2, .05, .05, .1, .05]), "AT": (8, 3, [.2, .45, .15, .03, .12, .05]),
 "CH": (10, 4, [.45, .2, .1, .05, .1, .1]), "CZ": (3, 1.5, [.15, .6, .03, .02, .2, 0]), "DK": (5, 2.5, [.25, .25, .2, .05, .15, .1]),
 "ES": (6, 2, [.15, .15, .2, .1, .1, .3]), "IT": (3, 3, [.1, .3, .2, .2, .2, 0]), "NO": (7, 3, [.3, .35, .1, .1, .1, .05]),
 "PL": (2, 3.5, [.05, .85, .02, 0, .05, .03]), "PT": (4, 4, [.2, .1, .1, .2, .1, .3]), "SE": (7, 2.5, [.2, .2, .3, .1, .15, .05]),
 "GB": (9, 4, [.15, .15, .1, .15, .38, .07]), "IE": (12, 5, [.35, .2, .05, .1, .2, .1]),
 "SI": (8, 5, [0.12, 0.75, 0.04, 0.02, 0.05, 0.02]), "SK": (3, 2.5, [0.18, 0.62, 0.02, 0.01, 0.15, 0.02]), "HU": (4, 3.5, [0.12, 0.45, 0.03, 0.02, 0.33, 0.05]), "FI": (9, 3, [0.28, 0.27, 0.12, 0.1, 0.18, 0.05]),
}
EXD = {  # en — доля импортной энергии, fdebt — доля госдолга у иностранцев, exporter — экспортёр энергии
 "DE": (.65, .45, 0), "FR": (.45, .5, 0), "NL": (.5, .5, 0), "BE": (.75, .55, 0), "LU": (.9, .6, 0), "AT": (.6, .6, 0), "CH": (.7, .2, 0), "CZ": (.45, .3, 0),
 "DK": (.3, .4, 0), "ES": (.7, .45, 0), "IT": (.75, .3, 0), "NO": (0, .1, 1), "PL": (.45, .35, 0), "PT": (.75, .5, 0), "SE": (.35, .25, 0),
 "GB": (.35, .3, 0), "IE": (.85, .65, 0),
 "SI": (0.48, 0.55, 0), "SK": (0.6, 0.45, 0), "HU": (0.6, 0.35, 0), "FI": (0.4, 0.55, 0),
}
# v38: новые страны дают свои данные в tools/newc/<cc>_extras.py (SOC_BASE, SOC_OVR, SOC_MIG, SOC_EXD)
import glob, importlib.util
for _f in sorted(glob.glob(os.path.join(os.path.dirname(os.path.abspath(__file__)), "newc", "*_extras.py"))):
    _sp = importlib.util.spec_from_file_location(os.path.basename(_f)[:-3], _f); _m = importlib.util.module_from_spec(_sp); _sp.loader.exec_module(_m)
    _cc = os.path.basename(_f)[:2].upper()
    if hasattr(_m, "SOC_BASE"): BASE[_cc] = list(_m.SOC_BASE)
    if getattr(_m, "SOC_OVR", None): OVR[_cc] = dict(_m.SOC_OVR)
    if hasattr(_m, "SOC_MIG"): MIG[_cc] = tuple(_m.SOC_MIG)
    if hasattr(_m, "SOC_EXD"): EXD[_cc] = tuple(_m.SOC_EXD)
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def norm(a):
    s = sum(a) or 1.0
    return [round(x / s, 5) for x in a]
def region_vec(cc, code):
    b = BASE[cc][:]
    o = OVR.get(cc, {}).get(code)
    if not o:
        return norm(b)
    fixed = {F.index(k): x for k, x in o.items()}
    s_fixed = sum(fixed.values())
    rest = [i for i in range(7) if i not in fixed]
    s_rest = sum(b[i] for i in rest) or 1.0
    out = [0.0] * 7
    for i, x in fixed.items():
        out[i] = x
    left = max(0.0, 100.0 - s_fixed)
    for i in rest:
        out[i] = left * b[i] / s_rest
    return norm(out)
import re
wd = json.loads(open(os.path.join(root, "data", "world.dat"), encoding="utf-8").read().replace("\n", " ")) if False else None
txt = open(os.path.join(root, "data", "world.dat"), encoding="utf-8").read()
codes = {}
pops = {}
for cc in BASE:
    i = txt.index('"%s": {' % cc)
    j = txt.index('"regions"', i)
    k = txt.find('\n\t"', j + 10)
    seg = txt[j:k if k > 0 else j + 80000]
    codes[cc] = re.findall(r'"code":\s*"([A-Z]+)"', seg)
    pops[cc] = {m[0]: float(m[1]) for m in re.findall(r'"code":\s*"([A-Z]+)",.*?"popm":\s*([\d.]+)', seg, re.S)}
D = {"faiths": F, "origins": ORIGINS, "ofaith": [norm(x) for x in OFAITH], "oskill": OSKILL, "ointeg": OINTEG, "odist": ODIST, "country": {}}
def rake(cc):
    # приводим региональные составы к национальному (взвешивание по населению)
    regs = {c: region_vec(cc, c) for c in codes[cc]}
    tgt = norm(BASE[cc])
    for it in range(40):
        tot = sum(pops[cc].get(c, 1.0) for c in regs)
        avg = [sum(regs[c][f] * pops[cc].get(c, 1.0) for c in regs) / tot for f in range(7)]
        for c in regs:
            regs[c] = norm([regs[c][f] * (tgt[f] / avg[f] if avg[f] > 0 else 1.0) for f in range(7)])
    return regs
for cc in BASE:
    in0, out0, mix = MIG[cc]
    en, fd, ex = EXD[cc]
    D["country"][cc] = {"base": norm(BASE[cc]), "reg": rake(cc), "in0": in0, "out0": out0, "mix": norm(mix), "en": en, "fdebt": fd, "exporter": ex}
open(os.path.join(root, "data", "soc.dat"), "w", encoding="utf-8").write(json.dumps(D, ensure_ascii=False, indent=None))
print("ok", {c: len(codes[c]) for c in codes})
