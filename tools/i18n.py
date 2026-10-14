#!/usr/bin/env python3
"""v54_1: английская версия игры.

Игра написана по-русски: все тексты — строковые литералы в скриптах (main.gd, scripts/**) и данных (data/**.dat).
Английская версия — отдельное дерево en/ (en/main.gd, en/scripts, en/data), где каждый русский литерал заменён переводом,
а пути res://scripts/, res://data/ и res://main.gd указывают в en/. Язык выбирается в меню (boot.gd в корне грузит нужный main.gd).

  python3 tools/i18n.py extract        # собрать русские строки -> i18n/src.json, недостающие переводы -> i18n/todo/chunk_NNN.json
  python3 tools/i18n.py check          # проверить переводы (плейсхолдеры %s, {r}, BBCode, переводы строк)
  python3 tools/i18n.py build          # собрать дерево en/ (непереведённые строки остаются русскими, их число печатается)

Переводы: i18n/en/*.json — словари {id: перевод}, id = первые 12 знаков sha1 русской строки.
i18n/en/00_manual.json — ручные переводы (глоссарий), они важнее остальных.
"""
import hashlib, json, os, re, shutil, sys, glob

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
I18N = os.path.join(ROOT, "i18n")
EN_TREE = os.path.join(ROOT, "en")
CYR = re.compile(r"[А-Яа-яЁё]")
CHUNK_CHARS = 30000


def sources():
    out = [os.path.join(ROOT, "main.gd")]
    out += sorted(glob.glob(os.path.join(ROOT, "scripts", "**", "*.gd"), recursive=True))
    out += sorted(glob.glob(os.path.join(ROOT, "data", "**", "*.dat"), recursive=True))
    return out


def sid(s):
    return hashlib.sha1(s.encode("utf-8")).hexdigest()[:12]


ESC_IN = {"n": "\n", "t": "\t", '"': '"', "\\": "\\", "'": "'", "r": "\r"}


def unescape(body):
    out = []
    i = 0
    while i < len(body):
        c = body[i]
        if c == "\\" and i + 1 < len(body):
            d = body[i + 1]
            if d == "u" and i + 5 < len(body):
                out.append(chr(int(body[i + 2:i + 6], 16))); i += 6; continue
            out.append(ESC_IN.get(d, "\\" + d)); i += 2; continue
        out.append(c); i += 1
    return "".join(out)


def escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\t", "\\t").replace("\r", "\\r")


def scan(text, is_gd):
    """-> список (start, end, raw_body) для строковых литералов "..." (комментарии # в .gd пропускаются)"""
    res = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if is_gd and c == "#":
            j = text.find("\n", i)
            i = n if j < 0 else j
            continue
        if c == '"' or (is_gd and c == "'"):
            q = c
            j = i + 1
            while j < n and text[j] != q:
                if text[j] == "\\":
                    j += 1
                elif text[j] == "\n" and q == "'":
                    break
                j += 1
            if q == '"':
                res.append((i, j + 1, text[i + 1:j]))
            i = j + 1
            continue
        i += 1
    return res


def collect():
    strs = {}
    where = {}
    for f in sources():
        text = open(f, encoding="utf-8").read()
        for a, b, raw in scan(text, f.endswith(".gd")):
            if not CYR.search(raw):
                continue
            s = unescape(raw)
            k = sid(s)
            strs[k] = s
            where.setdefault(k, os.path.relpath(f, ROOT))
    return strs, where


def load_tr():
    tr = {}
    files = sorted(glob.glob(os.path.join(I18N, "en", "*.json")))
    manual = [f for f in files if os.path.basename(f).startswith("00_")]
    for f in [x for x in files if x not in manual] + manual:
        try:
            d = json.load(open(f, encoding="utf-8"))
        except ValueError:
            print("пропущен (не JSON или пишется):", os.path.relpath(f, ROOT))
            continue
        tr.update({k: v for k, v in d.items() if isinstance(v, str)})
    return tr


FMT = re.compile(r"%[-+ 0#]*\d*(?:\.\d+)?[sdfxXcoeEgG%]")
BRACE = re.compile(r"\{[a-z_0-9]+\}")
TAG = re.compile(r"\[/?(?:b|i|u|s|color|url|font_size|center|right|indent|code|img|cell|table|bgcolor|outline_color|outline_size)(?:=[^\]]*)?\]")


def tag_norm(t):
    return re.sub(r"=.*\]", "=]", t)


def problems(ru, en):
    out = []
    if [m for m in FMT.findall(ru)] != [m for m in FMT.findall(en)]:
        out.append("форматы %s: %s -> %s" % ("", FMT.findall(ru), FMT.findall(en)))
    if sorted(BRACE.findall(ru)) != sorted(BRACE.findall(en)):
        out.append("подстановки {}: %s -> %s" % (BRACE.findall(ru), BRACE.findall(en)))
    if sorted(map(tag_norm, TAG.findall(ru))) != sorted(map(tag_norm, TAG.findall(en))):
        out.append("BBCode: %s -> %s" % (TAG.findall(ru), TAG.findall(en)))
    if ru.count("\n") != en.count("\n"):
        out.append("переводы строк %d -> %d" % (ru.count("\n"), en.count("\n")))
    if ru[:1] == " " and en[:1] != " " or ru[-1:] == " " and en[-1:] != " ":
        out.append("пробел по краям")
    if CYR.search(en):
        out.append("кириллица в переводе")
    return out


def cmd_extract():
    strs, where = collect()
    os.makedirs(I18N, exist_ok=True)
    json.dump(dict(sorted(strs.items())), open(os.path.join(I18N, "src.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=0)
    tr = load_tr()
    todo = [(k, s) for k, s in strs.items() if k not in tr]
    # порядок: по файлу, чтобы соседние строки (события одной страны) переводились вместе
    todo.sort(key=lambda kv: (where[kv[0]], kv[0]))
    tdir = os.path.join(I18N, "todo")
    shutil.rmtree(tdir, ignore_errors=True)
    os.makedirs(tdir)
    chunk, size, n = {}, 0, 0
    for k, s in todo:
        chunk[k] = s
        size += len(s)
        if size >= CHUNK_CHARS:
            json.dump(chunk, open(os.path.join(tdir, "chunk_%03d.json" % n), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
            chunk, size, n = {}, 0, n + 1
    if chunk:
        json.dump(chunk, open(os.path.join(tdir, "chunk_%03d.json" % n), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        n += 1
    print("строк %d (знаков %d), переведено %d, к переводу %d в %d файлах" % (len(strs), sum(map(len, strs.values())), len(strs) - len(todo), len(todo), n))


def cmd_check(verbose=True):
    strs, _ = collect()
    tr = load_tr()
    bad = {}
    for k, s in strs.items():
        if k in tr:
            p = problems(s, tr[k])
            if p:
                bad[k] = p
    if verbose:
        for k, p in list(bad.items())[:60]:
            print(k, "|", strs[k][:80].replace("\n", "⏎"), "|", "; ".join(p))
    print("строк %d, переведено %d, с ошибками %d" % (len(strs), sum(1 for k in strs if k in tr), len(bad)))
    return bad


def cmd_build():
    tr = load_tr()
    strs, _ = collect()
    bad = cmd_check(False)
    shutil.rmtree(EN_TREE, ignore_errors=True)
    miss = 0
    for f in sources():
        rel = os.path.relpath(f, ROOT)
        text = open(f, encoding="utf-8").read()
        is_gd = f.endswith(".gd")
        parts, last = [], 0
        for a, b, raw in scan(text, is_gd):
            if not CYR.search(raw):
                continue
            s = unescape(raw)
            k = sid(s)
            en = tr.get(k)
            if en is None or k in bad:
                miss += 1
                continue
            parts.append(text[last:a]); parts.append('"' + escape(en) + '"'); last = b
        parts.append(text[last:])
        out = "".join(parts)
        if is_gd:
            out = out.replace('"res://scripts/', '"res://en/scripts/').replace('"res://data/', '"res://en/data/').replace('"res://main.gd"', '"res://en/main.gd"')
        dst = os.path.join(EN_TREE, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        open(dst, "w", encoding="utf-8").write(out)
    shutil.copy(os.path.join(ROOT, "scripts", "CHAIN.txt"), os.path.join(EN_TREE, "scripts", "CHAIN.txt"))
    # тесты для английского дерева: те же сценарии, пути в en/
    for f in glob.glob(os.path.join(ROOT, "tests", "*.gd")):
        t = open(f, encoding="utf-8").read()
        t = t.replace('"res://scripts/', '"res://en/scripts/').replace('"res://main.gd"', '"res://en/main.gd"').replace('"res://data/', '"res://en/data/')
        dst = os.path.join(EN_TREE, "tests", os.path.basename(f))
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        open(dst, "w", encoding="utf-8").write(t)
    # Godot не должен видеть en/ как отдельный проект; .gdignore не ставим — скрипты должны грузиться
    print("en/ собрано; русских строк осталось (нет перевода или ошибка): %d из %d" % (miss, len(strs)))


def cmd_checkfile():
    """python3 tools/i18n.py checkfile i18n/todo/chunk_005.json i18n/en/chunk_005.json — проверка одного файла перевода"""
    src = json.load(open(sys.argv[2], encoding="utf-8"))
    dst = json.load(open(sys.argv[3], encoding="utf-8"))
    missing = [k for k in src if k not in dst]
    extra = [k for k in dst if k not in src]
    bad = 0
    for k, ru in src.items():
        if k in dst:
            p = problems(ru, dst[k])
            if p:
                bad += 1
                print(k, "|", ru[:70].replace("\n", "⏎"), "|", "; ".join(p))
    print("всего %d, нет перевода %d, лишних id %d, с ошибками %d" % (len(src), len(missing), len(extra), bad))
    if missing:
        print("нет перевода:", " ".join(missing[:30]))
    sys.exit(1 if (missing or bad) else 0)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"
    {"extract": cmd_extract, "check": cmd_check, "build": cmd_build, "checkfile": cmd_checkfile}[cmd]()
