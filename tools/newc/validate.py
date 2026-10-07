#!/usr/bin/env python3
"""Проверка модуля страны data_<cc>.py:  python3 tools/newc/validate.py gb   (из корня проекта или копии)"""
import sys, os, importlib
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
cc = sys.argv[1].upper()
m = importlib.import_module("data_%s" % cc.lower())
D = m.D
NO = datio.loadn(os.path.join(ROOT, "data", "countries", "NO.dat"))
bad = []
def fail(s): bad.append(s); print("ОШИБКА:", s)
def warn(s): print("замечание:", s)
need = [k for k in NO if k not in ("DIP_ORDER", "DIP_C", "DIP_LIKES")]
for k in need:
    if k not in D: fail("нет ключа " + k); continue
    if type(D[k]) != type(NO[k]) and not (isinstance(D[k], (int, float)) and isinstance(NO[k], (int, float))): fail("тип %s: %s вместо %s" % (k, type(D[k]).__name__, type(NO[k]).__name__))
for k in D:
    if k not in need: fail("лишний ключ " + k)
if bad: sys.exit(1)
def keys_eq(k, sub=None):
    a = D[k] if sub is None else D[k][sub]; b = NO[k] if sub is None else NO[k][sub]
    if set(a.keys()) != set(b.keys()): fail("ключи %s%s: лишние %s, не хватает %s" % (k, "" if sub is None else "." + str(sub), sorted(set(a) - set(b)), sorted(set(b) - set(a))))
for k in ["TERMS", "INFO", "MACRO", "UPPER"]: keys_eq(k)
for k in ["PARTY_NAMES", "PARCH", "PARTY_DESC", "PARTY_COLORS", "HEMI_ORDER", "PARTY_LEADERS", "PARTY_DEMANDS", "PARTY_MINISTRIES", "PARTY_TRAITS", "PARTY_LAW_DEMAND", "DE_START_SEATS", "DE_JOIN_ADJ", "ARCHS"]:
    if len(D[k]) != 10: fail("%s: нужно 10 элементов, а их %d" % (k, len(D[k])))
if len(D["MINISTRIES"]) != 12 or len(D["DE_START_MIN"]) != 12: fail("MINISTRIES / DE_START_MIN: по 12")
if len(D["MINISTER_NAMES"]) != 34: fail("MINISTER_NAMES: 34 имени, а их %d" % len(D["MINISTER_NAMES"]))
if len(D["GOV_NAMES"]) != 20: fail("GOV_NAMES: 20 имён, а их %d" % len(D["GOV_NAMES"]))
if sorted(D["HEMI_ORDER"]) != list(range(10)): fail("HEMI_ORDER — перестановка 0..9")
if sum(D["DE_START_SEATS"]) != D["SEATS"]: fail("SEATS %s != сумма мест %s" % (D["SEATS"], sum(D["DE_START_SEATS"])))
if D["COALITION0"][0] != 0: fail("COALITION0 должна начинаться с 0")
if abs(sum(D["GROUP_WEIGHT"].values()) - 1.0) > 0.011: fail("GROUP_WEIGHT: сумма %.3f" % sum(D["GROUP_WEIGHT"].values()))
if set(D["GROUP_WEIGHT"]) != set(NO["GROUP_WEIGHT"]) or set(D["GROUP_BASE"]) != set(NO["GROUP_BASE"]): fail("группы GROUP_WEIGHT/GROUP_BASE")
if [p["key"] for p in D["POLICY"]] != [p["key"] for p in NO["POLICY"]]: fail("POLICY: порядок и ключи как у образца")
for k in ["MARKETS_OVR", "GOODS_OVR"]: 
    if set(D[k]) - set(NO[k]) | set(NO[k]) - set(D[k]) and k == "MARKETS_OVR": fail("MARKETS_OVR: ключи %s" % sorted(NO[k]))
if set(D["DE_PARAM"]) != set(NO["DE_PARAM"]): fail("DE_PARAM: ключи %s" % sorted(set(NO["DE_PARAM"]) ^ set(D["DE_PARAM"])))
# регионы
import json
units = datio.loadn(os.path.join(ROOT, "data", "world_units.dat"))
uid = [u["id"] for u in units if u["cc"] == cc]
codes = [r["code"] for r in D["REGIONS"]]
if sorted("%s-%s" % (cc, c) for c in codes) != sorted(uid): fail("коды регионов не совпадают с картой: %s против %s" % (sorted(codes), sorted(u.split("-")[1] for u in uid)))
if len(D["REG_BIAS"]) != len(codes) or any(len(r) != 10 for r in D["REG_BIAS"]): fail("REG_BIAS: %d строк по 10" % len(codes))
if len(m.E) != len(codes) or any(len(r) != 10 for r in m.E): fail("E: %d строк по 10 (результат выборов по регионам)" % len(codes))
for r in D["REGIONS"]:
    for k in NO["REGIONS"][0]:
        if k not in r: fail("регион %s: нет поля %s" % (r["code"], k))
    if abs(sum(r["sec"].values()) - 1.0) > 0.01: fail("регион %s: sec сумма %.3f" % (r["code"], sum(r["sec"].values())))
popsum = sum(r["popm"] for r in D["REGIONS"])
if abs(popsum - D["INFO"]["pop"]) / D["INFO"]["pop"] > 0.03: fail("население регионов %.2f != INFO.pop %.2f" % (popsum, D["INFO"]["pop"]))
# законы
tids = []
for t in D["DE_TOPICS"]:
    if t["id"] in tids: fail("повтор id темы " + t["id"])
    tids.append(t["id"])
    if len(t["v"]) < 2: fail("тема %s: нужно ≥2 вариантов" % t["id"])
    if "c" in t["v"][0]: fail("тема %s: вариант 0 — действующий порядок, без стоимости" % t["id"])
    for j, v in enumerate(t["v"]):
        if j and ("c" not in v or "ps" not in v): warn("тема %s вариант %d: нужны c и ps" % (t["id"], j))
        if "ps" in v and not set(v["ps"].keys()) <= set(range(10)): fail("тема %s вариант %d: ps по ключам 0..9" % (t["id"], j))
if len(D["DE_TOPICS"]) < 36: warn("тем законов %d (образец: 39)" % len(D["DE_TOPICS"]))
for tid, vs in D["LAW_TAGS"].items():
    if tid not in tids: fail("LAW_TAGS: нет темы " + tid)
    t = [x for x in D["DE_TOPICS"] if x["id"] == tid][0]
    for k, (dim, sg) in vs.items():
        if dim not in ("eu", "aus", "trd", "brd", "nuk") or abs(sg) > 2: fail("LAW_TAGS %s %s" % (tid, k))
        elif k >= len(t["v"]): warn("LAW_TAGS %s: вариант %s не существует" % (tid, k))
for p in D["PARTY_LAW_DEMAND"]:
    if p and p["tid"] not in tids and p["tid"] not in ("min_wage", "pension_age", "carbon_tax", "migration", "state_property", "labor_code", "digital_law", "family_policy", "unemp_benefit", "copay", "agri_law", "uni_places", "mil_service"): warn("PARTY_LAW_DEMAND: неизвестный tid " + p["tid"])
ev = D["EVENTS_C"]; nw = D["NEWS_C"]
if len(ev) < 40: warn("событий %d (образец: 47)" % len(ev))
if len(nw) < 20: warn("новостей %d (образец: 24)" % len(nw))
for i, e in enumerate(ev):
    if "t" not in e or not e.get("o"): fail("событие %d без t/o" % i); continue
    for o in e["o"]:
        if "l" not in o or "fx" not in o: fail("событие %d: вариант без l/fx" % i)
for i, n in enumerate(nw):
    if "text" not in n or "fx" not in n: fail("новость %d без text/fx" % i)
# мир
W = m.WORLD
for k in ["name", "cap", "latlon", "pop", "gdp", "debt", "growth", "infl", "unemp", "def", "stab", "appr", "gov", "gov_party", "pot", "ecb_w", "stance", "desc", "leader", "pn", "eu", "euro", "likes", "dislikes", "open", "stance0", "ccol", "rel", "trade_x", "trade_m"]:
    if k not in W: fail("WORLD: нет " + k)
if len(W.get("pn", [])) != 10: fail("WORLD.pn: 10 коротких названий партий")
oth = [c for c in ["DE", "FR", "NL", "BE", "LU", "AT", "CH", "CZ", "DK", "ES", "IT", "NO", "PL", "PT", "SE", "GB", "IE", "SI", "SK", "HU", "FI"] if c != cc]
for k in ("rel", "trade_x", "trade_m"):
    miss = [c for c in oth if c not in W.get(k, {})]
    new4 = [c for c in miss if c in ("SI", "SK", "HU", "FI")]      # v33: новые страны — обязательны для v33-стран, для GB/IE только замечание
    if new4 and cc not in ("SI", "SK", "HU", "FI"): warn("WORLD.%s: нет %s" % (k, new4)); miss = [c for c in miss if c not in new4]
    if miss: fail("WORLD.%s: нет %s" % (k, miss))
if len(m.REG_EVENTS) < 6: warn("региональных событий %d (нужно ≥ 6)" % len(m.REG_EVENTS))
for e in m.REG_EVENTS:
    if "t" not in e or "o" not in e: fail("REG_EVENTS: событие без t/o")
if "head" not in m.ELEC or "sys" not in m.ELEC: fail("ELEC: нужны sys и head")
print("итог:", "ОШИБОК %d" % len(bad) if bad else "OK")
sys.exit(1 if bad else 0)
