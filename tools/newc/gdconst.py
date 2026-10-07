"""Чтение и замена констант `const NAME := {...}` / `[...]` в .gd-файлах (значения в формате, совместимом с datio)."""
import re, sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import datio, json

def _find(text, name):
    m = re.search(r"(?m)^(const|var) %s(?:\s*:[^=]*)?\s*:?=\s*" % re.escape(name), text)
    if not m:
        raise KeyError(name)
    i = m.end()
    op = text[i]
    cl = {"{": "}", "[": "]"}[op]
    depth = 0; j = i; ins = False
    while j < len(text):
        ch = text[j]
        if ins:
            if ch == "\\": j += 1
            elif ch == '"': ins = False
        else:
            if ch == '"': ins = True
            elif ch in "{[": depth += 1
            elif ch in "}]":
                depth -= 1
                if depth == 0: break
        j += 1
    return m.start(), i, j + 1

def _parse(txt):
    import tempfile
    p = tempfile.mktemp(suffix=".dat")
    open(p, "w", encoding="utf-8").write(txt)
    try:
        return datio.load(p)
    finally:
        os.remove(p)

def get(path, name):
    t = open(path, encoding="utf-8").read()
    a, i, j = _find(t, name)
    return datio.norm(_parse(t[i:j]))

def _flat(v):
    if isinstance(v, dict):
        if "__c" in v or "__v" in v: return datio._enc(v, 0)
        return "{" + ", ".join("%s: %s" % ((str(k) if isinstance(k, int) else json.dumps(str(k), ensure_ascii=False)), _flat(x)) for k, x in v.items()) + "}"
    if isinstance(v, list):
        return "[" + ", ".join(_flat(x) for x in v) + "]"
    return datio._enc(v, 0)

def put(path, name, value, multiline=False):
    t = open(path, encoding="utf-8").read()
    a, i, j = _find(t, name)
    if multiline:
        txt = datio._enc(value, 0)
    else:
        txt = _flat(value)
    open(path, "w", encoding="utf-8").write(t[:i] + txt + t[j:])
