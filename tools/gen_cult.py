#!/usr/bin/env python3
"""v55_1: собирает data/cult.dat — народы (культуры), церковь, промышленность и мегапроекты по странам.
Источники: tools/cult/catalog.py (справочник) и tools/cult/c_*.py (словарь COUNTRY по странам), регионы — tools/cult/regions.json.

  tools/gen_cult.py           проверить и записать data/cult.dat
  tools/gen_cult.py --check   только проверить
"""
import glob, importlib.util, json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CD = os.path.join(ROOT, "tools", "cult")
sys.path.insert(0, CD)
import catalog as K  # noqa: E402

ALL = ["DE", "FR", "NL", "BE", "LU", "AT", "CH", "CZ", "DK", "ES", "IT", "NO", "PL", "PT", "SE", "GB", "IE", "SI", "SK", "HU", "FI",
       "HR", "RS", "BA", "ME", "MK", "AL", "XK", "BG", "RO", "GR", "EE", "LV", "LT", "MD", "BY", "UA", "RU"]
GROUPS_RU = ["Рабочие", "Бизнес", "Пенсионеры", "Молодёжь", "Бюджетники", "Село", "Силовики", "Экологи"]
REG_KEYS = ["infra", "dev", "env", "edu", "health", "loyalty", "unrest"]
MK = ["agr", "res", "ind", "ene", "con", "srv"]
NCAT = 14


def load_countries():
    out = {}
    for f in sorted(glob.glob(os.path.join(CD, "c_*.py"))):
        sp = importlib.util.spec_from_file_location(os.path.basename(f)[:-3], f)
        m = importlib.util.module_from_spec(sp)
        sp.loader.exec_module(m)
        for cc, d in getattr(m, "COUNTRY", {}).items():
            if cc in out:
                print("ПОВТОР страны", cc, "в", f)
            out[cc] = d
    return out


def check(C, RJ):
    errs = []
    def e(cc, msg):
        errs.append("%s: %s" % (cc, msg))
    for cc in ALL:
        if cc not in C:
            e(cc, "нет данных")
            continue
        d = C[cc]
        codes = {r[0] for r in RJ[cc]["regions"]}
        for k in ["base", "tit", "pol", "church", "ind", "mega"]:
            if k not in d:
                e(cc, "нет поля " + k)
        for cid, v in d.get("base", {}).items():
            if cid not in K.CULTS:
                e(cc, "неизвестный народ " + cid)
            if not (0 <= float(v) <= 100):
                e(cc, "доля вне 0..100: %s" % cid)
        sb = sum(float(v) for v in d.get("base", {}).values())
        if sb > 100.5 or sb < 80:
            e(cc, "сумма base = %.1f" % sb)
        for rc, rv in d.get("reg", {}).items():
            if rc not in codes:
                e(cc, "неизвестный регион " + rc)
            for cid, v in rv.items():
                if cid not in K.CULTS:
                    e(cc, "регион %s: неизвестный народ %s" % (rc, cid))
            if sum(float(v) for v in rv.values()) > 100.5:
                e(cc, "регион %s: сумма > 100" % rc)
        for cid in d.get("tit", []) + d.get("prot", []):
            if cid not in K.CULTS:
                e(cc, "tit/prot: неизвестный народ " + cid)
        if not d.get("tit"):
            e(cc, "пустой tit")
        p = d.get("pol", {})
        for k, mx in (("lang", 3), ("school", 3), ("auto", 3), ("course", 2)):
            if k not in p or not (0 <= int(p[k]) <= mx):
                e(cc, "pol.%s вне диапазона" % k)
        for cid, v in d.get("griev", {}).items():
            if cid not in K.CULTS or not (0 <= float(v) <= 1):
                e(cc, "griev %s" % cid)
        for s, cid in d.get("party", {}).items():
            if not (0 <= int(s) <= 9) or cid not in K.CULTS:
                e(cc, "party %s:%s" % (s, cid))
        for o, mix in d.get("orig", {}).items():
            if not (0 <= int(o) <= 5):
                e(cc, "orig: номер %s" % o)
            for cid in mix:
                if cid not in K.CULTS:
                    e(cc, "orig: неизвестный народ " + cid)
        ch = d.get("church", {})
        for k in ("name", "faith", "state", "pow", "fin", "piety"):
            if k not in ch:
                e(cc, "church: нет " + k)
        if ch:
            if not (0 <= int(ch.get("faith", 0)) <= 6) or not (-1 <= int(ch.get("state", -1)) <= 6):
                e(cc, "church: faith/state")
            if not (0 <= float(ch.get("pow", 0)) <= 100) or not (0 <= float(ch.get("piety", 0)) <= 100) or int(ch.get("fin", 0)) not in (0, 1, 2):
                e(cc, "church: pow/piety/fin")
        ind = d.get("ind", {})
        for gid in K.GOODS_I:
            if gid not in ind:
                e(cc, "ind: нет " + gid)
        for gid, v in ind.items():
            if gid not in K.GOODS_I and gid not in K.GOODS_X:
                e(cc, "ind: неизвестный товар " + gid)
            if not (0 <= float(v) <= 20):
                e(cc, "ind: %s вне 0..20" % gid)
        for gid in d.get("gx", {}):
            if gid not in K.GOODS_X:
                e(cc, "gx: неизвестный товар " + gid)
        mg = d.get("mega", {})
        for k in ("id", "name", "region", "desc", "cat", "cost", "months"):
            if k not in mg:
                e(cc, "mega: нет " + k)
        if mg:
            if mg.get("region") not in codes:
                e(cc, "mega: неизвестный регион %s" % mg.get("region"))
            if not (0 <= int(mg.get("cat", 0)) < NCAT):
                e(cc, "mega: cat")
            if not (0.5 <= float(mg.get("cost", 0)) <= 8.0) or not (12 <= int(mg.get("months", 0)) <= 120):
                e(cc, "mega: cost/months")
            for k in mg.get("k", {}):
                if k not in MK:
                    e(cc, "mega.k: " + k)
            for k in mg.get("ind", {}):
                if k not in K.GOODS_I:
                    e(cc, "mega.ind: " + k)
            for k in mg.get("reg", {}):
                if k not in REG_KEYS:
                    e(cc, "mega.reg: " + k)
            for g in mg.get("nat", {}).get("support", {}):
                if g not in GROUPS_RU:
                    e(cc, "mega.nat.support: " + g)
    return errs


def norm(v):
    s = sum(v)
    return [x / s for x in v] if s > 0 else v


def build(C, RJ):
    D = {"groups": {}, "cults": {}, "orig": K.ORIG_CULT, "gx": {}, "gi": {}, "inputs": K.INPUTS, "country": {}}
    for gid, (nm, col) in K.GROUPS.items():
        D["groups"][gid] = {"name": nm, "col": col}
    for cid, (nm, grp, lang, home, faith, fert) in K.CULTS.items():
        D["cults"][cid] = {"name": nm, "grp": grp, "lang": lang, "home": home, "faith": faith, "fert": fert}
    for gid, (nm, sh, cat, w) in K.GOODS_X.items():
        D["gx"][gid] = {"name": nm, "short": sh, "cat": cat, "sh": w}
    for gid, (nm, sh, kind, mk, dc) in K.GOODS_I.items():
        D["gi"][gid] = {"name": nm, "short": sh, "kind": kind, "mk": mk, "dc": dc}
    for cc in ALL:
        d = C[cc]
        regs = RJ[cc]["regions"]
        # список народов страны: из base, регионов, мигрантов (по умолчанию и своих) и "oth"
        cl = []
        def add(cid):
            if cid not in cl:
                cl.append(cid)
        for cid, v in sorted(d["base"].items(), key=lambda x: -float(x[1])):
            add(cid)
        for rv in d.get("reg", {}).values():
            for cid in rv:
                add(cid)
        orig = [dict(o) for o in K.ORIG_CULT]
        for o, mix in d.get("orig", {}).items():
            orig[int(o)] = dict(mix)
        for o in orig:
            for cid in o:
                add(cid)
        add("oth")
        n = len(cl)
        def vec(src):
            v = [0.0] * n
            for cid, x in src.items():
                v[cl.index(cid)] += float(x)
            left = max(0.0, 100.0 - sum(v))
            v[cl.index("oth")] += left
            return norm(v)
        base = vec(d["base"])
        rv = {}
        for code, nm, pop in regs:
            rv[code] = vec(d["reg"][code]) if code in d.get("reg", {}) else list(base)
        # подгонка: средний по населению состав = национальному (регионы с явными данными меняются меньше)
        pops = {code: max(0.01, float(pop)) for code, nm, pop in regs}
        fixed = set(d.get("reg", {}).keys())
        for it in range(60):
            tot = sum(pops.values())
            avg = [sum(rv[c][f] * pops[c] for c in rv) / tot for f in range(n)]
            for c in rv:
                w = 0.35 if c in fixed else 1.0
                rv[c] = norm([rv[c][f] * ((base[f] / avg[f]) ** w if avg[f] > 1e-9 and base[f] > 0 else (1.0 if avg[f] <= 1e-9 else 0.0)) for f in range(n)])
        r5 = lambda v: [round(x, 5) if x >= 0.0001 else 0.0 for x in v]
        om = []
        for o in orig:
            v = [0.0] * n
            for cid, x in o.items():
                v[cl.index(cid)] += float(x)
            om.append(r5(norm(v)))
        out = {"cl": cl, "base": r5(base), "reg": {c: r5(v) for c, v in rv.items()}, "tit": d["tit"], "prot": d.get("prot", []),
               "pol": d["pol"], "griev": {k: float(v) for k, v in d.get("griev", {}).items()},
               "party": {str(int(k)): v for k, v in d.get("party", {}).items()}, "orig": om, "church": d["church"],
               "ind": {k: float(v) for k, v in d["ind"].items()}, "gx": {k: float(v) for k, v in d.get("gx", {}).items()}, "mega": d["mega"]}
        D["country"][cc] = out
    return D


def main():
    RJ = json.load(open(os.path.join(CD, "regions.json"), encoding="utf-8"))
    C = load_countries()
    errs = check(C, RJ)
    for x in errs:
        print("  ", x)
    missing = [cc for cc in ALL if cc not in C]
    print("стран с данными: %d из %d; ошибок: %d" % (len(ALL) - len(missing), len(ALL), len(errs)))
    if "--check" in sys.argv:
        sys.exit(1 if errs else 0)
    if errs:
        sys.exit(1)
    D = build(C, RJ)
    open(os.path.join(ROOT, "data", "cult.dat"), "w", encoding="utf-8").write(json.dumps(D, ensure_ascii=False))
    print("записано data/cult.dat")


if __name__ == "__main__":
    main()
