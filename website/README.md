# Сайт Symphony

Статический сайт об игре: описание, механики, список обновлений, скриншоты. Без сервера: `index.html` и картинки в `img/`.

Посмотреть локально: открыть `website/index.html` в браузере.

## Обновления на сайте появляются сами

Раздел «Обновления» и номер версии в шапке собираются из `UPDATES.md` скриптом `website/build_updates.py`.
Достаточно дописать в `UPDATES.md` новый блок в том же виде:

```
## v53_1 — Название версии
- **Что-то новое:** описание.
  - вложенный пункт
```

После пуша в основную ветку GitHub Actions (`.github/workflows/site.yml`) пересоберёт раздел и выложит сайт на Netlify: https://symphony-game.netlify.app.
Нужно один раз добавить секрет репозитория `NETLIFY_AUTH_TOKEN` (Netlify → User settings → Applications → Personal access tokens).

Собрать вручную: `python3 website/build_updates.py` (из корня репозитория).

Скриншоты сняты из игры (Godot 4.3, xvfb) на 1600 px по ширине в формате WebP.

## Раздел «Страны»

Карта, досье и флаги 38 стран берутся прямо из игры и лежат в `countries.js` и `img/flags/`. Если в игре поменялись данные стран, пересоберите их так (из корня репозитория):

```
xvfb-run -a godot --rendering-driver opengl3 --path . --script website/tools/export_countries.gd -- out=/tmp/sym
python3 website/tools/build_countries.py /tmp/sym
```

Первый шаг выгружает данные и флаги из Godot, второй собирает `countries.js` (контуры регионов берёт из `data/world_units.dat`) и `img/flags/*.webp`.
Файл `website/.gdignore` нужен, чтобы Godot не импортировал картинки сайта как ресурсы игры.
Кадры в `img/crop/` вырезаны из полных скриншотов, полные по-прежнему открываются по клику.
