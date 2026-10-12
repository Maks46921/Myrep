#!/usr/bin/env python3
"""Собирает раздел «Обновления» сайта из UPDATES.md.

Запуск из корня репозитория: python3 website/build_updates.py
Берёт каждый заголовок «## vNN_N — Название» и его пункты «- ...» (вложенные «  - ...» тоже),
вставляет ленту версий в website/index.html между метками updates:start / updates:end
и подставляет последнюю версию во все элементы с атрибутом data-ver.
"""
import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "UPDATES.md"
PAGE = ROOT / "website" / "index.html"
OPEN_LATEST = 2  # сколько свежих версий показывать раскрытыми


def inline(md: str) -> str:
    t = html.escape(md.strip(), quote=False)
    t = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", t)
    t = re.sub(r"`(.+?)`", r"\1", t)
    return t


def parse(text: str) -> list:
    versions = []
    cur = None
    for line in text.splitlines():
        m = re.match(r"^##\s+(v\d+_\d+)\s*[—–-]\s*(.+?)\s*$", line)
        if m:
            cur = {"v": m.group(1), "title": m.group(2), "items": []}
            versions.append(cur)
            continue
        if line.startswith("#") or line.strip() == "---":
            cur = None if line.startswith("#") else cur
            continue
        if cur is None:
            continue
        m = re.match(r"^(\s*)[-*]\s+(.*)$", line)
        if not m:
            continue
        if len(m.group(1)) >= 2 and cur["items"]:
            cur["items"][-1]["sub"].append(m.group(2))
        else:
            cur["items"].append({"text": m.group(2), "sub": []})
    versions.sort(key=lambda x: tuple(int(n) for n in re.findall(r"\d+", x["v"])), reverse=True)
    return versions


def render(versions: list) -> str:
    out = []
    for i, ver in enumerate(versions):
        items = []
        for it in ver["items"]:
            sub = ""
            if it["sub"]:
                sub = "<ul>" + "".join("<li>%s</li>" % inline(x) for x in it["sub"]) + "</ul>"
            items.append("<li>%s%s</li>" % (inline(it["text"]), sub))
        badge = ' <span class="badge">сейчас</span>' if i == 0 else ""
        out.append(
            '      <div class="rel%s"><span class="v">%s</span><span class="dot"></span>\n'
            '        <details%s><summary><h3>%s%s</h3></summary>\n'
            '          <div class="body"><ul>%s</ul></div>\n'
            "        </details>\n"
            "      </div>"
            % (" new" if i == 0 else "", ver["v"], " open" if i < OPEN_LATEST else "",
               inline(ver["title"]), badge, "".join(items))
        )
    return "\n".join(out)


def main() -> int:
    versions = parse(SRC.read_text(encoding="utf-8"))
    if not versions:
        print("В UPDATES.md не найдено ни одной версии вида «## vNN_N — Название»", file=sys.stderr)
        return 1
    page = PAGE.read_text(encoding="utf-8")
    start = re.search(r"<!-- updates:start[^>]*-->", page)
    end = page.find("<!-- updates:end -->")
    if not start or end < 0:
        print("В website/index.html нет меток updates:start / updates:end", file=sys.stderr)
        return 1
    page = page[: start.end()] + "\n" + render(versions) + "\n" + page[end:]
    latest = versions[0]["v"]
    page = re.sub(r"(<[^>]*\bdata-ver\b[^>]*>)v\d+_\d+(<)", r"\g<1>%s\2" % latest, page)
    PAGE.write_text(page, encoding="utf-8")
    print("Версий на сайте: %d, последняя: %s" % (len(versions), latest))
    return 0


if __name__ == "__main__":
    sys.exit(main())
