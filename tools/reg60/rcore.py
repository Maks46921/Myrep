# 0.60: режимы — вспомогательные функции для данных (варианты режимов, события, особые строи).
import sys, os, json
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "law60"))
import importlib.util as _u
_sp = _u.spec_from_file_location("law60core", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "law60", "core.py"))
_m = _u.module_from_spec(_sp); _sp.loader.exec_module(_m)
gd = _m.gd

VARS = []      # варианты режимов
EVENTS = []    # события вариантов
ACTS = []      # новые рычаги
UNIQ = []      # особые строи
UEVENTS = []   # события особых строёв


def VAR(cls, id, name, desc, ideo, cause, m, start=None, tl=None, party="", motto="", fl=None, real="", cc=None, hist=None):
    """cls — класс режима; ideo — архетипы правящей партии (social, liberal, conserv, green, populist);
    cause — как возник режим (reform, revolution, coup, war, crisis); m — добавки к показателям (steady-state);
    start — стартовые страх/пропаганда/фальсификации/культ; tl — множители цен рычагов (0 — рычаг недоступен);
    party — как называется правящая сила; fl — идеологические метки флагов; real — образцы для расчёта; cc — страны, где вариант вероятнее."""
    v = {"id": id, "cls": cls, "n": name, "d": desc, "ideo": ideo, "cause": cause, "m": m}
    if start: v["start"] = start
    if tl: v["tl"] = tl
    if party: v["party"] = party
    if motto: v["mo"] = motto
    if fl: v["fl"] = fl
    if real: v["real"] = real
    if cc: v["cc"] = cc
    VARS.append(v)
    return v


def fx(cap=0.0, all=0.0, sup=None, reg=None, au=None, **kw):
    d = {}
    if cap: d["capital"] = float(cap)
    if all: d["all"] = float(all)
    if sup: d["support"] = {k: float(x) for k, x in sup.items()}
    if reg: d["regall"] = {k: float(x) for k, x in reg.items()}
    if au: d["au"] = {k: (x if isinstance(x, str) else float(x)) for k, x in au.items()}
    for k, x in kw.items():
        d[k] = x
    return d


def E(var, text, *opts):
    """событие варианта режима; opts — (подпись, fx)"""
    EVENTS.append({"var": var, "t": text, "o": [{"l": l, "fx": f} for l, f in opts]})


def ACT(id, name, cost, cd, cls, tip):
    ACTS.append([id, name, float(cost), int(cd), cls, tip])


# ---------- особые строи ----------
MECH = {}      # 12 механик
UREG = []      # 19 особых строёв
UEV = []       # события особых строёв


def BTN(id, label, cost, cd, d=0.0, fx=None, tip=""):
    b = {"id": id, "l": label, "cost": float(cost), "cd": int(cd), "d": float(d), "tip": tip}
    if fx:
        b["fx"] = fx
    return b


def MCH(id, name, desc, m, btns, drift=0.0, hook=""):
    """механика: m — добавки на 100 единиц показателя (масштабируются линейно); btns — кнопки; drift — дрейф за полгода"""
    MECH[id] = {"id": id, "n": name, "d": desc, "m": m, "b": btns, "drift": float(drift), "h": hook}


def ST(text, label, fx=None):
    return {"t": text, "l": label, "fx": fx or {}}


def UNIQ(id, cc, name, motto, desc, mech, start, m, need, keep, stages, w, gov="", partner=None, hist="", real="", fl=None):
    """особый строй: need — условия первого этапа, keep — условия следующих; stages — три этапа пути; w — реакция мира"""
    r = {"id": id, "cc": cc, "n": name, "mo": motto, "d": desc, "mech": mech, "start": start, "m": m, "need": need, "keep": keep,
         "st": stages, "w": w}
    if gov: r["gov"] = gov
    if partner: r["partner"] = partner
    if hist: r["hist"] = hist
    if real: r["real"] = real
    if fl: r["fl"] = fl
    UREG.append(r)
    return r


def UE(u, text, *opts):
    UEV.append({"u": u, "t": text, "o": [{"l": l, "fx": f} for l, f in opts]})
