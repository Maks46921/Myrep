import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rcore import *
import variants, ev1, ev2, ev3, acts
try:
    import uniq
except ImportError:
    uniq = None

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def main():
    out = ['# 0.60: варианты режимов, события вариантов, новые рычаги и особые строи стран.',
           '# Файл создан скриптом tools/reg60/emit.py — правьте данные там (variants.py, ev1.py…ev3.py, acts.py, uniq.py).',
           'extends "res://scripts/data/data_laws60.gd"', '']
    out.append("const REG_VARS60 := [")
    out.append(",\n".join("\t" + gd(v) for v in VARS))
    out.append("]\n")
    out.append("const REG_EVENTS60 := [")
    out.append(",\n".join("\t" + gd(e) for e in EVENTS))
    out.append("]\n")
    out.append("const AU_ACTS60 := [")
    out.append(",\n".join("\t" + gd(a) for a in ACTS))
    out.append("]\n")
    if uniq is not None:
        out.extend(uniq.emit_lines())
    p = os.path.join(ROOT, "scripts/data/data_regimes60.gd")
    open(p, "w", encoding="utf-8").write("\n".join(out))
    print(p, len(VARS), len(EVENTS), len(ACTS))


main()
