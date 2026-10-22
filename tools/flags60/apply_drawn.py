#!/usr/bin/env python3
"""0.60: подмена картинок флагов нарисованными кодом (папка flags_drawn): тот же id, имя, годы и идеологии остаются.
Запуск: python3 tools/flags60/apply_drawn.py ID,ID,... [каталог]   (без списка id ничего не делает)
Записи, уже заменённые настоящими флагами (поле lic), пропускаются."""
import json, os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
from import_flags import clean_svg, viewbox, DAT

SRC = "/mnt/project-files/symphony/flags_drawn"


def main():
    ids = set((sys.argv[1] if len(sys.argv) > 1 else "").split(","))
    src = sys.argv[2] if len(sys.argv) > 2 else SRC
    idx = json.load(open(os.path.join(src, "index.json"), encoding="utf8"))
    db = json.load(open(DAT, encoding="utf8"))
    n = 0
    for r in idx:
        if r["id"] not in ids:
            continue
        ent = [e for e in db.get(r["cc"], []) if e["id"] == r["id"]]
        if not ent:
            print("нет записи", r["id"])
            continue
        e = ent[0]
        if "lic" in e:
            print("уже настоящий флаг, пропуск", r["id"])
            continue
        svg = clean_svg(open(os.path.join(src, r["file"]), encoding="utf8").read())
        svg = re.sub(r"\sxmlns:c2pa=\"[^\"]*\"", "", svg)
        if viewbox(svg) is None or "<image" in svg or "<text" in svg:
            print("непригоден", r["id"])
            continue
        e["svg"] = svg
        e["w"] = int(round(float(r["w"])))
        n += 1
    json.dump(db, open(DAT, "w", encoding="utf8"), ensure_ascii=False, separators=(",", ":"))
    print("заменено", n)


if __name__ == "__main__":
    main()
