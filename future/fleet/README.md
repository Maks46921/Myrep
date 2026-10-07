# Флот и морская торговля (отложено в v31)

Убрано из игры по просьбе автора. Код рабочий (в v30 прошёл тесты на 17 странах).

Вернуть:
1. Скопировать файлы по тем же путям: `scripts/fleet.gd` → `scripts/logic/fleet.gd`, `scripts/ui_fleet.gd` → `scripts/ui/ui_fleet.gd`, `scripts/fleet_map.gd` → `scripts/classes/`, `data/fleet.dat` → `data/`, `tests/t_fleet.gd` → `tests/`, `tools/gen_fleet.py` → `tools/` (данные: `python3 tools/gen_fleet.py`).
2. CHAIN.txt: `scripts/logic/fleet.gd` между influence.gd и radical.gd; `scripts/ui/ui_fleet.gd` после ui_soc.gd. Поправить `extends` у radical.gd (на fleet.gd) и main.gd (на ui_fleet.gd).
3. turn.gd: `fleet_day()` в `day_tick`, `+ fleet_g()` в приросте ВВП, `+ fleet_infl()` в инфляции (macro_step), `fleet_month()` в next_turn, `fleet_init()` в начале игры.
4. events.gd: в `choose()` после `nocon` — `elif special == "fleet": fleet_resolve(i)`.
5. ui_core.gd: `build_fleet_windows()` в build_ui, `update_fleet_windows()` для desk 12, четвёртая кнопка подпанели экономики (страница 12, значок «ship» уже есть в ico.gd), `accent_for_desk(12)`.
6. `python3 tools/stubs.py`, добавить тест `fleet` в tools/test.py.
