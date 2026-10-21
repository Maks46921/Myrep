#!/usr/bin/env python3
"""0.60: импорт свободных флагов с Викисклада в data/flags.dat.

Вход: <src>/index.json — список записей
  {cc, file, name, lic, author, url, y0, y1, regime, ideo, note}
и файлы SVG по путям file (от каталога src).
Допустимые лицензии: PD, CC0, CC BY, CC BY-SA.
Запись с тем же cc и y1, что у уже имеющейся, заменяет её картинку (id сохраняется, чтобы не ломать сейвы);
остальные добавляются как <CC>-c<n>. Результат — data/flags.dat и tools/flags60/credits.gd.txt (не нужен: окно читает поля lic/author/url).

Запуск: python3 tools/flags60/import_flags.py [каталог_src] [--dry]
"""
import json, re, sys, os

SRC = "/mnt/project-files/symphony/flags_src"
DAT = os.path.join(os.path.dirname(__file__), "..", "..", "data", "flags.dat")
OK_LIC = {"PD": "PD", "PUBLIC DOMAIN": "PD", "CC0": "CC0", "CC BY": "CC BY", "CC-BY": "CC BY",
          "CC BY-SA": "CC BY-SA", "CC-BY-SA": "CC BY-SA"}
MAXB = 150 * 1024
H = 60


def lic_norm(s):
    s = re.sub(r"\s+[0-9.]+(\s+\w+)?$", "", str(s).strip().upper().replace("_", " "))
    s = s.replace("CC BY SA", "CC BY-SA")
    return OK_LIC.get(s)


def clean_svg(txt):
    """Оставляет только то, что рисует Godot: убирает пролог, комментарии, метаданные, скрипты, текст и внешние ссылки."""
    txt = re.sub(r"<\?xml[^>]*\?>", "", txt)
    txt = re.sub(r"<!DOCTYPE[^>]*>", "", txt)
    txt = re.sub(r"<!--.*?-->", "", txt, flags=re.S)
    txt = re.sub(r"<metadata.*?</metadata>", "", txt, flags=re.S)
    txt = re.sub(r"<(sodipodi|inkscape|rdf|cc|dc):[^>]*?/>", "", txt)
    txt = re.sub(r"<(sodipodi|inkscape|rdf|cc|dc):[^>]*?>.*?</\1:[^>]*?>", "", txt, flags=re.S)
    txt = re.sub(r"\s(inkscape|sodipodi):[\w-]+=\"[^\"]*\"", "", txt)
    txt = re.sub(r"<script.*?</script>", "", txt, flags=re.S)
    txt = re.sub(r">\s+<", "><", txt.strip())
    return txt


def viewbox(txt):
    m = re.search(r"<svg[^>]*\sviewBox=\"([^\"]+)\"", txt)
    if m:
        v = [float(x) for x in re.split(r"[ ,]+", m.group(1).strip())]
        if len(v) == 4 and v[2] > 0 and v[3] > 0:
            return v
    w = re.search(r"<svg[^>]*\swidth=\"([0-9.]+)", txt)
    h = re.search(r"<svg[^>]*\sheight=\"([0-9.]+)", txt)
    if w and h:
        return [0, 0, float(w.group(1)), float(h.group(1))]
    return None


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    src = args[0] if args else SRC
    dry = "--dry" in sys.argv
    idx = json.load(open(os.path.join(src, "index.json"), encoding="utf8"))
    if isinstance(idx, dict):
        idx = idx.get("flags") or idx.get("items") or list(idx.values())
    db = json.load(open(DAT, encoding="utf8"))
    stat = {"replaced": 0, "added": 0, "skip_lic": 0, "skip_svg": 0, "skip_dup": 0}
    for r in idx:
        cc = r.get("cc")
        lic = lic_norm(r.get("lic", ""))
        if cc not in db or lic is None:
            stat["skip_lic"] += 1
            print("пропуск (лицензия/страна):", cc, r.get("name"), r.get("lic"))
            continue
        p = os.path.join(src, r["file"])
        if not os.path.isfile(p) or os.path.getsize(p) > MAXB:
            stat["skip_svg"] += 1
            print("пропуск (файл):", cc, r.get("file"))
            continue
        svg = clean_svg(open(p, encoding="utf8", errors="replace").read())
        vb = viewbox(svg)
        if vb is None or "<image" in svg or "<text" in svg or "<foreignObject" in svg or "xlink:href=\"http" in svg:
            stat["skip_svg"] += 1
            print("пропуск (svg непригоден):", cc, r.get("file"))
            continue
        w = int(round(H * vb[2] / vb[3]))
        w = max(30, min(w, 120))
        y0, y1 = int(r.get("y0") or 0), int(r.get("y1") or 0)
        ent = {"w": w, "svg": svg, "regime": r.get("regime", ""), "ideo": list(r.get("ideo") or []),
               "y0": y0, "y1": y1, "name": r.get("name", ""), "src": "Викисклад",
               "note": r.get("note", ""), "lic": lic, "author": r.get("author", ""), "url": r.get("url", "")}
        same = [e for e in db[cc] if int(e["y1"]) == y1 and "lic" not in e and not e.get("_hit")]
        if any(e.get("url") == ent["url"] and ent["url"] for e in db[cc]):
            stat["skip_dup"] += 1
            continue
        if same:
            # заменяем картинку, сохраняя id, названия, годы и идеологии, подобранные раньше
            old = same[0]
            for k in ("svg", "w", "lic", "author", "url"):
                old[k] = ent[k]
            old["src"] = "Викисклад"
            old["_hit"] = True
            stat["replaced"] += 1
        else:
            n = 1 + sum(1 for e in db[cc] if str(e["id"]).startswith(cc + "-c"))
            ent["id"] = "%s-c%d" % (cc, n)
            db[cc].append(ent)
            stat["added"] += 1
    print(stat)
    for cc in db:
        for e in db[cc]:
            e.pop("_hit", None)
    if not dry:
        json.dump(db, open(DAT, "w", encoding="utf8"), ensure_ascii=False, separators=(",", ":"))
        print("записано", DAT)


if __name__ == "__main__":
    main()
