# Карта проекта (создаётся автоматически: `python3 tools/mapdoc.py`)

Скрипты игры образуют **цепочку наследования**: каждый файл `extends` предыдущий, вершина — `main.gd`. Порядок — в `scripts/CHAIN.txt`. Поэтому любая функция доступна из любого модуля; если модуль вызывает функцию из модуля ниже по цепочке, нужна «заглушка» — её создаёт `tools/stubs.py`.

## Цепочка

### `scripts/data/data_core.gd`  (13868 строк)
Справочные таблицы игры: группы, политика, уровни, рынки, цвета и т.п. (только const).

Функции (2): `ext_load`, `ext_load_countries`

Константы (144): `StatBar`, `PieChart`, `ElectionView`, `HeadView`, `FloatWindow`, `MarketBar`, `EconChart`, `AgentPop`, `AgentMapView`, `AgentHistView`, `Ico`, `FaithChart`, `DepChart`, `Spark`, `TechView`, `COUNTRY_CODES`, `GoodsView`, `CountryMap`, `START_YEAR`, `PLAY_SPEEDS`, `PLAY_NAMES`, `MONTHS_GEN`, `MONTHS`, `COALITION_JOIN`, `COALITION_JOIN_PAID`, `COALITION_LEAVE`, `CONCESSION_COST`, `COL_GOOD`, `COL_BAD`, `COL_NEUTRAL`, `COL_HEAD`, `COL_WARN`, `COL_ELECT`, `COL_PURPLE`, `COL_TEAL`, `COL_DIM`, `COL_FAINT_HEX`, `C_BG`, `C_PANEL`, `C_PANEL2`, `C_BORDER`, `C_TEXT`, `C_DIM`, `C_FAINT`, `C_ACCENT`, `C_GOOD`, `C_WARN`, `C_BAD`, `C_PURPLE`, `C_TEAL`, `REV_COLORS`, `EXP_COLORS`, `GROUPS`, `GROUP_FX`, `EXPECT_DRIFT`, `LEVELS`, `LEVEL_RATE`, `STATE_NAMES`, `LEVEL_EFFECTS`, `MIN_FX_SCALE`, `SAT_OFFSET`, `SAT_FATIGUE`, `SAT_FATIGUE_CAP`, `COAL_EVENTS`, `SAT_LEAVE`, `REG_KEYS`, `REG_TITLES`, `SECTOR_NAMES`, `GOV_KINDS`, `GOV_DESC`, `MAP_LAYERS`, `MAP_LAYER_ORDER`, `MAP_LEGENDS`, `MARKET_COLORS`, `GOOD_PROF`, `AG_GK`, `STRUCT_CATS`, `FOCUS_NAMES`, `FOCUS_IDS`, `RATE_NEUTRAL_REAL`, `PROJECTS`, `ECON_FX_INFO`, `ECON_EVENTS`, `ECON_MEASURES`, `REGION_ACTIONS`, `LAW_CATS`, `LAW_CAT_COLORS`, `PRES_RULE_NAMES`, `MOD_INFO`, `MEASURES_BASE`, `ACTIONS`, `NEWS`, `AG_STRIDE`, `AG_POLL_N`, `AG_ZK`, `HIST_KEYS`, `EC_CHART_NAMES`, `EC_CHART_COLORS`, `FUND_IDS`, `DEM_LAW`, `LAW_PARAMS_V11`, `PARAM_DEMANDS`, `DEM_BASE`, `MIL_DEMO`, `LOG_FILTERS`, `LOG_FILTER_CATS`, `LOG_CAT_COL`, `LOG_CAT_NAME`, `LOG_TAG_CAT`, `LOG_POL_WORDS`, `LOG_ECO_WORDS`, `AP_STYLES`, `AP_STYLE_TIPS`, `PRESETS`, `AP_BUILD_MAP`, `DIP_TRACKS`, `DIP_ACTIONS`, `DIP_LAYERS`, `DIP_REL_NAMES`, `DIP_EVENTS`, `DIP_SUMMITS`, `W_OPEN`, `W_KINDS`, `EMIT_MAX`, `RAD_MONARCHIES`, `RAD_AUTH`, `RAD_CUR`, `RAD_AUTH_TOPICS`, `RAD_MARKET_TOPICS`, `RSEC`, `SEC_COLORS`, `REG_TOOLS`, `REG_EVENTS_GEN`, `REG_EVENTS_CC`, `ELEC_DATA`, `WORLD_PCOL`, `WORLD_CCOL`, `WORLD_OPEN`, `WORLD_STANCE0`, `WORLD_TRADE`, `WORLD_REL`, `WORLD_LV0`, `WORLD_CTX`, `WORLD_CAPS`

Переменные (1): `WORLD`

### `scripts/data/data_content.gd`  (688 строк)
Крупные таблицы контента: события, законы, радикальные законы, карта мира.

Константы (4): `LAW_TOPICS_BASE`, `EVENTS`, `NEW_TOPICS`, `RAD_EVENTS`

Переменные (2): `WORLD_UNITS`, `ATE`

### `scripts/data/data_tech.gd`  (311 строк)
Технологии (v42_1): пять веток по 14 уровней на 100 лет вперёд (124 технологии; на 6 уровнях каждой ветки выбор «одна из 2–3») и специальные сооружения.

Константы (11): `TECH_NB`, `TECH_BRANCHES`, `TECHS`, `TECH_BUILDINGS`, `TECH_R0`, `TECH_CAP0`, `TECH_CAP_YEAR`, `TECH_FREE_BASE`, `TECH_FREE_SPAN`, `TECH_PASSIVE`, `TECH_PASSIVE_CAP`

### `scripts/data/data_countries.gd`  (6 строк)
Пакеты данных стран (генерируются tools/gen_data из Python-описаний).

Переменные (1): `CDATA`

### `scripts/state/state_data.gd`  (576 строк)
Таблицы, которые страна подменяет при запуске (REGIONS, LEAN, PARTY_NAMES и др.).

Переменные (66): `SEATS`, `MAJORITY`, `POLICY`, `GROUP_WEIGHT`, `GROUP_BASE`, `PARTY_NAMES`, `PARTY_DESC`, `PARTY_COLORS`, `LEAN`, `HEMI_ORDER`, `PARTY_LEADERS`, `PARTY_DEMANDS`, `MINISTRIES`, `PARTY_MINISTRIES`, `MIN_SPECIAL`, `PARTY_TRAITS`, `PARTY_LAW_DEMAND`, `MINISTER_NAMES`, `GOV_NAMES`, `REGIONS`, `REG_BIAS`, `MARKETS`, `BASE_MODS`, `LAW_TOPICS`, `MEASURES`, `TERMS`, `INFO`, `UPPER`, `MACRO`, `REGIONAL_P`, `MARKETS_OVR`, `GOODS`, `GOODS_OVR`, `COALITION0`, `LAW_TAGS`, `PARCH`, `EVENTS_C`, `NEWS_C`, `EVENTS_SPECIAL`, `ARCHS`, `ELEC`, `AG`, `LOC_RULES`, `TOLERATE_W`, `SUPER`, `GDP0`, `G_POT`, `G_NEU`, `I_NEU`, `I_TGT`, `U_NEU`, `OTHER0`, `RATE0`, `DE_START_SEATS`, `DE_START_MIN`, `DE_PARAM`, `DE_NEW_PARAMS`, `DE_REMOVE`, `DE_FUND_ADD`, `DE_TOPICS` …

### `scripts/state/state.gd`  (784 строк)
Текущее состояние партии: показатели, законы, парламент, узлы интерфейса.

Переменные (434): `pending_code`, `pending_party`, `game_opts`, `ccode`, `map_reg_pick`, `emit_note`, `risk_prem`, `minority_ok`, `turn`, `year`, `month`, `gdp`, `debt`, `growth`, `inflation`, `unemployment`, `shock`, `other_rev`, `pol`, `pol_def`, `prev_pol`, `policy_by_key`, `lvl`, `support`, `bias`, `mods`, `cooldown`, `capital`, `seats`, `in_coalition`, `warned`, `crisis_months`, `prev_head`, `h12`, `observer`, `deadlock`, `minority_gov`, `pm_lead`, `techno_until`, `extra_mins`, `neg_offer_mins`, `crisis_offered`, `impeach_warned`, `last_parl`, `last_pres`, `pres_due`, `pres_camp`, `pres_camp_done`, `pres_party`, `hemi_rad`, `el_head`, `game_over`, `current_event`, `event_region`, `prev_items`, `year_start`, `charisma`, `satis`, `joined`, `conc` …

### `scripts/logic/util.gd`  (345 строк)
Мелкие помощники: перевод, форматирование, цвета, даты.

Функции (44): `rt`, `tm`, `cap1`, `low1`, `build_loc`, `loc`, `loc_tree`, `jag_edge`, `sg`, `col_delta`, `find_by_id`, `policy_title`, `sat`, `mrate`, `years_passed`, `days_in_month`, `date_full`, `date_chip`, `days_until_months`, `days_text`, `date_text`, `turn_date`, `months_text`, `date_after`, `stat_color`, `total_pop`, `pop_ratio`, `amt`, `std_index`, `fx_col`, `sbox`, `make_dot_tex`, `scale_color`, `fmt_n`, `months_short`, `arrow_text`, `delta_col`, `col_signed`, `bit_text`, `good_col`, `hint_line`, `fmt_sg`, `date_short`, `polygon_area`

### `scripts/logic/policy.gd`  (1012 строк)
Бюджетная политика: ползунки, блокировки, уровни, эффекты, моды законов.

Функции (98): `add_commitment`, `adm_admin_mult`, `apply_econ`, `apply_psat`, `dip_all`, `dip_apply_mods`, `dip_fx_apply`, `dip_fx_text`, `ec_budget_lines`, `fed_tax_leak`, `fulfill_coalition_demands`, `good_name`, `goods_support_term`, `ministry_fx`, `mk_def`, `new_minister`, `radical_dyn`, `radical_roll`, `reg_avg`, `reg_zones_end`, `rel`, `sec_idx`, `slider_value_for`, `soc_fx`, `soc_tax`, `sync_ministers`, `tech_apply_mods`, `tech_edu_upkeep`, `transfer_avg`, `update_slider_label`, `variant_of`, `war_prem`, `world_help`, `approval`, `add_support`, `add_all_support`, `set_policy`, `apply_reg_delta`, `describe_reg`, `region_support`, `split_subsidies`, `expected`, `factor`, `fatigue`, `target_support`, `target_gov_support`, `budget_changes`, `describe_fx`, `apply_fx`, `compute_budget`, `update_levels`, `pp0`, `expected_pp`, `is_abs`, `abs_range`, `sync_abs_policies`, `lock_active`, `add_lock`, `lock_allowed`, `lock_allowed_share`, `lock_until_text`, `lock_note`, `expire_locks`, `emit_cap`, `sync_emit`, `emit_safe_pct`, `emit_excess`, `lvl_sum`, `issue_multiplier`, `regional_potential`, `per_capita`, `avg_per_capita`, `tier_name`, `dev_gain_mult`, `tax_ratio`, `project_cost_pct`, `roi_estimate`, `roi_text`, `effective_reg`, `demand_cur`, `is_hybrid`, `pw_of`, `scale_dict`, `funding_mode`, `party_funded`, `funding_mult`, `init_laws`, `parl_term`, `pres_term`, `impeach_seats`, `crisis_limit`, `compute_mods`, `recompute_mods`, `scale_fx`, `mod_good_dir`, `boost_good`, `describe_econ`, `debt_rate`

Константы (2): `AGRI_FX`, `HYBRID_IDS`

### `scripts/logic/laws.gd`  (1073 строк)
Законы: варианты, голосование, числовые законы, меры и действия.

Функции (65): `hold_parliament`, `junior_info`, `law_locked`, `log_line`, `log_tag`, `national_shares`, `pact_has`, `party_stance`, `propose_variant`, `radical_bypass`, `radical_enact`, `radical_req`, `refresh`, `rid_of`, `sfx`, `do_measure`, `do_action`, `level_effects_text`, `fx_items`, `reg_item`, `fx_pros_cons`, `layer_ramp`, `level_effect_list`, `law_tweak`, `variant_of`, `variant_part`, `cur_idx`, `law_cost`, `dict_diff`, `support_delta`, `variant_stance`, `variant_votes`, `upper_check`, `upper_text`, `negotiate_variant`, `adopt_variant`, `mod_item`, `variant_effect_items`, `items_pros_cons`, `pres_needs_runoff`, `law_reform_count`, `law_demand_of`, `law_demand_met`, `law_demand_text`, `fmt_param`, `param_grid`, `make_param_topic`, `build_law_topics`, `sq_effects`, `variant_own_items`, `is_fund`, `law_need`, `demand_idx`, `demand_dict_met`, `param_scale_text`, `variant_swing`, `de_law_params`, `de_fix_ps`, `de_adapt_topics`, `brake_allowed`, `brake_active`, `brake_step`, `brake_text`, `snap_info`, `snap_votes`

Константы (3): `POW_MODERATION`, `SQ_K`, `SNAP_RULES`

### `scripts/logic/goods.gd`  (157 строк)
Товары: потребительская корзина (18 видов), их цены и спрос, корзины групп населения.

Функции (14): `good_def`, `good_name`, `apply_goods`, `goods_init`, `prof_mult`, `goods_demand`, `goods_prices`, `goods_shock`, `good_yoy`, `cpi_goods`, `group_cpi`, `group_gap`, `goods_support_term`, `group_top_goods`

### `scripts/logic/economy.gd`  (549 строк)
Экономика: рынки, сооружения, центробанк, торговля, шаг экономики.

Функции (32): `world_ea_update`, `mk_def`, `init_economy`, `tariff_rev_share`, `import_share`, `roy_rev_share`, `ec_budget_lines`, `struct_count`, `struct_total`, `struct_cond_factor`, `struct_step`, `complete_struct`, `repair_cost_pct`, `repair_all`, `struct_total_count`, `world_step`, `cb_target`, `cb_name`, `cb_step`, `set_rate`, `income_parts`, `households_step`, `bconf_reasons`, `business_step`, `gov_idx`, `markets_step`, `trade_step`, `economy_step`, `hist_push`, `apply_econ`, `region_struct_text`, `struct_effect_text`

### `scripts/logic/regions.gd`  (649 строк)
Регионы: лояльность, недовольство, проекты, региональная экономика.

Функции (42): `adm_dev_term`, `ag_unrest_term`, `fed_auto_term`, `fed_dev_term`, `fed_loy_term`, `fed_unr_term`, `soc_loy_term`, `soc_unr_term`, `update_forecast`, `update_transfer_ui`, `select_region`, `reg_avg`, `recalc_weights`, `new_governor`, `transfer_avg`, `update_regions`, `complete_project`, `start_project`, `cancel_project`, `appoint_governor`, `set_transfer`, `equalize_transfers`, `do_region_action`, `region_ok`, `de_start_parliament`, `calibrate_regions`, `calibrate_region`, `build_geometry`, `sec_idx`, `sec_cur`, `dominant_sector`, `reg_growth`, `rdebt_target`, `reg_zones_end`, `reg_econ_step`, `reg_year_report`, `reg_events_all`, `tool_req`, `tool_effect_text`, `reg_tool_factor`, `tool_cost_pct`, `reg_tool_buy`

### `scripts/logic/elections.gd`  (846 строк)
Выборы: голоса, места, президентские и парламентские выборы, конкуренция партий.

Функции (50): `ag_exit_report`, `ag_region_table`, `ai_form_gov`, `coalition_names`, `decree_power`, `form_government`, `gov_seats`, `log_header`, `opp_after_election`, `opp_campaign`, `opp_enter`, `opp_gov_seats`, `opp_gov_text`, `opp_to_gov`, `pact_mult`, `present_event`, `radical_text`, `show_election`, `show_head_election`, `upper_renew`, `vote_weights`, `region_shares`, `region_shares_legacy`, `parl_shares`, `allocate_seats`, `sorted_parties`, `head_cand_ok`, `head_cand_name`, `head_row`, `head_term_months`, `hold_head`, `hold_head_core`, `head_outcome`, `head_present`, `hold_head_direct`, `hold_head_indirect`, `hold_head_council`, `head_campaign_check`, `hold_parliament`, `hold_parliament_core`, `election_title`, `campaign_check`, `party_attitude`, `electorate_text`, `national_shares`, `democracy_index`, `democracy_name`, `apply_competition`, `democracy_text`, `sham_shares`

### `scripts/logic/coalition.gd`  (882 строк)
Коалиция и правительство: партии, министры, требования, вотум недоверия.

Функции (69): `coal_members`, `coal_share`, `council_invite_vote`, `council_min_vote`, `council_on`, `end_game`, `invite_offer_w`, `party_lean`, `show_crisis_exit`, `war_sat_term`, `can_govern`, `is_cordon`, `tolerates`, `against_seats`, `gov_ok`, `gov_margin`, `seat_pad`, `gov_seats`, `coalition_names`, `opp_bloc`, `check_impeachment`, `party_stance`, `floor_share`, `auto_floor`, `demand_value`, `demand_met`, `demand_score`, `demand_lines`, `port_score`, `sat_target`, `sat_reason`, `grant_ministries`, `release_ministries`, `assign_ministries`, `add_member`, `remove_member`, `cycle_ministry`, `select_party`, `do_concession`, `fulfill_demands`, `fulfill_party_demands`, `fulfill_coalition_demands`, `form_government`, `check_government`, `show_no_confidence`, `resolve_no_confidence`, `toggle_coalition`, `ministries_of`, `ministry_fx`, `ministry_is_special`, `ministry_role_text`, `ministry_items`, `new_minister`, `sync_ministers`, `cabinet_items`, `assign_ministry`, `replace_minister`, `reshuffle_cabinet`, `quota_for`, `sat_breakdown`, `willingness`, `add_commitment`, `check_commitments`, `invite_party`, `coal_text`, `pick_weighted_partner`, `coal_pick`, `show_coal_event`, `apply_psat`

Константы (2): `GOV_EXCLUDE`, `CORDON_JOIN`

### `scripts/logic/events.gd`  (375 строк)
События и новости.

Функции (27): `auto_event_ok`, `auto_event_pick`, `auto_resolve_event`, `council_event`, `council_event_note`, `council_event_ok`, `council_split`, `fleet_resolve`, `mil_resolve`, `opp_resolve_offer`, `radical_events`, `resolve_crisis`, `set_time_btns`, `ev_de_only`, `event_ok`, `show_news`, `ev_kind_info`, `ev_style`, `ev_context_text`, `present_event`, `econ_pool`, `show_event`, `choose`, `dip_events`, `gen_dip_event`, `w_help_event`, `fire_scripted`

### `scripts/logic/turn.gd`  (718 строк)
Ход игры: один месяц, конец игры, начальная установка состояния.

Функции (72): `adm_month`, `ag_build`, `ag_step`, `ai_init`, `ai_parties_step`, `ate_reset`, `autopilot_run`, `bills_step`, `council_budget`, `dip_init`, `dip_step`, `ex_g`, `ex_infl`, `ex_init`, `ex_month`, `fed_init`, `fed_month`, `fleet_day`, `fleet_g`, `fleet_infl`, `fleet_init`, `fleet_month`, `h12_snap`, `idl_mult`, `idl_step`, `junior_power`, `junior_quit`, `log_add`, `mil_day`, `mil_g`, `mil_infl`, `mil_init`, `mil_month`, `mil_unemp`, `observer_step`, `opp_init`, `opp_step`, `radical_step`, `soc_g`, `soc_init`, `soc_month`, `soc_unemp`, `tech_init`, `tech_month`, `world_init`, `world_spill_g`, `world_spill_infl`, `wsim_step`, `set_speed`, `on_play_toggled`, `on_speed_selected`, `set_time_btns`, `blocked`, `day_tick`, `advance_day`, `advance_days`, `advance_month`, `_process`, `log_policy_changes`, `macro_step`, `cap_rate`, `debt_erode`, `debt_drag`, `rt`, `week_tick`, `take_month_snap`, `next_turn`, `log_month`, `log_year_summary`, `end_game`, `init_state`, `skip_months`

### `scripts/logic/world.gd`  (683 строк)
Дипломатия и живой мир.

Функции (45): `ex_bot_g`, `mil_dip_term`, `open_mult`, `foreign_region_text`, `dip_init`, `dip_rel_name`, `dip_target`, `dip_rel_factor`, `dip_growth`, `dip_sec`, `dip_infra_bonus`, `dip_avg_rel`, `dip_apply_mods`, `dip_change`, `dip_step`, `track_name`, `dip_fx_apply`, `dip_fx_text`, `dip_do_action`, `dip_track_cost`, `dip_upgrade`, `dip_downgrade`, `w_codes`, `world_init`, `w_stance_name`, `w_share`, `w_cur_growth`, `w_pot`, `world_spill_g`, `w_shock_g`, `world_spill_infl`, `world_ea_update`, `w_start_crisis`, `world_help`, `w_election`, `w_player_stance`, `w_shock_step`, `w_party_name`, `w_party_for`, `wsim_step`, `world_infl_bias`, `world_news`, `world_info`, `remap_base_ps`, `dip_all`

### `scripts/logic/federation.gd`  (1254 строк)
Федерация, автономия субъектов и передача территорий (покупка региона, добровольное объединение стран).

Функции (74): `ate_unit_has_capital`, `map_rebuild`, `soc_init_region`, `fed_cfg`, `fed_reset_world`, `fed_init`, `fed_region_init`, `fed_new_sub`, `fed_d`, `fed_shock`, `fed_loy_term`, `fed_unr_term`, `fed_dev_term`, `fed_auto_term`, `fed_tax_leak`, `fed_max_level`, `fed_coal_share`, `fed_dom`, `fed_upper`, `fed_ref_p`, `fed_roll`, `fed_cd_get`, `fed_cap_ok`, `fed_comp_cost`, `fed_comp_check`, `fed_comp_step`, `fed_comp_all`, `fed_status_check`, `fed_status_step`, `fed_set_eq`, `fed_reform_check`, `fed_reform`, `fed_party_for_bloc`, `fed_make_upper`, `fed_admit_check`, `fed_admit`, `fed_month`, `fed_idx_of_uid`, `fed_demand_of`, `fed_demand_text`, `fed_demand_decide`, `fed_world_cc`, `fed_wreg`, `fed_wreg_gdp`, `fed_unit_is_capital`, `fed_unit_cc`, `fed_set_unit_cc`, `fed_backup_world`, `fed_adjacent_units`, `fed_rel`, `fed_court`, `fed_pc_ratio`, `fed_avg_dict`, `fed_take_unit`, `fed_rebuild_world_side`, `fed_rebuild`, `fed_calibrate_new`, `fed_news_world`, `terr_price`, `terr_buy_quote`, `terr_buy`, `terr_sell_buyers`, `fed_ui_of_region`, `terr_sell_quote`, `terr_sell`, `terr_transfer`, `fed_drop_region`, `union_candidates`, `union_quote`, `union_do`, `union_absorb`, `fed_comp_text`, `fed_region_line`, `fed_stats`

Константы (9): `FED_SPH`, `FED_LV`, `FED_LV_DESC`, `FED_LVL_NAMES`, `FED_ST`, `FED_EQ`, `FED_W`, `FED_K`, `FED_SHOCK`

Переменные (6): `FED`, `fst`, `fed_u0`, `fed_w0`, `fed_ui`, `fed_rng`

### `scripts/logic/admin.gd`  (923 строк)
v36: административно-территориальные единицы (АТЕ) и административные реформы.

Функции (47): `ate_load`, `ate_nbs`, `ate_at_point`, `ate_reset`, `ate_rebuild`, `ate_unit_center`, `ate_alive`, `ate_unit_has_capital`, `ate_cc`, `ate_region`, `ate_share`, `ate_pop`, `ate_name`, `ate_groups`, `ate_touches`, `adm_region_ui`, `adm_region_ates`, `adm_region_km`, `adm_region_nbs`, `adm_devf`, `adm_pot`, `adm_mix_blend`, `adm_blend`, `adm_absorb`, `adm_new_region`, `adm_upper_seat`, `adm_cost`, `adm_common_check`, `adm_sel_own`, `adm_sel_pop`, `adm_left_check`, `adm_move_check`, `adm_create_check`, `adm_delete_check`, `adm_aftermath`, `adm_dev_term`, `adm_month`, `adm_admin_mult`, `adm_apply_moves`, `adm_move`, `adm_create`, `adm_delete`, `adm_rename`, `ate_buy_quote`, `adm_sel_km`, `ate_buy`, `ate_attach`

Константы (5): `ADM_CD`, `ADM_SHOCK`, `ADM_MAX_REG`, `ADM_BLEND`, `ADM_BLEND_D`

Переменные (1): `ate_k`

### `scripts/logic/society.gd`  (536 строк)
Религии и миграция. У каждого региона — религиозный состав; у каждого агента — своя вера.

Функции (38): `ex_fx`, `ex_rel_change`, `soc_cfg`, `soc_dyn`, `soc_vec`, `soc_init`, `soc_init_region`, `soc_national`, `soc_div`, `soc_delta_dot`, `soc_abs_dot`, `soc_nat_delta`, `soc_nat_abs`, `soc_din`, `soc_dout`, `soc_skill`, `soc_skill0`, `soc_mix_eff`, `soc_mig_faith`, `soc_loy_term`, `soc_unr_term`, `soc_g`, `soc_unemp`, `soc_tax`, `soc_month`, `soc_push_event`, `soc_events`, `soc_fx`, `soc_cd_get`, `soc_spend`, `soc_set_mig`, `soc_set_prog`, `soc_set_sel`, `soc_set_sec`, `soc_set_fund`, `soc_dialog`, `soc_dominant`, `soc_effect_text`

Константы (10): `SOC_FAITH`, `SOC_FCOL`, `SOC_FX`, `SOC_FNOTE`, `SOC_MIGM`, `SOC_IN_CAP`, `SOC_MIGN`, `SOC_PROG`, `SOC_SEC`, `SOC_SEL`

Переменные (3): `SOC`, `soc`, `soc_rng`

### `scripts/logic/tech.gd`  (484 строк)
Технологии (v39_1): три ветки исследований, специальные сооружения, скорость исследований с мягким потолком.

Функции (42): `ex_dep`, `ex_partners`, `mil_land_neighbor`, `tech_init`, `tech_def`, `tech_bdef`, `tech_done`, `tech_alts`, `tech_is_choice`, `tech_tier_done`, `tech_missing`, `tech_avail`, `tech_freedom`, `tech_sum`, `tech_bsum`, `tech_power`, `tech_edu_term`, `tech_cap`, `tech_raw`, `tech_soft`, `tech_refresh_rates`, `tech_apply_mods`, `tech_edu_upkeep`, `tech_build_missing`, `tech_build`, `tech_select`, `tech_set_weight`, `tech_auto_pick`, `tech_choice_waiting`, `tech_progress`, `tech_total`, `tech_count`, `tech_month`, `tech_fx_text`, `tech_nb`, `tech_hash`, `tech_nb_pace`, `tech_nb_tiers`, `tech_nb_has`, `tech_nb_who`, `tech_nb_share`, `tech_passive_rate`

Переменные (2): `tech`, `tech_idx`

### `scripts/logic/influence.gd`  (342 строк)
Экономическое влияние и зависимость: ваша страна ⇄ остальные страны мира (боты).

Функции (20): `ex_init`, `ex_partners`, `ex_rel_change`, `ex_cd_get`, `ex_dep`, `ex_leverage`, `ex_leverage_on_us`, `ex_g`, `ex_infl`, `ex_bot_g`, `ex_month`, `ex_events`, `ex_fx`, `ex_cap`, `ex_deal_set`, `ex_tariff_set`, `ex_aid_give`, `ex_dbuy_amt`, `ex_dbuy_set`, `ex_favor`

Константы (4): `EX_DEAL`, `EX_TAR`, `EX_GAIN`, `EX_LOSS`

Переменные (2): `ex`, `ex_rng`

### `scripts/logic/fleet.gd`  (544 строк)
Флот и морская торговля (v30): порты, морские пути, инциденты, военно-морской флот.

Функции (33): `fleet_load`, `flt_ports_of`, `flt_port`, `flt_has_sea`, `flt_port_split`, `flt_path`, `flt_path_len`, `fleet_init`, `fleet_power`, `fleet_class`, `fleet_cover`, `fleet_scale`, `fleet_port_util`, `fleet_util`, `fleet_sea_gdp`, `fleet_g`, `fleet_infl`, `fleet_recalc_f`, `fleet_log`, `fleet_day`, `fleet_incident`, `fleet_present_event`, `fleet_resolve`, `fleet_month`, `fleet_port_cost`, `fleet_port_invest`, `fleet_can_build`, `fleet_order`, `fleet_set_mission`, `fleet_merch`, `fleet_ports_summary`, `fleet_lane_edges`, `fleet_status_text`

Константы (2): `FLT_KINDS`, `FLT_MISSIONS`

Переменные (5): `FLEET`, `flt`, `flt_rng`, `flt_nodes`, `flt_path_cache`

### `scripts/logic/military.gd`  (2090 строк)
v37: армии, войны и захват территорий.

Функции (122): `talk_apply`, `talk_avail`, `talk_border_ates`, `talk_budget`, `talk_ceasefire`, `talk_cost`, `talk_mediator`, `talk_pkg_text`, `talk_terms`, `war_demo`, `war_dip_extra`, `war_intl`, `war_intl_g`, `war_intl_infl`, `war_intl_init`, `war_intl_month`, `war_on_declare`, `war_sanctions_update`, `war_timers_month`, `war_trade_g`, `war_vote`, `war_vote_text`, `mil_init`, `mil_on`, `mil_n_units`, `mil_cap`, `mil_spend_ratio`, `mil_q`, `mil_unit_name`, `mil_new_unit`, `mil_unit`, `mil_units_of`, `mil_cc_ates`, `mil_home_spots`, `mil_border_spots`, `mil_owner`, `mil_ctl`, `mil_at_war`, `mil_side`, `mil_at_war_with`, `mil_hostile`, `mil_side_ccs`, `mil_pw`, `mil_side_power`, `mil_total`, `mil_regular_total`, `mil_reserve_k`, `mil_mob_k`, `mil_country_power`, `mil_log`, `mil_idx`, `mil_un_build`, `mil_passable`, `mil_bfs`, `mil_reached`, `mil_path_to`, `mil_coast_build`, `mil_home_node`, `mil_port_nodes`, `mil_recruit_check`, `mil_min_unit`, `mil_recruit`, `mil_mob_check`, `mil_mobilize`, `mil_mob_arrive`, `mil_order_move`, `mil_order_mode`, `mil_targets`, `mil_land_neighbor`, `mil_allies_for`, `mil_declare_check`, `mil_declare`, `mil_start_war`, `mil_spawn_army`, `mil_day`, `mil_hostile_units_at`, `mil_units_at`, `mil_set_ctl`, `mil_take`, `mil_move_all`, `mil_local_odds`, `mil_battle_at`, `mil_join_battles`, `mil_def_mult`, `mil_battles`, `mil_battle_end`, `mil_retreat`, `mil_cleanup`, `mil_recover`, `mil_supply_update`, `mil_plan`, `mil_amp_cap`, `mil_land_check`, `mil_land_order`, `mil_sea_day`, `mil_land`, `mil_evacuate`, `mil_nav_station_set`, `mil_navy_day`, `mil_naval_battle`, `mil_occ`, `mil_cap_held`, `mil_score_update`, `mil_month`, `mil_war_month`, `mil_fix_positions`, `mil_mob_g`, `mil_g`, `mil_infl`, `mil_unemp`, `mil_dip_term`, `mil_occupied_by_us`, `mil_peace_quote`, `mil_peace_propose`, `mil_peace`, `mil_annex`, `mil_cede`, `mil_ai_peace`, `mil_event`, `mil_resolve`, `mil_ai_declare`, `mil_status_text`

Константы (6): `MIL_BASE`, `MIL_NATO`, `MIL_COMBAT`, `MIL_DIV`, `MIL_TRUCE`, `MIL_PEACE_KINDS`

Переменные (14): `mil`, `mil_rng`, `mil_coast`, `mil_coast_ok`, `mil_supply`, `mil_plan_t`, `mil_os`, `mil_cs`, `mil_un`, `mil_seen`, `mil_par`, `mil_stamp`, `mil_iver`, `mil_dirty`

### `scripts/logic/warpol.gd`  (800 строк)
v38: политика войны.

Функции (48): `war_demo`, `war_hawk`, `war_rel`, `war_both_eu`, `war_vote`, `war_vote_text`, `war_anger_add`, `war_anger`, `war_sat_term`, `war_prel_term`, `war_on_declare`, `war_anger_month`, `talk_sel`, `talk_border_ates`, `talk_avail`, `talk_cost`, `talk_package`, `talk_budget`, `talk_quote`, `talk_pkg_text`, `talk_terms`, `talk_propose`, `talk_ceasefire_check`, `talk_ceasefire`, `talk_ceasefire_break`, `talk_mediator_name`, `talk_mediator`, `talk_apply`, `war_intl`, `war_aggressor`, `war_victim`, `war_cond0`, `war_eu0`, `war_intl_init`, `war_sanc_list`, `war_sanctions_update`, `war_preview_text`, `war_intl_month`, `war_join_check`, `war_join`, `war_intl_g`, `war_intl_infl`, `war_nonrec_any`, `war_prem`, `war_dip_extra`, `war_timers_month`, `war_trade_g`, `war_intl_text`

Константы (4): `WAR_HAWK`, `TALK_IDS`, `TALK_INFO`, `TALK_REPAR`

### `scripts/logic/opposition.gd`  (750 строк)
Выбор партии, оппозиция и соглашения между партиями.

Функции (38): `idl_react`, `prm_init`, `rel_add`, `party_lean`, `party_sim`, `prel_base`, `prel_init`, `pact_left`, `pact_has`, `pact_mult`, `cd_left`, `player_swap_ok`, `swap_idx`, `apply_player_party`, `ai_coalition`, `ai_form_gov`, `opp_set_gov`, `opp_gov_text`, `opp_gov_seats`, `opp_init`, `opp_ap_force`, `opp_enter`, `junior_quit`, `opp_to_gov`, `gov_pop`, `opp_step`, `opp_act`, `pact_need`, `pact_can`, `pact_do`, `pacts_tick`, `pacts_after_election`, `opp_after_election`, `opp_show_offer`, `_gov_names`, `opp_resolve_offer`, `opp_status_text`, `opp_campaign`

Константы (5): `NO_PLAY_SLOTS`, `NO_GOV_SLOTS`, `OPP_ACTS`, `PACT_KINDS`, `PM_LEAD_START`

### `scripts/logic/aiparty.gd`  (981 строк)
Партийный ИИ: идеологии, политический капитал партий, правление без вас, законопроекты и поправки.

Функции (51): `autobalance_step`, `autopilot_step`, `ideo_keys`, `ideo_valid`, `lean_share`, `ideo_d`, `ideo_stat`, `party_arch`, `ideo_stance`, `ideo_target`, `gov_stance`, `gov_target`, `ai_def_lim`, `ai_policy_step`, `ideo_label`, `idl_planks`, `plank_dev`, `idl_mult`, `idl_step`, `idl_react`, `ideology_text`, `junior_info`, `junior_power`, `rel`, `rel_add`, `prm_base`, `prm_init`, `ai_init`, `ai_note`, `cap_swap`, `cap_unswap`, `autopilot_run`, `ai_parties_step`, `ai_party_act`, `ai_bloc_plan`, `ai_gov_rule`, `ai_recruit`, `ai_reshuffle`, `ai_pick_law`, `bill_of`, `bill_index`, `bill_forced`, `bill_preview`, `propose_variant`, `bill_request_new`, `bill_request`, `bill_pow_block`, `bill_amend`, `bills_step`, `bill_vote`, `ai_bill_vote`

Константы (1): `ARCH`

### `scripts/logic/council.gd`  (467 строк)
Совет коалиции (v35): партнёры голосуют по событиям, кабинету, бюджету и приёму новых партий;

Функции (26): `coal_members`, `coal_share`, `council_on`, `fx_utility`, `council_backers`, `council_fav`, `council_event_ok`, `council_event`, `council_split`, `council_event_note`, `council_min_yes`, `council_min_vote`, `council_budget`, `invite_offer_w`, `council_invite_vote`, `crisis_tol_pick`, `crisis_grand_pick`, `show_crisis_exit`, `resolve_crisis`, `party_abbr`, `upper_on`, `upper_gov`, `upper_renew`, `upper_summary`, `observer_start`, `observer_step`

Константы (2): `COUNCIL_TOL`, `UPPER_RENEW`

### `scripts/logic/radical.gd`  (470 строк)
Радикальные законы: форма правления, строй, выход из ЕС и т.д.

Функции (21): `arch_ps`, `RV`, `rid_of`, `regime_id`, `econ_id`, `decree_power`, `radical_bypass`, `radical_req`, `law_locked`, `auth_idx`, `radical_enact`, `open_mult`, `radical_dyn`, `radical_step`, `show_uprising`, `radical_roll`, `radical_text`, `active_rids`, `radical_events`, `radical_add_variants`, `radical_inject`

### `scripts/logic/agents.gd`  (264 строк)
Население: подключение агентов к голосованию, шагу и протестам.

Функции (15): `update_pop_windows`, `ag_k`, `ag_make_pos`, `ag_support_arr`, `ag_build`, `ag_calibrate`, `ag_zs`, `ag_zg`, `ag_step`, `ag_unrest_term`, `ag_region_table`, `ag_exit_report`, `ag_pick`, `ag_random_agent`, `ag_reset_ui`

### `scripts/logic/autopilot.gd`  (252 строк)
Помощник и автопилот.

Функции (13): `ap_can_adj`, `ap_note_change`, `ap_flush_log`, `autobalance_step`, `balance_now`, `apply_preset`, `fx_score`, `auto_event_pick`, `auto_event_ok`, `auto_resolve_event`, `autobuild_step`, `autopilot_step`, `advisor_lines`

### `scripts/logic/log.gd`  (204 строк)
Структурированный журнал.

Функции (21): `log_guess_cat`, `log_match`, `log_add`, `log_chip`, `log_render`, `log_cell`, `log_render_month`, `log_render_year`, `log_rebuild`, `log_clear`, `on_log_filter`, `build_log_filters`, `log_line`, `log_sys`, `log_header`, `log_tag`, `h12_push`, `h12_ago`, `h12_months`, `h12_label`, `h12_snap`

### `scripts/ui/ui_core.gd`  (1521 строк)
Интерфейс: окна, тема, верхняя панель, экран «Бюджет», обновление.

Функции (95): `build_dip_windows`, `build_econ_windows`, `build_election_window`, `build_event_window`, `build_fed_windows`, `build_fleet_windows`, `build_goods_windows`, `build_gov_windows`, `build_law_windows`, `build_map_windows`, `build_opp_windows`, `build_politics_windows`, `build_pop_windows`, `build_soc_windows`, `build_tech_windows`, `build_war_windows`, `ec_slider`, `make_tech_button`, `map_apply_mode`, `show_country_menu`, `update_dip_windows`, `update_econ_windows`, `update_fed_windows`, `update_fleet_windows`, `update_goods_windows`, `update_gov_windows`, `update_law_windows`, `update_opp_windows`, `update_parliament`, `update_regions_ui`, `update_soc_windows`, `update_tech_windows`, `update_war_windows`, `new_window`, `win_vis`, `on_win_close`, `win_menu_fill`, `on_win_menu`, `layout_windows`, `fix_wraps`, `fix_wraps_later`, `on_wrap_timer`, `reset_layout`, `show_desk`, `build_ui`, `add_title`, `add_note`, `make_fold`, `make_tail`, `set_tail_text`, `on_fold_toggled`, `on_detail_toggled`, `add_wrap_label`, `make_button`, `make_rt`, `add_slider`, `set_bar`, `build_budget_windows`, `build_log_and_event`, `update_slider_label`, `update_forecast`, `update_stats`, `update_polls`, `add_bar`, `color_button`, `refresh`, `on_slider`, `slider_value_for`, `configure_slider`, `toggle_slider_mode`, `make_theme`, `accent_for_desk`, `polish_tree`, `make_chip`, `set_chip`, `update_chips`, `draw_budget_viz`, `on_log_detail`, `show_tab`, `update_subbar`, `btn_icon`, `build_subbar`, `build_auto_window`, `on_ap_toggle`, `on_ap_target`, `on_ap_style`, `update_auto_window`, `on_floor_toggle`, `audio_ok`, `audio_load`, `audio_init`, `audio_apply_volume`, `music_next`, `sfx`, `toggle_music`

Константы (1): `WIN_DEFAULT_CLOSED`

Переменные (6): `music_player`, `sfx_players`, `sfx_cache`, `music_list`, `music_idx`, `sfx_last`

### `scripts/ui/ui_map.gd`  (1739 строк)
Интерфейс: карта, таблица регионов, региональная экономика.

Функции (66): `draw_war_overlay`, `draw_war_tokens`, `fed_btn`, `fed_opt`, `fed_pct`, `update_fregion`, `war_hover`, `war_map_click`, `on_layer_selected`, `fill_table_rows`, `fill_transfer_rows`, `rebuild_region_widgets`, `map_rebuild`, `map_prepare`, `map_tri_mesh`, `map_border_segs`, `map_view`, `map_country_rect`, `map_free_rect`, `map_fit_rect`, `map_zoom_cmd`, `map_zoom_at`, `map_clamp`, `unit_is_tiny`, `ate_at`, `unit_at`, `ctx_at`, `unit_tip`, `map_click`, `on_region_picked`, `map_apply_mode`, `on_map_input`, `build_map_windows`, `on_transfer_slider`, `on_table_row`, `set_sort`, `is_world_layer`, `layer_info`, `layer_leader`, `layer_color`, `cl_info`, `cl_color`, `unit_color`, `draw_map`, `region_tip`, `region_sort_value`, `update_regions_ui`, `update_region_table`, `update_transfer_ui`, `update_region_info`, `on_tool_selected`, `build_regecon_window`, `update_regecon`, `regecon_inject`, `ate_tip`, `fmt_people`, `ate_click`, `build_adm_window`, `adm_open`, `adm_opt_fill`, `adm_sel_regions_adjacent`, `update_adm_ui`, `on_adm_move`, `on_adm_create`, `on_adm_delete`, `on_adm_buy`

Константы (1): `MAP_HCELL`

Переменные (13): `reg_grid`, `transfer_parent`, `map_ate_tris`, `map_all_mesh`, `map_unit_mesh`, `map_ln_ate`, `map_ln_reg`, `map_ln_cty`, `map_hash`, `map_seg_cache`, `map_hover_ate`, `map_fit_cc`, `adm_ui`

### `scripts/ui/ui_politics.gd`  (334 строк)
Интерфейс: парламент, полукруг, таблица партий.

Функции (10): `select_neg_party`, `build_hemicycle`, `build_politics_windows`, `on_party_button`, `update_parliament`, `draw_hemi`, `on_hemi_input`, `update_party_table`, `update_party_detail`, `ministry_effect_text`

### `scripts/ui/ui_laws.gd`  (637 строк)
Интерфейс: окно законов.

Функции (21): `update_bill_window`, `build_law_windows`, `on_law_search`, `on_law_filter`, `law_demand_map`, `on_law_cat`, `on_topic_pressed`, `first_other_variant`, `on_card_input`, `on_adopt`, `on_negotiate`, `update_law_windows`, `update_law_effects`, `refit_law_cards`, `update_law_votes`, `build_law_slider`, `on_law_pow`, `on_law_slider`, `build_law_list`, `update_law_headers`, `update_law_detail`

### `scripts/ui/ui_gov.gd`  (425 строк)
Интерфейс: правительство и коалиционные переговоры.

Функции (20): `build_gov_windows`, `select_ministry`, `select_neg_party`, `on_neg_selected`, `on_neg_promise`, `on_neg_mins`, `on_neg_main`, `on_neg_conc`, `on_neg_dem`, `on_assign_ministry`, `on_replace_minister`, `update_gov_windows`, `update_coal_summary`, `update_cabinet`, `update_min_detail`, `refit_gov`, `update_neg`, `refit_neg`, `update_cabfx`, `update_commit`

### `scripts/ui/ui_econ.gd`  (458 строк)
Интерфейс: экран «Экономика».

Функции (14): `ec_slider`, `build_econ_windows`, `on_cb_auto`, `on_rate_slider`, `on_tariff_slider`, `on_roy_slider`, `on_focus_selected`, `on_chart_selected`, `update_chart`, `update_econ_windows`, `build_goods_windows`, `goods_market_color`, `update_goods_windows`, `_hot_txt`

### `scripts/ui/ui_world.gd`  (147 строк)
Интерфейс: дипломатия.

Функции (4): `select_dip`, `on_dip_far_ex`, `build_dip_windows`, `update_dip_windows`

### `scripts/ui/ui_pop.gd`  (330 строк)
Интерфейс: вкладка «Население».

Функции (4): `build_pop_windows`, `ag_tip`, `ag_agent_text`, `update_pop_windows`

Константы (1): `AG_GROUP_COLS`

### `scripts/ui/ui_events.gd`  (317 строк)
Интерфейс: окна событий и выборов.

Функции (6): `show_head_election`, `build_election_window`, `show_election`, `election_continue`, `build_event_window`, `refit_event`

### `scripts/ui/ui_fed.gd`  (608 строк)
Интерфейс: «Регионы и автономия» (desk 8) и «Территории» (desk 9).

Функции (28): `fed_btn`, `fed_opt`, `build_fregion_window`, `on_fregion_back`, `on_fregion_buy`, `fmap_sel_unit_valid`, `update_fregion`, `build_fed_windows`, `on_fed_reform`, `on_fed_eq`, `on_fed_meta`, `on_fed_comp`, `on_fed_bulk`, `on_fed_status`, `on_fed_admit`, `on_fed_demand`, `on_tw_changed`, `on_tw_buy`, `on_tw_union`, `on_tw_court`, `on_tw_sell`, `on_tw_admit`, `update_fed_windows`, `fed_pct`, `update_fed_desk`, `fed_why_text`, `tw_fill_options`, `update_terr_desk`

Константы (1): `TW_MULT`

Переменные (37): `fw_state_rt`, `fw_upper_rt`, `fw_btn_up`, `fw_btn_down`, `fw_eq_btns`, `fw_list_rt`, `fw_reg_rt`, `fw_comp_rows`, `fw_st_dn`, `fw_st_up`, `fw_admit_btn`, `fw_bulk_rows`, `fw_dem_box`, `tw_buy_pick`, `tw_buy_mult`, `tw_buy_how`, `tw_buy_rt`, `tw_buy_btn`, `tw_buy_units`, `tw_un_pick`, `tw_un_terms`, `tw_un_rt`, `tw_un_btn`, `tw_court_btn`, `tw_un_cc`, `tw_sell_lbl`, `tw_sell_pick`, `tw_sell_mult`, `tw_sell_rt`, `tw_sell_btn`, `tw_sell_cc`, `tw_sell_for`, `tw_terr_box`, `tw_stat_rt`, `fr_rt`, `fr_buy_btn`, `fr_back_btn`

### `scripts/ui/ui_soc.gd`  (293 строк)
Интерфейс: «Религия и миграция» (desk 11) и «Влияние и зависимость» (desk 10).

Функции (21): `soc_btn`, `build_soc_windows`, `on_soc_sec`, `on_soc_fund`, `on_soc_dialog`, `on_soc_mig`, `on_soc_prog`, `on_soc_sel`, `on_ex_meta`, `on_ex_deal`, `on_ex_tar`, `on_ex_aid`, `on_ex_dbuy`, `on_ex_favor`, `soc_eff_line`, `update_soc_windows`, `update_soc_desk`, `regions_rel0_vec`, `regions_rel0_nat`, `_soc_btn_state`, `update_ex_desk`

Переменные (14): `sw_rel_rt`, `sw_pol_rt`, `sw_mig_rt`, `sw_reg_rt`, `sw_btn`, `xw_list_rt`, `xw_info_rt`, `xw_btn`, `sw_chart`, `sw_regchart`, `sw_spk_t`, `sw_spk_n`, `xw_chart`, `xw_spk`

### `scripts/ui/ui_tech.gd`  (425 строк)
Интерфейс: окно «Технологии» (v42_1) — отдельное окно поверх игры: схема технологий, сводка, сооружения.

Функции (18): `make_tech_button`, `on_tech_toggle`, `set_tech_open`, `tech_scroll_to_frontier`, `build_tech_windows`, `on_tech_filter`, `on_tech_weight`, `on_tech_auto`, `on_tech_hover`, `on_tech_pick`, `on_tech_build`, `tech_bar`, `tech_info_text`, `tech_info_update`, `update_tech_windows`, `tech_clear`, `tech_build_buildings`, `tech_buildings_text`

Переменные (16): `tech_ov`, `tech_btn`, `tech_view`, `tech_scroll`, `tw_sum_rt`, `tw_info_rt`, `tw_spk`, `tw_bld_rt`, `tw_bld_box`, `tw_wlbl`, `tw_wbtn`, `tw_auto`, `tw_filter`, `tw_hover`, `tw_sig`, `tw_first`

### `scripts/ui/ui_opp.gd`  (209 строк)
Интерфейс: оппозиция и переговоры между партиями (экран «Политика»).

Функции (9): `build_opp_windows`, `on_bill_pick`, `on_bill_req`, `on_bill_amend`, `update_bill_window`, `on_opp_act`, `on_pact_party`, `on_pact_do`, `update_opp_windows`

Переменные (11): `opp_rt`, `opp_btns`, `pact_rt`, `pact_opt`, `pact_btns`, `pact_sel`, `bill_opt`, `bill_rt`, `bill_acc`, `bill_rej`, `bill_am`

### `scripts/ui/ui_fleet.gd`  (193 строк)
Экран «Флот» (desk 14): морская торговля, порты, военный флот, война на море.

Функции (7): `build_fleet_windows`, `on_fleet_merch`, `on_fleet_order`, `on_fleet_mission`, `on_fleet_port`, `on_fleet_station`, `update_fleet_windows`

Переменные (11): `fw_info_rt`, `fw_navy_rt`, `fw_inc_rt`, `fw_sea_rt`, `fw_pbox`, `fw_pkey`, `fw_btn`, `fw_btn_ports`, `fw_spk`, `fw_station`, `fw_station_ids`

### `scripts/ui/ui_war.gd`  (634 строк)
Экран «Армия и война» (desk 13): армия, мобилизация, объявление войны, ход войны, мир.

Функции (19): `build_war_windows`, `on_war_declare`, `update_war_talk`, `on_war_peace`, `war_select`, `update_war_windows`, `mil_side_total`, `war_map_on`, `war_occ_build`, `draw_war_overlay`, `war_token_pos`, `draw_war_tokens`, `draw_sea_lanes`, `war_ship`, `war_token_at`, `war_node_at`, `war_map_click`, `war_tip`, `war_hover`

Константы (2): `WAR_C0`, `WAR_C1`

Переменные (19): `war_army_rt`, `war_unit_rt`, `war_ops_rt`, `war_log_rt`, `war_list`, `war_list_key`, `war_btn`, `war_tgt`, `war_tgt_ids`, `war_note`, `war_msg`, `war_occ_ver`, `war_occ_tris`, `war_front`, `war_hover_tok`, `war_talk_rt`, `war_intl_rt`, `war_talk_chk`, `war_repar`

### `main.gd`  (831 строк)
PolitGame: корневой скрипт (вершина цепочки наследования, см. scripts/CHAIN.txt).

Функции (29): `country_arg`, `party_arg`, `seed_arg`, `apply_country`, `apply_markets`, `cdat`, `diff_color`, `menu_title`, `menu_rt`, `menu_bar`, `sector_shares`, `country_strengths`, `fill_country_card`, `opt_index`, `menu_update_est`, `opt_row`, `opt_choice`, `opt_slider`, `fmt_mult`, `fmt_k`, `build_settings_panel`, `opts_from_args`, `show_country_menu`, `fill_party_pick`, `update_menu_party`, `choose_country`, `_ready`, `_input`, `_unhandled_input`

Константы (1): `OBSERVER_ID`

Переменные (5): `menu_est_code`, `menu_sit_rt`, `menu_sit_code`, `menu_est_lbl`, `menu_ag_k`

## Классы (`scripts/classes/`)

- `agent_hist_view.gd` — extends Control, 25 строк
- `agent_map_view.gd` — extends Control, 228 строк
- `agent_pop.gd` — extends RefCounted, 600 строк
- `country_map.gd` — extends Control, 333 строк
- `dep_chart.gd` — extends Control, 54 строк
- `econ_chart.gd` — extends Control, 70 строк
- `election_view.gd` — extends Control, 183 строк
- `faith_chart.gd` — extends Control, 53 строк
- `float_window.gd` — extends Control, 251 строк
- `goods_view.gd` — extends Control, 61 строк
- `head_view.gd` — extends Control, 89 строк
- `ico.gd` — extends Control, 157 строк
- `market_bar.gd` — extends Control, 64 строк
- `pie_chart.gd` — extends Control, 45 строк
- `spark.gd` — extends Control, 49 строк
- `stat_bar.gd` — extends Control, 37 строк
- `tech_view.gd` — extends Control, 305 строк
