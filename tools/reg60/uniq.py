# 0.60: особые строи — собирает данные 19 строёв (u1…u4), 12 механик (mech) и событий для emit.py
import mech, u1, u2, u3, u4
from rcore import UREG, UEV, MECH, gd


def emit_lines():
    out = ["const REG_UNIQ60 := ["]
    out.append(",\n".join("\t" + gd(r) for r in UREG))
    out.append("]\n")
    out.append("const UQ_MECH60 := " + gd(MECH) + "\n")
    out.append("const REG_UEV60 := [")
    out.append(",\n".join("\t" + gd(e) for e in UEV))
    out.append("]\n")
    return out
