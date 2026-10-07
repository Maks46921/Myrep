# Карта проекта (создаётся автоматически: `python3 tools/mapdoc.py`)

Скрипты игры образуют **цепочку наследования**: каждый файл `extends` предыдущий, вершина — `main.gd`. Порядок — в `scripts/CHAIN.txt`. Поэтому любая функция доступна из любого модуля; если модуль вызывает функцию из модуля ниже по цепочке, нужна «заглушка» — её создаёт `tools/stubs.py`.

## Цепочка

### `scripts/data/data_core.gd`  (1065 строк)
Справочные таблицы игры: группы, политика, уровни, рынки, цвета и т.п. (только const).

Константы (133): `StatBar`, `ElectionView`, `HeadView`, `FloatWindow`, `MarketBar`, `EconChart`, `AgentPop`, `AgentMapView`, `AgentHistView`, `GoodsView`, `CountryMap`, `START_YEAR`, `MONTHS`, `COALITION_JOIN`, `COALITION_JOIN_PAID`, `COALITION_LEAVE`, `CONCESSION_COST`, `COL_GOOD`, `COL_BAD`, `COL_NEUTRAL`, `COL_HEAD`, `COL_WARN`, `COL_ELECT`, `COL_PURPLE`, `COL_TEAL`, `COL_DIM`, `COL_FAINT_HEX`, `C_BG`, `C_PANEL`, `C_PANEL2`, `C_BORDER`, `C_TEXT`, `C_DIM`, `C_FAINT`, `C_ACCENT`, `C_GOOD`, `C_WARN`, `C_BAD`, `C_PURPLE`, `C_TEAL`, `REV_COLORS`, `EXP_COLORS`, `GROUPS`, `GROUP_FX`, `EXPECT_DRIFT`, `LEVELS`, `LEVEL_RATE`, `STATE_NAMES`, `LEVEL_EFFECTS`, `MIN_FX_SCALE`, `SAT_OFFSET`, `SAT_FATIGUE`, `SAT_FATIGUE_CAP`, `COAL_EVENTS`, `SAT_LEAVE`, `REG_KEYS`, `REG_TITLES`, `SECTOR_NAMES`, `GOV_KINDS`, `GOV_DESC`, `MAP_LAYERS`, `MAP_LEGENDS`, `MARKET_COLORS`, `GOOD_PROF`, `AG_GK`, `STRUCT_CATS`, `FOCUS_NAMES`, `FOCUS_IDS`, `RATE_NEUTRAL_REAL`, `PROJECTS`, `ECON_FX_INFO`, `ECON_EVENTS`, `ECON_MEASURES`, `REGION_ACTIONS`, `LAW_CATS`, `LAW_CAT_COLORS`, `PRES_RULE_NAMES`, `MOD_INFO`, `MEASURES_BASE`, `ACTIONS`, `NEWS`, `AG_STRIDE`, `AG_POLL_N`, `AG_ZK`, `HIST_KEYS`, `EC_CHART_NAMES`, `EC_CHART_COLORS`, `FUND_IDS`, `DEM_LAW`, `LAW_PARAMS_V11`, `PARAM_DEMANDS`, `DEM_BASE`, `LOG_FILTERS`, `LOG_FILTER_CATS`, `LOG_CAT_COL`, `LOG_CAT_NAME`, `LOG_TAG_CAT`, `LOG_POL_WORDS`, `LOG_ECO_WORDS`, `AP_STYLES`, `AP_STYLE_TIPS`, `PRESETS`, `AP_BUILD_MAP`, `DIP_TRACKS`, `DIP_ACTIONS`, `DIP_LAYERS`, `DIP_REL_NAMES`, `DIP_EVENTS`, `DIP_SUMMITS`, `W_OPEN`, `W_KINDS`, `EMIT_MAX`, `RAD_MONARCHIES`, `RAD_AUTH`, `RAD_CUR`, `RAD_AUTH_TOPICS`, `RAD_MARKET_TOPICS`, `RSEC`, `SEC_COLORS`, `REG_TOOLS`, `REG_EVENTS_GEN`, `REG_EVENTS_CC`, `ELEC_DATA`, `WORLD`, `WORLD_PCOL`, `WORLD_CCOL`, `WORLD_OPEN`, `WORLD_STANCE0`, `WORLD_TRADE`, `WORLD_REL`, `WORLD_LV0`, `WORLD_CTX`, `WORLD_CAPS`

### `scripts/data/data_content.gd`  (835 строк)
Крупные таблицы контента: события, законы, радикальные законы, карта мира.

Константы (5): `LAW_TOPICS_BASE`, `EVENTS`, `NEW_TOPICS`, `RAD_EVENTS`, `WORLD_UNITS`

### `scripts/data/data_countries.gd`  (2339 строк)
Пакеты данных стран (генерируются tools/gen_data из Python-описаний).

Константы (1): `CDATA`

### `scripts/state/state_data.gd`  (576 строк)
Таблицы, которые страна подменяет при запуске (REGIONS, LEAN, PARTY_NAMES и др.).

Переменные (66): `SEATS`, `MAJORITY`, `POLICY`, `GROUP_WEIGHT`, `GROUP_BASE`, `PARTY_NAMES`, `PARTY_DESC`, `PARTY_COLORS`, `LEAN`, `HEMI_ORDER`, `PARTY_LEADERS`, `PARTY_DEMANDS`, `MINISTRIES`, `PARTY_MINISTRIES`, `MIN_SPECIAL`, `PARTY_TRAITS`, `PARTY_LAW_DEMAND`, `MINISTER_NAMES`, `GOV_NAMES`, `REGIONS`, `REG_BIAS`, `MARKETS`, `BASE_MODS`, `LAW_TOPICS`, `MEASURES`, `TERMS`, `INFO`, `UPPER`, `MACRO`, `REGIONAL_P`, `MARKETS_OVR`, `GOODS`, `GOODS_OVR`, `COALITION0`, `LAW_TAGS`, `PARCH`, `EVENTS_C`, `NEWS_C`, `EVENTS_SPECIAL`, `ARCHS`, `ELEC`, `AG`, `LOC_RULES`, `TOLERATE_W`, `SUPER`, `GDP0`, `G_POT`, `G_NEU`, `I_NEU`, `I_TGT`, `U_NEU`, `OTHER0`, `RATE0`, `DE_START_SEATS`, `DE_START_MIN`, `DE_PARAM`, `DE_NEW_PARAMS`, `DE_REMOVE`, `DE_FUND_ADD`, `DE_TOPICS` …

### `scripts/state/state.gd`  (684 строк)
Текущее состояние партии: показатели, законы, парламент, узлы интерфейса.

Переменные (340): `pending_code`, `ccode`, `map_reg_pick`, `emit_note`, `risk_prem`, `minority_ok`, `turn`, `year`, `month`, `gdp`, `debt`, `growth`, `inflation`, `unemployment`, `shock`, `other_rev`, `pol`, `pol_def`, `prev_pol`, `policy_by_key`, `lvl`, `support`, `bias`, `mods`, `cooldown`, `capital`, `seats`, `in_coalition`, `warned`, `crisis_months`, `impeach_warned`, `last_parl`, `last_pres`, `pres_due`, `pres_camp`, `pres_camp_done`, `pres_party`, `hemi_rad`, `el_head`, `game_over`, `current_event`, `event_region`, `prev_items`, `year_start`, `charisma`, `satis`, `joined`, `conc`, `ministries`, `selected_party`, `last_nocon`, `pop_w`, `gdp_w`, `neighbors`, `auto0`, `pol_abs`, `pol_abs_mode`, `locks`, `slider_busy`, `growth_ema` …

### `scripts/logic/util.gd`  (299 строк)
Мелкие помощники: перевод, форматирование, цвета, даты.

Функции (38): `tm`, `cap1`, `low1`, `build_loc`, `loc`, `loc_tree`, `jag_edge`, `sg`, `col_delta`, `find_by_id`, `policy_title`, `sat`, `mrate`, `years_passed`, `date_text`, `turn_date`, `months_text`, `date_after`, `stat_color`, `total_pop`, `pop_ratio`, `amt`, `std_index`, `fx_col`, `sbox`, `make_dot_tex`, `scale_color`, `fmt_n`, `months_short`, `arrow_text`, `delta_col`, `col_signed`, `bit_text`, `good_col`, `hint_line`, `fmt_sg`, `date_short`, `polygon_area`

### `scripts/logic/policy.gd`  (841 строк)
Бюджетная политика: ползунки, блокировки, уровни, эффекты, моды законов.

Функции (82): `add_commitment`, `apply_econ`, `apply_psat`, `dip_all`, `dip_apply_mods`, `dip_fx_apply`, `dip_fx_text`, `ec_budget_lines`, `fulfill_coalition_demands`, `good_name`, `goods_support_term`, `ministry_fx`, `mk_def`, `new_minister`, `radical_dyn`, `radical_roll`, `reg_avg`, `reg_zones_end`, `sec_idx`, `slider_value_for`, `sync_ministers`, `transfer_avg`, `update_slider_label`, `variant_of`, `world_help`, `approval`, `add_support`, `add_all_support`, `set_policy`, `apply_reg_delta`, `describe_reg`, `region_support`, `expected`, `factor`, `fatigue`, `target_support`, `budget_changes`, `describe_fx`, `apply_fx`, `compute_budget`, `update_levels`, `pp0`, `expected_pp`, `is_abs`, `abs_range`, `sync_abs_policies`, `lock_active`, `add_lock`, `lock_allowed`, `lock_allowed_share`, `lock_until_text`, `lock_note`, `expire_locks`, `emit_cap`, `sync_emit`, `emit_safe_pct`, `emit_excess`, `lvl_sum`, `issue_multiplier`, `regional_potential`, `per_capita`, `avg_per_capita`, `tier_name`, `dev_gain_mult`, `tax_ratio`, `project_cost_pct`, `roi_estimate`, `roi_text`, `effective_reg`, `demand_cur`, `init_laws`, `parl_term`, `pres_term`, `impeach_seats`, `crisis_limit`, `compute_mods`, `recompute_mods`, `scale_fx`, `mod_good_dir`, `boost_good`, `describe_econ`, `debt_rate`

### `scripts/logic/laws.gd`  (892 строк)
Законы: варианты, голосование, числовые законы, меры и действия.

Функции (55): `hold_parliament`, `law_locked`, `log_line`, `log_tag`, `party_stance`, `radical_bypass`, `radical_enact`, `radical_req`, `refresh`, `rid_of`, `do_measure`, `do_action`, `level_effects_text`, `fx_items`, `reg_item`, `fx_pros_cons`, `layer_ramp`, `level_effect_list`, `variant_of`, `variant_part`, `cur_idx`, `law_cost`, `dict_diff`, `support_delta`, `variant_stance`, `variant_votes`, `upper_check`, `upper_text`, `negotiate_variant`, `adopt_variant`, `mod_item`, `variant_effect_items`, `items_pros_cons`, `pres_needs_runoff`, `law_reform_count`, `law_demand_of`, `law_demand_met`, `law_demand_text`, `fmt_param`, `param_grid`, `make_param_topic`, `build_law_topics`, `is_fund`, `law_need`, `demand_idx`, `demand_dict_met`, `param_scale_text`, `variant_swing`, `de_law_params`, `de_fix_ps`, `de_adapt_topics`, `brake_allowed`, `brake_active`, `brake_step`, `brake_text`

### `scripts/logic/goods.gd`  (157 строк)
Товары: потребительская корзина (18 видов), их цены и спрос, корзины групп населения.

Функции (14): `good_def`, `good_name`, `apply_goods`, `goods_init`, `prof_mult`, `goods_demand`, `goods_prices`, `goods_shock`, `good_yoy`, `cpi_goods`, `group_cpi`, `group_gap`, `goods_support_term`, `group_top_goods`

### `scripts/logic/economy.gd`  (544 строк)
Экономика: рынки, сооружения, центробанк, торговля, шаг экономики.

Функции (32): `world_ea_update`, `mk_def`, `init_economy`, `tariff_rev_share`, `import_share`, `roy_rev_share`, `ec_budget_lines`, `struct_count`, `struct_total`, `struct_cond_factor`, `struct_step`, `complete_struct`, `repair_cost_pct`, `repair_all`, `struct_total_count`, `world_step`, `cb_target`, `cb_name`, `cb_step`, `set_rate`, `income_parts`, `households_step`, `bconf_reasons`, `business_step`, `gov_idx`, `markets_step`, `trade_step`, `economy_step`, `hist_push`, `apply_econ`, `region_struct_text`, `struct_effect_text`

### `scripts/logic/regions.gd`  (613 строк)
Регионы: лояльность, недовольство, проекты, региональная экономика.

Функции (34): `ag_unrest_term`, `update_forecast`, `update_transfer_ui`, `select_region`, `reg_avg`, `recalc_weights`, `new_governor`, `transfer_avg`, `update_regions`, `complete_project`, `start_project`, `cancel_project`, `appoint_governor`, `set_transfer`, `equalize_transfers`, `do_region_action`, `region_ok`, `de_start_parliament`, `calibrate_regions`, `build_geometry`, `sec_idx`, `sec_cur`, `dominant_sector`, `reg_growth`, `rdebt_target`, `reg_zones_end`, `reg_econ_step`, `reg_year_report`, `reg_events_all`, `tool_req`, `tool_effect_text`, `reg_tool_factor`, `tool_cost_pct`, `reg_tool_buy`

### `scripts/logic/elections.gd`  (751 строк)
Выборы: голоса, места, президентские и парламентские выборы, конкуренция партий.

Функции (41): `ag_exit_report`, `ag_region_table`, `coalition_names`, `decree_power`, `form_government`, `gov_seats`, `log_header`, `present_event`, `radical_text`, `show_election`, `show_head_election`, `vote_weights`, `region_shares`, `region_shares_legacy`, `parl_shares`, `allocate_seats`, `sorted_parties`, `head_cand_ok`, `head_cand_name`, `head_row`, `head_term_months`, `hold_head`, `hold_head_core`, `head_outcome`, `head_present`, `hold_head_direct`, `hold_head_indirect`, `hold_head_council`, `head_campaign_check`, `hold_parliament`, `hold_parliament_core`, `election_title`, `campaign_check`, `party_attitude`, `electorate_text`, `national_shares`, `democracy_index`, `democracy_name`, `apply_competition`, `democracy_text`, `sham_shares`

### `scripts/logic/coalition.gd`  (757 строк)
Коалиция и правительство: партии, министры, требования, вотум недоверия.

Функции (56): `end_game`, `tolerates`, `against_seats`, `gov_ok`, `gov_margin`, `seat_pad`, `gov_seats`, `coalition_names`, `opp_bloc`, `check_impeachment`, `party_stance`, `demand_value`, `demand_met`, `demand_score`, `demand_lines`, `port_score`, `sat_target`, `sat_reason`, `grant_ministries`, `release_ministries`, `assign_ministries`, `add_member`, `remove_member`, `cycle_ministry`, `select_party`, `do_concession`, `fulfill_demands`, `fulfill_party_demands`, `fulfill_coalition_demands`, `form_government`, `check_government`, `show_no_confidence`, `resolve_no_confidence`, `toggle_coalition`, `ministries_of`, `ministry_fx`, `ministry_is_special`, `ministry_role_text`, `ministry_items`, `new_minister`, `sync_ministers`, `cabinet_items`, `assign_ministry`, `replace_minister`, `reshuffle_cabinet`, `quota_for`, `sat_breakdown`, `willingness`, `add_commitment`, `check_commitments`, `invite_party`, `coal_text`, `pick_weighted_partner`, `coal_pick`, `show_coal_event`, `apply_psat`

### `scripts/logic/events.gd`  (305 строк)
События и новости.

Функции (16): `auto_event_ok`, `auto_resolve_event`, `radical_events`, `ev_de_only`, `event_ok`, `show_news`, `ev_kind_info`, `ev_style`, `ev_context_text`, `present_event`, `show_event`, `choose`, `dip_events`, `gen_dip_event`, `w_help_event`, `fire_scripted`

### `scripts/logic/turn.gd`  (361 строк)
Ход игры: один месяц, конец игры, начальная установка состояния.

Функции (20): `ag_build`, `ag_step`, `autopilot_step`, `dip_init`, `dip_step`, `log_add`, `radical_step`, `world_init`, `world_spill_g`, `world_spill_infl`, `wsim_step`, `on_auto_toggled`, `on_auto_tick`, `log_policy_changes`, `next_turn`, `log_month`, `log_year_summary`, `end_game`, `init_state`, `skip_months`

### `scripts/logic/world.gd`  (672 строк)
Дипломатия и живой мир.

Функции (43): `open_mult`, `foreign_region_text`, `dip_init`, `dip_rel_name`, `dip_target`, `dip_rel_factor`, `dip_growth`, `dip_sec`, `dip_infra_bonus`, `dip_avg_rel`, `dip_apply_mods`, `dip_change`, `dip_step`, `track_name`, `dip_fx_apply`, `dip_fx_text`, `dip_do_action`, `dip_track_cost`, `dip_upgrade`, `dip_downgrade`, `w_codes`, `world_init`, `w_stance_name`, `w_share`, `w_cur_growth`, `w_pot`, `world_spill_g`, `w_shock_g`, `world_spill_infl`, `world_ea_update`, `w_start_crisis`, `world_help`, `w_election`, `w_player_stance`, `w_shock_step`, `w_party_name`, `w_party_for`, `wsim_step`, `world_infl_bias`, `world_news`, `world_info`, `remap_base_ps`, `dip_all`

### `scripts/logic/radical.gd`  (470 строк)
Радикальные законы: форма правления, строй, выход из ЕС и т.д.

Функции (21): `arch_ps`, `RV`, `rid_of`, `regime_id`, `econ_id`, `decree_power`, `radical_bypass`, `radical_req`, `law_locked`, `auth_idx`, `radical_enact`, `open_mult`, `radical_dyn`, `radical_step`, `show_uprising`, `radical_roll`, `radical_text`, `active_rids`, `radical_events`, `radical_add_variants`, `radical_inject`

### `scripts/logic/agents.gd`  (276 строк)
Население: подключение агентов к голосованию, шагу и протестам.

Функции (17): `update_pop_windows`, `ag_k`, `ag_make_pos`, `ag_support_arr`, `ag_build`, `ag_calibrate`, `ag_zs`, `ag_zg`, `ag_step`, `ag_unrest_term`, `ag_region_table`, `ag_exit_report`, `ag_toggle`, `ag_set_k`, `ag_pick`, `ag_random_agent`, `ag_reset_ui`

### `scripts/logic/autopilot.gd`  (248 строк)
Помощник и автопилот.

Функции (13): `ap_can_adj`, `ap_note_change`, `ap_flush_log`, `autobalance_step`, `balance_now`, `apply_preset`, `fx_score`, `auto_event_pick`, `auto_event_ok`, `auto_resolve_event`, `autobuild_step`, `autopilot_step`, `advisor_lines`

### `scripts/logic/log.gd`  (152 строк)
Структурированный журнал.

Функции (16): `log_guess_cat`, `log_match`, `log_add`, `log_chip`, `log_render`, `log_cell`, `log_render_month`, `log_render_year`, `log_rebuild`, `log_clear`, `on_log_filter`, `build_log_filters`, `log_line`, `log_sys`, `log_header`, `log_tag`

### `scripts/ui/ui_core.gd`  (1209 строк)
Интерфейс: окна, тема, верхняя панель, экран «Бюджет», обновление.

Функции (69): `build_dip_windows`, `build_econ_windows`, `build_election_window`, `build_event_window`, `build_goods_windows`, `build_gov_windows`, `build_law_windows`, `build_map_windows`, `build_politics_windows`, `build_pop_windows`, `ec_slider`, `map_apply_mode`, `show_country_menu`, `update_dip_windows`, `update_econ_windows`, `update_goods_windows`, `update_gov_windows`, `update_law_windows`, `update_parliament`, `update_regions_ui`, `new_window`, `layout_windows`, `fix_wraps`, `fix_wraps_later`, `on_wrap_timer`, `reset_layout`, `show_desk`, `build_ui`, `add_title`, `add_note`, `make_fold`, `make_tail`, `set_tail_text`, `on_fold_toggled`, `on_detail_toggled`, `add_wrap_label`, `make_button`, `make_rt`, `add_slider`, `set_bar`, `build_budget_windows`, `build_log_and_event`, `update_slider_label`, `update_forecast`, `update_stats`, `update_polls`, `add_bar`, `color_button`, `refresh`, `on_slider`, `slider_value_for`, `configure_slider`, `toggle_slider_mode`, `make_theme`, `accent_for_desk`, `polish_tree`, `make_chip`, `set_chip`, `update_chips`, `draw_budget_viz`, `on_log_detail`, `show_tab`, `update_subbar`, `build_subbar`, `build_auto_window`, `on_ap_toggle`, `on_ap_target`, `on_ap_style`, `update_auto_window`

### `scripts/ui/ui_map.gd`  (1069 строк)
Интерфейс: карта, таблица регионов, региональная экономика.

Функции (36): `on_layer_selected`, `map_prepare`, `map_view`, `map_country_rect`, `map_fit_rect`, `map_zoom_cmd`, `map_zoom_at`, `map_clamp`, `unit_at`, `ctx_at`, `unit_tip`, `map_click`, `on_region_picked`, `map_apply_mode`, `on_map_input`, `build_map_windows`, `on_transfer_slider`, `on_table_row`, `set_sort`, `layer_info`, `layer_leader`, `layer_color`, `cl_info`, `cl_color`, `unit_color`, `draw_map`, `region_tip`, `region_sort_value`, `update_regions_ui`, `update_region_table`, `update_transfer_ui`, `update_region_info`, `on_tool_selected`, `build_regecon_window`, `update_regecon`, `regecon_inject`

### `scripts/ui/ui_politics.gd`  (318 строк)
Интерфейс: парламент, полукруг, таблица партий.

Функции (10): `select_neg_party`, `build_hemicycle`, `build_politics_windows`, `on_party_button`, `update_parliament`, `draw_hemi`, `on_hemi_input`, `update_party_table`, `update_party_detail`, `ministry_effect_text`

### `scripts/ui/ui_laws.gd`  (572 строк)
Интерфейс: окно законов.

Функции (19): `build_law_windows`, `on_law_search`, `on_law_filter`, `law_demand_map`, `on_law_cat`, `on_topic_pressed`, `first_other_variant`, `on_card_input`, `on_adopt`, `on_negotiate`, `update_law_windows`, `update_law_effects`, `refit_law_cards`, `update_law_votes`, `build_law_slider`, `on_law_slider`, `build_law_list`, `update_law_headers`, `update_law_detail`

### `scripts/ui/ui_gov.gd`  (392 строк)
Интерфейс: правительство и коалиционные переговоры.

Функции (19): `build_gov_windows`, `select_ministry`, `select_neg_party`, `on_neg_selected`, `on_neg_promise`, `on_neg_main`, `on_neg_conc`, `on_neg_dem`, `on_assign_ministry`, `on_replace_minister`, `update_gov_windows`, `update_coal_summary`, `update_cabinet`, `update_min_detail`, `refit_gov`, `update_neg`, `refit_neg`, `update_cabfx`, `update_commit`

### `scripts/ui/ui_econ.gd`  (454 строк)
Интерфейс: экран «Экономика».

Функции (14): `ec_slider`, `build_econ_windows`, `on_cb_auto`, `on_rate_slider`, `on_tariff_slider`, `on_roy_slider`, `on_focus_selected`, `on_chart_selected`, `update_chart`, `update_econ_windows`, `build_goods_windows`, `goods_market_color`, `update_goods_windows`, `_hot_txt`

### `scripts/ui/ui_world.gd`  (125 строк)
Интерфейс: дипломатия.

Функции (3): `select_dip`, `build_dip_windows`, `update_dip_windows`

### `scripts/ui/ui_pop.gd`  (244 строк)
Интерфейс: вкладка «Население».

Функции (3): `build_pop_windows`, `ag_agent_text`, `update_pop_windows`

### `scripts/ui/ui_events.gd`  (306 строк)
Интерфейс: окна событий и выборов.

Функции (6): `show_head_election`, `build_election_window`, `show_election`, `election_continue`, `build_event_window`, `refit_event`

### `main.gd`  (494 строк)
PolitGame: корневой скрипт (вершина цепочки наследования, см. scripts/CHAIN.txt).

Функции (16): `country_arg`, `seed_arg`, `apply_country`, `apply_markets`, `cdat`, `diff_color`, `menu_title`, `menu_rt`, `menu_bar`, `sector_shares`, `country_strengths`, `fill_country_card`, `show_country_menu`, `choose_country`, `_ready`, `_unhandled_input`

## Классы (`scripts/classes/`)

- `agent_hist_view.gd` — extends Control, 25 строк
- `agent_map_view.gd` — extends Control, 46 строк
- `agent_pop.gd` — extends RefCounted, 481 строк
- `country_map.gd` — extends Control, 192 строк
- `econ_chart.gd` — extends Control, 70 строк
- `election_view.gd` — extends Control, 178 строк
- `float_window.gd` — extends Control, 228 строк
- `goods_view.gd` — extends Control, 61 строк
- `head_view.gd` — extends Control, 89 строк
- `market_bar.gd` — extends Control, 64 строк
- `stat_bar.gd` — extends Control, 37 строк
