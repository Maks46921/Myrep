import re, json
def _strip_commas(s):
    out = []; i = 0; n = len(s); ins = False
    while i < n:
        ch = s[i]
        if ins:
            out.append(ch)
            if ch == "\\":
                out.append(s[i + 1]); i += 1
            elif ch == '"':
                ins = False
        elif ch == '"':
            ins = True; out.append(ch)
        elif ch == ",":
            j = i + 1
            while j < n and s[j] in " \t\r\n": j += 1
            if j < n and s[j] in "}]":
                pass
            else:
                out.append(ch)
        else:
            out.append(ch)
        i += 1
    return "".join(out)
def load(path):
    s = open(path, encoding="utf-8").read()
    s = _strip_commas(s)
    s = re.sub(r"Color\(([^)]*)\)", lambda m: '{"__c":[%s]}' % m.group(1), s)
    s = re.sub(r"Vector2\(([^)]*)\)", lambda m: '{"__v":[%s]}' % m.group(1), s)
    s = re.sub(r"(?m)^(\s*)(-?\d+):", lambda m: '%s"__i:%s":' % (m.group(1), m.group(2)), s)
    return json.loads(s)
def _enc(v, ind):
    t = "\t" * ind
    if isinstance(v, dict):
        if "__c" in v: return "Color(%s)" % ", ".join(_n(x) for x in v["__c"])
        if "__v" in v: return "Vector2(%s)" % ", ".join(_n(x) for x in v["__v"])
        if not v: return "{}"
        return "{\n" + ",\n".join('%s\t%s: %s' % (t, (str(k) if isinstance(k, int) else (str(k)[4:] if str(k).startswith("__i:") else json.dumps(str(k), ensure_ascii=False))), _enc(x, ind + 1)) for k, x in v.items()) + "\n" + t + "}"
    if isinstance(v, list):
        if not v: return "[]"
        if all(not isinstance(x, (dict, list)) for x in v) and len(v) <= 12 and all(not isinstance(x, str) for x in v):
            return "[" + ", ".join(_enc(x, 0) for x in v) + "]"
        return "[\n" + ",\n".join(t + "\t" + _enc(x, ind + 1) for x in v) + "\n" + t + "]"
    if isinstance(v, bool): return "true" if v else "false"
    if v is None: return "null"
    if isinstance(v, str): return json.dumps(v, ensure_ascii=False)
    return _n(v)
def _n(x):
    if isinstance(x, float):
        r = repr(x)
        return r if ("." in r or "e" in r) else r + ".0"
    return str(x)
def dump(path, v):
    open(path, "w", encoding="utf-8").write(_enc(v, 0) + "\n")

def norm(v):
    """'__i:N' -> int в ключах (удобно для Python-кода)."""
    if isinstance(v, dict):
        return {(int(k[4:]) if isinstance(k, str) and k.startswith("__i:") else k): norm(x) for k, x in v.items()}
    if isinstance(v, list):
        return [norm(x) for x in v]
    return v
def loadn(path):
    return norm(load(path))
