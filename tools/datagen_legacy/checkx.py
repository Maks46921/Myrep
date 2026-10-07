#!/usr/bin/env python3
# Проверка x_<cc>.py: python3 checkx.py CC
import sys, importlib
from common import *
import laws_c
cc = sys.argv[1].upper(); lo = cc.lower()
X = importlib.import_module("x_" + lo)
errs = []; warn = []
E = errs.append
RESERVED = {"state_structure","gov_form","econ_model","civil_rights","trade_policy","social_model","property_rights","military_state","debt_default","state_church","eu_policy"}
FX = {"slider","support","capital","shock","debt","unemp","infl","all","state","regall","reg","reg_transfer","econ","dip","other_rev","sector"}
CONDS = {"env_low","infl_high","debt_high","unemp_high","sec_low","appr_low","rich","pre_elec"}
REGK = {"any","unrest30","sep","res","agr","ind","srv","poor","regional"}
PSK = {"own","soc","lib","left","green","popl","popr","cons","euro","region","prot","oth"}
AK = {"growth_bonus","equal_shift","extra_spend","sec_bonus","mood_shift","dem_shift","dip_bonus","capital_bonus","reg_unrest_shift","auto_shift","eff_bonus","corr_shift","unemp_base","cb_bias","reg_dev_bonus"}
base_ids = set()
import importlib as il
try:
    l = il.import_module("l_" + lo)
    ci = dict(l.INFO); ci["name"] = "Страна"; ci["gen"] = "Страны"
    base_ids = {t["id"] for t in l.topics(ci)}
except ModuleNotFoundError:
    ci = dict(laws_c.LAW_INFO[cc]); ci["name"] = "Страна"; ci["gen"] = "Страны"
    base_ids = {t["id"] for t in laws_c.TOPICS[cc](ci)}
ci = dict(ci)
ts = X.topics_x(ci)
print("тем:", len(ts), "событий:", len(X.EVENTS_X), "новостей:", len(X.NEWS_X))
if len(ts) < 6: E("нужно >= 6 новых тем")
if len(X.EVENTS_X) < 15: E("нужно >= 15 новых событий")
if len(X.NEWS_X) < 8: E("нужно >= 8 новых новостей")
seen = set()
for t in ts:
    if t["id"] in base_ids or t["id"] in seen or t["id"] in RESERVED: E("id темы занят/зарезервирован: %s" % t["id"])
    seen.add(t["id"])
    if t["cat"] not in (0, 1, 2): E("cat темы %s" % t["id"])
    if len(t["v"]) < 3 or len(t["v"]) > 6: E("тема %s: вариантов 3..6" % t["id"])
    for i, v in enumerate(t["v"]):
        if i > 0 and "c" not in v: E("тема %s вар %d: нет стоимости c" % (t["id"], i))
        if i == 0 and (v.get("a") or v.get("s") or v.get("st")): E("тема %s: вариант 0 без эффектов" % t["id"])
        for k in v.get("a", {}):
            if k not in AK: warn.append("тема %s: ключ a.%s неизвестен (проверь)" % (t["id"], k))
        for k in v.get("psa", {}):
            if k not in PSK: E("psa ключ %s" % k)
        for g in v.get("s", {}):
            if g not in GROUPS: E("группа %s" % g)
for e in X.EVENTS_X:
    if "t" not in e or not e.get("o") or not (2 <= len(e["o"]) <= 4): E("событие без t/o или не 2..4 вариантов: %s" % str(e.get("t", ""))[:40])
    if e.get("cond") and e["cond"] not in CONDS: E("cond %s" % e["cond"])
    if e.get("reg") and e["reg"] not in REGK: E("reg %s" % e["reg"])
    for o in e.get("o", []):
        if "l" not in o or "fx" not in o: E("вариант без l/fx")
        for k in o.get("fx", {}):
            if k not in FX: E("fx ключ %s" % k)
for n in X.NEWS_X:
    if "text" not in n or "fx" not in n: E("новость без text/fx")
nreg = sum(1 for e in X.EVENTS_X if e.get("reg")); ndip = sum(1 for e in X.EVENTS_X if any("dip" in o.get("fx", {}) for o in e.get("o", [])))
print("событий с reg:", nreg, "с dip:", ndip)
if nreg < 3: E("нужно >= 3 событий с reg")
if ndip < 3: E("нужно >= 3 событий с dip")
for w in warn: print("WARN", w)
if errs:
    print("\n".join(errs)); sys.exit(1)
print("OK")
