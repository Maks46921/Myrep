#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""v55_3: отчёт большого теста (tests/t_big.gd) — одна HTML-страница со скриншотами.

Читает .testlogs/big/<язык>_<страна>/{ui,mech,bal}.json и скриншоты, сверку с реальностью docs/reality/XX.md
и заметки версии docs/reality/notes.json (что исправлено, предложения, статусы строк сверки).
Пишет <out>/index.html (для публикации — без <html>/<body>), <out>/report.html (открыть локально) и <out>/img/*.jpg.

  python3 tools/big_report.py [--logs .testlogs/big] [--out .testlogs/big_report] [--version v55_3]
"""
import argparse
import html
import json
import os
import re
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COUNTRY_RU = {"DE": "Германия", "FR": "Франция", "GB": "Великобритания", "PL": "Польша", "UA": "Украина", "RU": "Россия"}
ORDER = ["DE", "FR", "GB", "PL", "UA", "RU"]


def load(p, dflt=None):
    try:
        with open(p, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return dflt


# ---------- markdown → html (только то, что встречается в отчётах сверки) ----------
URL = re.compile(r"https?://[^\s<>()|,;]+[^\s<>()|,;.»]")


def md_inline(s):
    s = html.escape(s.strip(), quote=False)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", s)
    s = URL.sub(lambda m: '<a href="%s" target="_blank" rel="noopener">%s</a>' % (m.group(0), short_url(m.group(0))), s)
    return s


def short_url(u):
    u = re.sub(r"^https?://(www\.)?", "", u)
    host, _, rest = u.partition("/")
    return host + ("/…" if rest else "")


def md_table(md, section_no):
    """Первая таблица в разделе «## N.»: (заголовки, строки)."""
    lines = md.splitlines()
    inside = False
    rows = []
    for ln in lines:
        if ln.startswith("## "):
            inside = ln.startswith("## %d." % section_no)
            continue
        if inside and ln.startswith("|"):
            cells = [c for c in ln.strip().strip("|").split("|")]
            if all(re.fullmatch(r"\s*:?-{2,}:?\s*", c) for c in cells):
                continue
            rows.append([c.strip() for c in cells])
    if not rows:
        return [], []
    return rows[0], rows[1:]


def md_section(md, section_no):
    out = []
    inside = False
    for ln in md.splitlines():
        if ln.startswith("## "):
            inside = ln.startswith("## %d." % section_no)
            continue
        if inside:
            out.append(ln)
    return "\n".join(out).strip()


def md_block(text):
    """Списки и абзацы."""
    out = []
    lst = []
    for ln in text.splitlines():
        m = re.match(r"^\s*(?:[-*]|\d+\.)\s+(.*)", ln)
        if m:
            lst.append("<li>%s</li>" % md_inline(m.group(1)))
            continue
        if lst:
            out.append("<ul>%s</ul>" % "".join(lst))
            lst = []
        if ln.strip():
            out.append("<p>%s</p>" % md_inline(ln))
    if lst:
        out.append("<ul>%s</ul>" % "".join(lst))
    return "\n".join(out)


def real_status(cc, area, typ, overrides):
    for o in overrides:
        if o["cc"] == cc and o["match"] in area:
            return o["status"], o.get("note", "")
    t = typ.lower()
    if t.startswith("ошибка данных"):
        return "fixed", ""
    if t.startswith("дизайн"):
        return "design", ""
    if t.startswith("упрощение"):
        return "proposal", ""
    return "kept", ""


def build_reality(real_dir, notes):
    out = []
    overrides = notes.get("real_status", [])
    for cc in ORDER:
        p = os.path.join(real_dir, cc + ".md")
        if not os.path.exists(p):
            continue
        md = open(p, encoding="utf-8").read()
        head, rows = md_table(md, 1)
        hl = [h.lower() for h in head]

        def col(row, *names):
            for n in names:
                for i, h in enumerate(hl):
                    if h.startswith(n) and i < len(row):
                        return row[i]
            return ""
        items = []
        for r in rows:
            area = col(r, "область", "что", "тема")
            game = col(r, "в игре")
            life = col(r, "в жизни")
            src = col(r, "источник")
            typ = col(r, "тип")
            imp = col(r, "важность")
            if not area and len(r) > 1:
                area = r[1] if hl and hl[0] == "#" else r[0]
            st, note = real_status(cc, area + " " + game, typ, overrides)
            items.append({"area": md_inline(area), "game": md_inline(game), "life": md_inline(life), "src": md_inline(src),
                          "type": html.escape(typ), "imp": html.escape(imp), "st": st, "note": html.escape(note)})
        title = md.splitlines()[0].lstrip("# ").strip()
        ok = md_section(md, 4)
        out.append({"cc": cc, "title": title, "rows": items, "ok": md_block(ok)})
    return out


# ---------- скриншоты ----------
KEY_EN = {"d00", "d01", "d02", "d03", "d05", "d06", "d11", "d13", "d15", "d18", "d19", "event1", "election", "crisis2", "war_d13", "tech"}
MAP_FEW = {"map00", "map05", "map12"}


def pick_shot(name, lang, cc, full_maps_cc):
    base = name[:-4]
    if lang == "en":
        return base in KEY_EN
    if base.startswith("map"):
        return cc == full_maps_cc or base in MAP_FEW
    return True


def convert(src, dst, width=1100):
    if os.path.exists(dst) and os.path.getmtime(dst) >= os.path.getmtime(src):
        return
    im = Image.open(src).convert("RGB")
    if im.width > width:
        im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    im.save(dst, "JPEG", quality=56, optimize=True, progressive=True)


DESK = {0: "Бюджет", 1: "Политика → Парламент", 2: "Карта → Карта", 3: "Политика → Законы", 4: "Политика → Правительство",
        5: "Экономика → Рынки и финансы", 6: "Политика → Население", 7: "Экономика → Товары и цены", 8: "Карта → Регионы и автономия",
        9: "Карта → Территории", 10: "Экономика → Влияние и зависимость", 11: "Общество → Религия и миграция",
        12: "Политика → Оппозиция и сделки", 13: "Карта → Армия и война", 14: "Карта → Флот", 15: "Карта → Вооружённые силы",
        16: "Экономика → пульт экономической модели", 17: "Экономика → Корпорации", 18: "Организации",
        19: "Общество → Культура", 20: "Общество → Церковь и государство"}


def desk_name(s):
    return re.sub(r"экран (\d+)", lambda m: DESK.get(int(m.group(1)), m.group(0)), s)


SHOT_NAMES = {"tech": "Технологии", "crisis": "Кризисы", "crisis2": "Кризис: волнения в 5 регионах", "election": "Окно выборов",
              "event1": "Окно события 1", "event2": "Окно события 2", "event3": "Окно события 3"}


def shot_title(base, where):
    if base in SHOT_NAMES:
        return SHOT_NAMES[base]
    if base.startswith("war_d"):
        return "Война: " + DESK.get(int(base[5:]), base)
    if base.startswith("w_"):
        return "Окно по запросу: " + base[2:]
    if base.startswith("map"):
        return "Слой карты %d" % int(base[3:])
    if base.startswith("d") and base[1:].isdigit():
        return DESK.get(int(base[1:]), base)
    return where or base


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--logs", default=os.path.join(ROOT, ".testlogs", "big"))
    ap.add_argument("--out", default=os.path.join(ROOT, ".testlogs", "big_report"))
    ap.add_argument("--real", default=os.path.join(ROOT, "docs", "reality"))
    ap.add_argument("--version", default="v55_3")
    ap.add_argument("--maps", default="DE", help="страна, для которой в отчёт идут все слои карты")
    a = ap.parse_args()
    notes = load(os.path.join(a.real, "notes.json"), {}) or {}
    os.makedirs(os.path.join(a.out, "img"), exist_ok=True)

    runs = []
    finds = []
    trims = []
    shots = []
    bal = {}
    for lang in ["ru", "en"]:
        for cc in ORDER:
            d = os.path.join(a.logs, "%s_%s" % (lang, cc))
            if not os.path.isdir(d):
                continue
            run = {"cc": cc, "lang": lang, "parts": {}}
            for part in ["ui", "mech", "bal"]:
                j = load(os.path.join(d, part + ".json"))
                if j is None:
                    continue
                run["parts"][part] = {"bad": j.get("bad", 0), "finds": len(j.get("finds", [])),
                                      "stats": {k: v for k, v in (j.get("stats") or {}).items() if k != "rows"}}
                for f in j.get("finds", []):
                    finds.append({"cc": cc, "lang": lang, "part": part, "cat": f.get("cat", ""), "where": desk_name(f.get("where", "")), "t": f.get("t", "")})
                for t in j.get("trims", []):
                    trims.append({"cc": cc, "lang": lang, "where": desk_name(t.get("where", "")), "t": t.get("t", "")})
                if part == "bal":
                    bal["%s_%s" % (lang, cc)] = (j.get("stats") or {}).get("rows") or load(os.path.join(d, "bal_rows.json"), [])
                for s in j.get("shots", []):
                    nm = s["f"]
                    if not pick_shot(nm, lang, cc, a.maps):
                        continue
                    src = os.path.join(d, nm)
                    if not os.path.exists(src):
                        continue
                    out_nm = "%s_%s_%s.jpg" % (lang, cc, nm[:-4])
                    convert(src, os.path.join(a.out, "img", out_nm))
                    shots.append({"cc": cc, "lang": lang, "f": "img/" + out_nm, "title": shot_title(nm[:-4], s.get("where", "")), "where": desk_name(s.get("where", ""))})
            runs.append(run)
    if not runs:
        print("нет результатов в", a.logs)
        return 1

    data = {
        "version": a.version,
        "runs": runs,
        "finds": finds,
        "trims": trims,
        "shots": shots,
        "bal": bal,
        "countries": {cc: COUNTRY_RU[cc] for cc in ORDER},
        "reality": build_reality(a.real, notes),
        "fixed": [md_inline(x) for x in notes.get("fixed", [])],
        "proposals": [{"t": md_inline(p["t"]), "d": md_inline(p.get("d", "")), "cc": p.get("cc", "")} for p in notes.get("proposals", [])],
        "done_props": [md_inline(x) for x in notes.get("done_props", [])],
        "date": notes.get("date", ""),
    }
    tpl = open(os.path.join(ROOT, "tools", "big_report.html"), encoding="utf-8").read()
    js = json.dumps(data, ensure_ascii=False).replace("</", "<\\/")
    page = tpl.replace("/*DATA*/null", js).replace("{{VERSION}}", a.version)
    with open(os.path.join(a.out, "index.html"), "w", encoding="utf-8") as f:
        f.write(page)
    with open(os.path.join(a.out, "report.html"), "w", encoding="utf-8") as f:
        f.write("<!doctype html>\n<html lang=\"ru\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"></head><body>\n" + page + "\n</body></html>\n")
    size = sum(os.path.getsize(os.path.join(a.out, "img", x)) for x in os.listdir(os.path.join(a.out, "img")))
    print("отчёт: %s (прогонов %d, находок %d, скриншотов %d, %.1f МБ)" % (os.path.join(a.out, "index.html"), len(runs), len(finds), len(shots), size / 1e6))
    return 0


if __name__ == "__main__":
    sys.exit(main())
