import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import t_elec
import c1, c2, c3, c4, c5
import cdsl
from core import *
import areamap, starts

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def main():
    out = ['# 0.60: новые темы законов, ползунки, области законов и стартовые значения стран.',
           '# Файл создан скриптом tools/law60/emit.py — правьте данные там (tools/law60/t_*.py, starts.py, areamap.py).',
           'extends "res://scripts/data/data_content.gd"', '']
    out.append("const NEW_TOPICS60 := [")
    out.append(",\n".join(topic_gd(t) for t in TOPICS))
    out.append("]\n")
    out.append("const LAW_PARAMS60 := [")
    out.append(",\n".join("\t" + gd(p) for p in PARAMS))
    out.append("]\n")
    # области всех известных id
    area = {}
    for ln in open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "allids.txt"), encoding="utf-8"):
        n, i, cat, name = ln.rstrip("\n").split("|", 3)
        a = areamap.area_of(i, name)
        if a is not None:
            area[i] = a
    area.update(AREA)
    out.append("# область закона (0 экономика и налоги … 10 выборы и партии); для неизвестных id область подбирается по словам в названии")
    out.append("const LAW_AREA60 := " + json.dumps(area, ensure_ascii=False, sort_keys=True) + "\n")
    out.append("const LAW_AREA_NAMES := " + json.dumps(areamap.AREA_NAMES, ensure_ascii=False) + "\n")
    st = {}
    for tid, d in starts.START_IDX.items():
        for cc, idx in d.items():
            st.setdefault(cc, {})[tid] = idx
    out.append("const LAW_START60 := " + gd({k: st[k] for k in sorted(st)}) + "\n")
    pr = {}
    for pid, d in starts.PARAM_REF.items():
        for cc, v in d.items():
            pr.setdefault(cc, {})[pid] = v
    out.append("const PARAM_REF60 := " + gd({k: pr[k] for k in sorted(pr)}) + "\n")
    out.append("# особые законы стран: id в данных страны не повторяются, доли партий заданы по местам партий страны")
    out.append("const COUNTRY_TOPICS60 := {")
    parts = []
    for cc in sorted(cdsl.CTOPICS):
        parts.append("\t" + json.dumps(cc) + ": [\n" + ",\n".join(topic_gd(t) for t in cdsl.CTOPICS[cc]) + "]")
    out.append(",\n".join(parts))
    out.append("}\n")
    out.append("const REMOVE60 := " + gd({k: starts.REMOVE[k] for k in sorted(starts.REMOVE)}) + "\n")
    p = os.path.join(ROOT, "scripts/data/data_laws60.gd")
    open(p, "w", encoding="utf-8").write("\n".join(out))
    print(p, len(TOPICS), len(PARAMS), len(area))


main()
