# 0.60: генератор новых тем законов. Варианты задаются осями (экономика, свобода, зелёное, национальное) и своими эффектами;
# реакции групп и партий выводятся из осей. Результат — scripts/data/data_laws60.gd
import json, math

GROUPS = ["Рабочие", "Бизнес", "Пенсионеры", "Молодёжь", "Бюджетники", "Село", "Силовики", "Экологи"]
# чувствительность групп к осям: e — рынок (+) / государство (−); l — свобода (+) / порядок (−); g — зелёное; n — консервативное, национальное (+) / космополитное (−)
GS = {
    "Рабочие":    {"e": -0.8, "l": 0.1, "n": 0.2},
    "Бизнес":     {"e": 0.9, "l": 0.2, "g": -0.3},
    "Пенсионеры": {"e": -0.3, "l": -0.3, "n": 0.4},
    "Молодёжь":   {"e": -0.1, "l": 0.7, "g": 0.4, "n": -0.4},
    "Бюджетники": {"e": -0.6, "l": 0.1},
    "Село":       {"e": -0.1, "n": 0.7, "g": -0.3},
    "Силовики":   {"l": -0.8, "n": 0.4},
    "Экологи":    {"g": 1.0, "l": 0.2},
}
# архетипы партий: 0 own, 1 soc, 2 lib, 3 left, 4 green, 5 popl, 6 oth, 7 euro, 8 region, 9 prot
PS = {
    1: {"e": -0.9, "l": 0.4, "g": 0.3, "n": -0.3},
    2: {"e": 1.0, "l": 0.8, "g": -0.1, "n": -0.4},
    3: {"e": -1.2, "l": 0.3, "g": 0.4, "n": -0.4},
    4: {"e": -0.3, "l": 0.5, "g": 1.2, "n": -0.3},
    5: {"e": -0.5, "l": -0.3, "g": -0.2, "n": 0.8},
    7: {"e": 0.2, "l": 0.6, "g": 0.4, "n": -0.8},
    8: {"n": 0.3},
    9: {"e": -0.1, "l": -0.1, "n": 0.4},
}


def snap(x, step=0.5):
    return round(x / step) * step


def derive_s(ax, mult=1.0):
    out = {}
    for g, w in GS.items():
        v = sum(w.get(k, 0.0) * ax.get(k, 0.0) for k in ("e", "l", "g", "n")) * mult
        v = snap(max(-7.0, min(7.0, v)))
        if abs(v) >= 0.5:
            out[g] = v
    return out


def derive_ps(ax, mult=1.0):
    out = {}
    for p, w in PS.items():
        v = sum(w.get(k, 0.0) * ax.get(k, 0.0) for k in ("e", "l", "g", "n")) * mult
        v = snap(max(-9.0, min(9.0, v)), 0.5)
        if abs(v) >= 0.5:
            out[p] = v
    return out


def V(n, d, c=None, ax=None, s=None, a=None, x=None, st=None, ps=None, rg=None, extra=None, k=1.0):
    """Один вариант закона. ax — оси; s/ps дополняют и перекрывают выведенные из осей."""
    v = {"n": n, "d": d}
    if c is not None:
        v["c"] = float(c)
    if ax is not None:
        ss = derive_s(ax, k)
        ss.update(s or {})
        ppp = derive_ps(ax, k)
        ppp.update(ps or {})
    else:
        ss, ppp = (s or {}), (ps or {})
    if ss:
        v["s"] = ss
    if a:
        v["a"] = a
    if x:
        v["x"] = x
    if st:
        v["st"] = st
    if rg:
        v["rg"] = rg
    if ppp:
        v["ps"] = ppp
    if extra:
        v.update(extra)
    return v


TOPICS = []
PARAMS = []
AREA = {}
START = {}   # id -> {cc: idx}


def T(id, cat, area, name, desc, variants, fund=False, start=None):
    t = {"id": id, "cat": cat, "name": name, "desc": desc, "v": variants}
    if fund:
        t["fund"] = True
    TOPICS.append(t)
    AREA[id] = area
    if start:
        START[id] = start


def P(id, cat, area, name, desc, unit, fmt, lo, hi, fs, ref, step, c0, ck, s=None, a=None, x=None, st=None, ps=None, setk=None, setm=None, start=None):
    p = {"id": id, "unit": unit, "cat": cat, "name": name, "desc": desc, "fmt": fmt, "lo": lo, "hi": hi, "fs": fs, "ref": ref, "step": step, "c0": c0, "ck": ck}
    for k, v in (("s", s), ("a", a), ("x", x), ("st", st), ("ps", ps)):
        if v:
            p[k] = v
    if setk:
        p["setk"] = setk
        p["setm"] = setm
    PARAMS.append(p)
    AREA[id] = area
    if start:
        START[id] = start


# --- вывод в GDScript ---
def gd(v, ind=0):
    t = "\t" * ind
    if isinstance(v, dict):
        if not v:
            return "{}"
        items = []
        for k, x in v.items():
            ks = str(k) if isinstance(k, int) else json.dumps(k, ensure_ascii=False)
            items.append("%s: %s" % (ks, gd(x, ind + 1)))
        return "{" + ", ".join(items) + "}"
    if isinstance(v, list):
        return "[" + ", ".join(gd(x, ind + 1) for x in v) + "]"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, float):
        r = repr(round(v, 4))
        return r if ("." in r or "e" in r) else r + ".0"
    if isinstance(v, int):
        return str(v)
    return json.dumps(v, ensure_ascii=False)


def topic_gd(t):
    head = '{"id": %s, "cat": %d, "name": %s, "desc": %s%s, "v": [\n' % (json.dumps(t["id"]), t["cat"], json.dumps(t["name"], ensure_ascii=False), json.dumps(t["desc"], ensure_ascii=False), ', "fund": true' if t.get("fund") else "")
    body = ",\n".join("\t\t" + gd(v) for v in t["v"])
    return "\t" + head + body + "]}"
