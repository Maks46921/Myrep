# Карта проекта (создаётся автоматически: `python3 tools/mapdoc.py`)

Скрипты игры образуют **цепочку наследования**: каждый файл `extends` предыдущий, вершина — `main.gd`. Порядок — в `scripts/CHAIN.txt`. Поэтому любая функция доступна из любого модуля; если модуль вызывает функцию из модуля ниже по цепочке, нужна «заглушка» — её создаёт `tools/stubs.py`.

## Цепочка

### `scripts/data/data_core.gd`  (19968 строк)
Справочные таблицы игры: группы, политика, уровни, рынки, цвета и т.п. (только const).

Функции (2): `ext_load`, `ext_load_countries`

Константы (143): `StatBar`, `PieChart`, `ElectionView`, `HeadView`, `FloatWindow`, `MarketBar`, `EconChart`, `AgentPop`, `AgentMapView`, `AgentHistView`, `Ico`, `FaithChart`, `DepChart`, `Spark`, `TechView`, `Flags`, `COUNTRY_CODES`, `GoodsView`, `CountryMap`, `PartyHemi`, `Gfx`, `EventArt`, `START_YEAR`, `PLAY_SPEEDS`, `PLAY_NAMES`, `MONTHS_GEN`, `MONTHS`, `COALITION_JOIN`, `COALITION_JOIN_PAID`, `COALITION_LEAVE`, `CONCESSION_COST`, `COL_GOOD`, `COL_BAD`, `COL_NEUTRAL`, `COL_HEAD`, `COL_WARN`, `COL_ELECT`, `COL_PURPLE`, `COL_TEAL`, `COL_DIM`, `COL_FAINT_HEX`, `C_TEXT`, `C_DIM`, `C_FAINT`, `C_GOOD`, `C_WARN`, `C_BAD`, `C_PURPLE`, `C_TEAL`, `REV_COLORS`, `EXP_COLORS`, `GROUPS`, `GROUP_FX`, `EXPECT_DRIFT`, `LEVELS`, `LEVEL_RATE`, `STATE_NAMES`, `LEVEL_EFFECTS`, `MIN_FX_SCALE`, `SAT_OFFSET`, `SAT_FATIGUE`, `SAT_FATIGUE_CAP`, `COAL_EVENTS`, `SAT_LEAVE`, `REG_KEYS`, `REG_TITLES`, `SECTOR_NAMES`, `GOV_KINDS`, `GOV_DESC`, `MAP_LAYERS`, `MAP_LAYER_ORDER`, `MAP_LEGENDS`, `MARKET_COLORS`, `GOOD_PROF`, `AG_GK`, `STRUCT_CATS`, `FOCUS_NAMES`, `FOCUS_IDS`, `RATE_NEUTRAL_REAL`, `ECON_FX_INFO`, `ECON_EVENTS`, `ECON_MEASURES`, `REGION_ACTIONS`, `LAW_CATS`, `LAW_CAT_COLORS`, `PRES_RULE_NAMES`, `MOD_INFO`, `MEASURES_BASE`, `HEAD_MEASURES`, `ACTIONS`, `NEWS`, `AG_STRIDE`, `AG_POLL_N`, `AG_ZK`, `HIST_KEYS`, `EC_CHART_NAMES`, `EC_CHART_COLORS`, `FUND_IDS`, `DEM_LAW`, `LAW_PARAMS_V11`, `PARAM_DEMANDS`, `DEM_BASE`, `MIL_DEMO`, `LOG_FILTERS`, `LOG_FILTER_CATS`, `LOG_CAT_COL`, `LOG_CAT_NAME`, `LOG_TAG_CAT`, `LOG_POL_WORDS`, `LOG_ECO_WORDS`, `AP_STYLES`, `AP_STYLE_TIPS`, `PRESETS`, `AP_BUILD_MAP`, `DIP_TRACKS`, `DIP_ACTIONS`, `DIP_LAYERS`, `DIP_REL_NAMES`, `DIP_EVENTS`, `DIP_SUMMITS`, `W_OPEN`, `W_KINDS`, `EMIT_MAX`, `RAD_MONARCHIES`, `RAD_AUTH`, `RAD_CUR`, `RAD_AUTH_TOPICS`, `RAD_MARKET_TOPICS`, `RSEC`, `SEC_COLORS`, `REG_TOOLS`, `REG_EVENTS_GEN`, `REG_EVENTS_CC`, `ELEC_DATA`, `WORLD_PCOL`, `WORLD_CCOL`, `WORLD_OPEN`, `WORLD_STANCE0`, `WORLD_TRADE`, `WORLD_REL`, `WORLD_LV0`, `WORLD_CTX`, `WORLD_CAPS`

Переменные (7): `C_BG`, `C_PANEL`, `C_PANEL2`, `C_BORDER`, `C_ACCENT`, `PROJECTS`, `WORLD`

### `scripts/data/data_content.gd`  (688 строк)
Крупные таблицы контента: события, законы, радикальные законы, карта мира.

Константы (4): `LAW_TOPICS_BASE`, `EVENTS`, `NEW_TOPICS`, `RAD_EVENTS`

Переменные (2): `WORLD_UNITS`, `ATE`

### `scripts/data/data_tech.gd`  (323 строк)
Технологии (v42_1): пять веток по 14 уровней на 100 лет вперёд (124 технологии; на 6 уровнях каждой ветки выбор «одна из 2–3») и специальные сооружения.

Константы (13): `TECH_NB`, `TECH_BRANCHES`, `TECHS`, `TECH_BUILDINGS`, `TECH_R0`, `TECH_CAP0`, `TECH_CAP_YEAR`, `TECH_FREE_BASE`, `TECH_FREE_SPAN`, `TECH_WAIT_MONTHS`, `TECH_PASSIVE`, `TECH_PASSIVE_CAP`, `TECH_AI_SCALE`

### `scripts/data/data_events.gd`  (567 строк)
События v46_1: общие для всех стран, с категориями, условиями, весами, рисками, отложенными последствиями и цепочками.

Константы (2): `EV_CATS`, `EVENTS_X`

### `scripts/data/data_countries.gd`  (6 строк)
Пакеты данных стран (генерируются tools/gen_data из Python-описаний).

Переменные (1): `CDATA`

### `scripts/data/data_corp.gd`  (615 строк)
v51_1: крупнейшие компании стран (отечественные: id, название, рынок, отрасль, доля государства %, выручка млрд €, работников тыс., примечание)

Константы (1): `CORP_DATA`

### `scripts/data/data_hist.gd`  (92 строк)
v52_1: исторические предпосылки. Черты национального характера (влияют на экономику, настроения, политику)

Константы (3): `HIST_TRAITS`, `COUNTRY_TRAITS`, `HIST_REL`

### `scripts/data/data_orgs.gd`  (218 строк)
v52_1: международные организации. Члены (из 38 стран игры; ext — остальные члены текстом), правило решений,

Константы (4): `ORG_ORDER`, `ORG_TYPES`, `ORG_RULES`, `ORGS`

### `scripts/state/state_data.gd`  (593 строк)
Таблицы, которые страна подменяет при запуске (REGIONS, LEAN, PARTY_NAMES и др.).

Переменные (73): `SEATS`, `MAJORITY`, `MAJ_BASE`, `POLICY`, `GROUP_WEIGHT`, `GROUP_BASE`, `PARTY_NAMES`, `PARTY_DESC`, `PARTY_COLORS`, `LEAN`, `HEMI_ORDER`, `PARTY_LEADERS`, `PARTY_DEMANDS`, `MINISTRIES`, `PARTY_MINISTRIES`, `MIN_SPECIAL`, `PARTY_TRAITS`, `PARTY_LAW_DEMAND`, `MINISTER_NAMES`, `GOV_NAMES`, `REGIONS`, `REG_BIAS`, `MARKETS`, `BASE_MODS`, `LAW_TOPICS`, `MEASURES`, `TERMS`, `INFO`, `UPPER`, `MACRO`, `REGIONAL_P`, `PROTEST_P`, `MARKETS_OVR`, `GOODS`, `GOODS_OVR`, `COALITION0`, `LAW_TAGS`, `PARCH`, `EVENTS_C`, `NEWS_C`, `EVENTS_SPECIAL`, `ARCHS`, `ELEC`, `AG`, `LOC_RULES`, `TOLERATE_W`, `SUPER`, `GDP0`, `G_POT`, `G_NEU`, `I_NEU`, `I_TGT`, `U_NEU`, `OTHER0`, `RATE0`, `DE_START_SEATS`, `DE_START_MIN`, `DE_PARAM`, `DE_NEW_PARAMS`, `DE_REMOVE` …

### `scripts/state/state.gd`  (863 строк)
Текущее состояние партии: показатели, законы, парламент, узлы интерфейса.

Переменные (506): `pending_code`, `pending_party`, `game_opts`, `ccode`, `map_reg_pick`, `emit_note`, `risk_prem`, `minority_ok`, `turn`, `year`, `month`, `gdp`, `debt`, `growth`, `inflation`, `unemployment`, `shock`, `other_rev`, `pol`, `pol_def`, `prev_pol`, `policy_by_key`, `lvl`, `support`, `bias`, `mods`, `cooldown`, `capital`, `cap_ai`, `ev_hist`, `ev_queue`, `ev_later`, `ev_log`, `noc_constr`, `tech_adj`, `tech_pas_mult`, `nato_ovr`, `free_adj`, `seats`, `in_coalition`, `warned`, `crisis_months`, `prev_head`, `h12`, `observer`, `deadlock`, `minority_gov`, `coal_talks`, `coal_tried`, `pm_lead`, `techno_until`, `extra_mins`, `cn_draft`, `cn_pat`, `cn_ans`, `cn_out`, `cn_round`, `coal_deal`, `neg_offer_mins`, `crisis_offered` …

### `scripts/logic/util.gd`  (411 строк)
Мелкие помощники: перевод, форматирование, цвета, даты.

Функции (52): `log_line`, `rt`, `tm`, `cap1`, `low1`, `build_loc`, `loc_latin_end`, `loc_rx`, `loc`, `loc_tree`, `jag_edge`, `pl_gov`, `pl_parl`, `pl_why`, `pl_deny`, `qn`, `sg`, `col_delta`, `find_by_id`, `policy_title`, `sat`, `mrate`, `years_passed`, `days_in_month`, `date_full`, `date_chip`, `days_until_months`, `days_text`, `date_text`, `turn_date`, `months_text`, `date_after`, `stat_color`, `total_pop`, `pop_ratio`, `amt`, `std_index`, `fx_col`, `sbox`, `make_dot_tex`, `scale_color`, `fmt_n`, `months_short`, `arrow_text`, `delta_col`, `col_signed`, `bit_text`, `good_col`, `hint_line`, `fmt_sg`, `date_short`, `polygon_area`

### `scripts/logic/policy.gd`  (1532 строк)
Бюджетная политика: ползунки, блокировки, уровни, эффекты, моды законов.

Функции (151): `add_commitment`, `adm_admin_mult`, `apply_econ`, `apply_psat`, `ar_apply_mods`, `au_fx`, `bq_alloc`, `bud_draft_on`, `church_fx`, `coal_members`, `coal_share`, `con_fx`, `configure_slider_range`, `council_on`, `cult_fx`, `demand_score`, `dip_all`, `dip_apply_mods`, `dip_fx_apply`, `dip_fx_text`, `ec_budget_lines`, `fed_tax_leak`, `fulfill_coalition_demands`, `good_name`, `goods_support_term`, `ideo_stance`, `ind_fx`, `log_tag`, `ministry_fx`, `mk_def`, `new_minister`, `radical_dyn`, `radical_roll`, `reg_avg`, `reg_zones_end`, `rel`, `sec_idx`, `slider_value_for`, `soc_fx`, `soc_tax`, `sync_ministers`, `tech_apply_mods`, `tech_edu_upkeep`, `transfer_avg`, `update_slider_label`, `variant_of`, `war_prem`, `world_help`, `approval`, `add_support`, `add_all_support`, `cap_spendable`, `cap_neg_risk`, `set_policy`, `reg_relig`, `reg_rel_k`, `apply_reg_delta`, `describe_reg`, `region_support`, `split_subsidies`, `expected`, `factor`, `fatigue`, `target_support`, `target_gov_support`, `budget_changes`, `describe_fx`, `apply_fx`, `aid_now`, `compute_budget`, `update_levels`, `pp0`, `expected_pp`, `is_abs`, `pol_hi`, `slider_hi`, `abs_range`, `sync_abs_policies`, `lock_active`, `add_lock`, `lock_allowed`, `lock_allowed_share`, `lock_until_text`, `lock_note`, `expire_locks`, `emit_cap`, `sync_emit`, `emit_safe_pct`, `emit_excess`, `lvl_sum`, `issue_multiplier`, `regional_potential`, `per_capita`, `avg_per_capita`, `tier_name`, `dev_gain_mult`, `tax_ratio`, `project_cost_pct`, `roi_estimate`, `roi_text`, `effective_reg`, `demand_cur`, `is_hybrid`, `pw_of`, `scale_dict`, `funding_mode`, `party_funded`, `funding_mult`, `init_laws`, `law_start_idx`, `parl_term`, `pres_term`, `impeach_seats`, `crisis_limit`, `compute_mods`, `recompute_mods`, `scale_fx`, `mod_good_dir`, `boost_good`, `describe_econ`, `debt_rate`, `bud_mark`, `bud_pending`, `bud_changes`, `oneoff_cap_ok`, `oneoff_left`, `oneoff_why`, `oneoff_pay`, `oneoff_set`, `oneoff_year_reset`, `bud_tr_snap`, `bud_tr_check`, `bud_tr_changed`, `bud_tr_old`, `bud_tr_old_avg`, `bud_tr_restore`, `bud_change_text`, `tr_shift`, `bud_title`, `bud_stance`, `bud_hold_begin`, `bud_tr_unhold`, `bud_hold_end`, `bud_partner_view`, `bud_hold_end_quiet`, `bud_council`, `bud_needs_council`, `bud_apply`, `bud_cancel`, `bud_drop_disputed`, `bud_persuade`

Константы (3): `DEM_GROWTH_CAP`, `AGRI_FX`, `HYBRID_IDS`

Переменные (7): `bud_base`, `bud_persuaded`, `bud_tr_base`, `oneoff_cap`, `oneoff_cap0`, `oneoff_used`, `oneoff_log`

### `scripts/logic/laws.gd`  (1524 строк)
Законы: варианты, голосование, числовые законы, меры и действия.

Функции (90): `ch_law_label`, `decree_power`, `democracy_index`, `hold_parliament`, `junior_info`, `law_locked`, `martial_on`, `national_shares`, `pact_has`, `party_stance`, `propose_variant`, `radical_bypass`, `radical_enact`, `radical_req`, `refresh`, `rid_of`, `sfx`, `vote_show`, `meas_quarter`, `meas_q_used`, `meas_min`, `meas_holder`, `meas_partner_against`, `meas_resp_text`, `meas_head_why`, `meas_why`, `do_measure`, `do_action`, `level_effects_text`, `fx_items`, `reg_item`, `fx_pros_cons`, `layer_ramp`, `level_effect_list`, `law_tweak`, `variant_of`, `variant_part`, `cur_idx`, `law_cost`, `dict_diff`, `support_delta`, `variant_stance`, `variant_votes`, `party_dissent`, `party_vote_split`, `upper_check`, `upper_text`, `negotiate_variant`, `adopt_variant`, `mod_item`, `mod_channel`, `mod_visible`, `vote_next_text`, `range_factor`, `range_part`, `range_tip`, `thr_party_info`, `variant_effect_items`, `rg_drip_step`, `items_pros_cons`, `pres_needs_runoff`, `law_reform_count`, `law_demand_of`, `law_demand_met`, `law_demand_text`, `fmt_param`, `param_grid`, `make_param_topic`, `build_law_topics`, `sq_effects`, `variant_own_items`, `is_fund`, `law_need`, `demand_idx`, `demand_dict_met`, `param_scale_text`, `variant_swing`, `law_years`, `law_scaled`, `law_fit_generic`, `law_text_apply`, `de_law_params`, `de_fix_ps`, `de_adapt_topics`, `brake_allowed`, `brake_active`, `brake_step`, `brake_text`, `snap_info`, `snap_votes`

Константы (9): `MEAS_RESP`, `MEAS_Q_LIMIT`, `POW_MODERATION`, `CHAN_WIDTH`, `NO_RANGE`, `CHAN_WHY`, `MERGE_STAT`, `SQ_K`, `SNAP_RULES`

Переменные (3): `last_vote`, `vote_notes`, `vote_live`

### `scripts/logic/goods.gd`  (167 строк)
Товары: потребительская корзина (18 видов), их цены и спрос, корзины групп населения.

Функции (15): `ind_cat_term`, `good_def`, `good_name`, `apply_goods`, `goods_init`, `prof_mult`, `goods_demand`, `goods_prices`, `goods_shock`, `good_yoy`, `cpi_goods`, `group_cpi`, `group_gap`, `goods_support_term`, `group_top_goods`

### `scripts/logic/economy.gd`  (564 строк)
Экономика: рынки, сооружения, центробанк, торговля, шаг экономики.

Функции (34): `con_struct_extra`, `world_ea_update`, `mk_def`, `init_economy`, `tariff_rev_share`, `import_share`, `roy_rev_share`, `ec_budget_lines`, `struct_count`, `struct_total`, `struct_cond_factor`, `struct_lvl_k`, `struct_step`, `complete_struct`, `repair_cost_pct`, `repair_all`, `struct_total_count`, `world_step`, `cb_target`, `cb_name`, `cb_step`, `set_rate`, `income_parts`, `households_step`, `bconf_reasons`, `business_step`, `gov_idx`, `markets_step`, `trade_step`, `economy_step`, `hist_push`, `apply_econ`, `region_struct_text`, `struct_effect_text`

### `scripts/logic/regions.gd`  (806 строк)
Регионы: лояльность, недовольство, проекты, региональная экономика.

Функции (65): `adm_dev_term`, `ag_unrest_term`, `ate_name`, `au_unr_term`, `bld_money_month`, `bq_add`, `bq_cancel`, `bq_has`, `bq_in_region`, `bq_migrate`, `bq_month`, `bq_rate`, `church_loy_term`, `church_unr_term`, `con_mega_done`, `con_start_check`, `con_unr_term`, `con_upgrade_done`, `cult_loy_term`, `cult_unr_term`, `fed_auto_term`, `fed_dev_term`, `fed_loy_term`, `fed_unr_term`, `soc_loy_term`, `soc_unr_term`, `update_forecast`, `update_transfer_ui`, `select_region`, `reg_avg`, `recalc_weights`, `new_governor`, `transfer_avg`, `update_regions`, `complete_project`, `complete_project_pr`, `proj_group_fx`, `proj_group_text`, `project_start_at`, `region_main_ate`, `start_project`, `cancel_project`, `appoint_governor`, `set_transfer`, `equalize_transfers`, `do_region_action`, `region_ok`, `de_start_parliament`, `calibrate_regions`, `calibrate_region`, `build_geometry`, `sec_idx`, `sec_cur`, `dominant_sector`, `reg_growth`, `rdebt_target`, `reg_zones_end`, `reg_econ_step`, `reg_year_report`, `reg_events_all`, `tool_req`, `tool_effect_text`, `reg_tool_factor`, `tool_cost_pct`, `reg_tool_buy`

Константы (1): `PROJ_GROUP_FX`

### `scripts/logic/elections.gd`  (1263 строк)
Выборы: голоса, места, президентские и парламентские выборы, конкуренция партий.

Функции (83): `ag_exit_report`, `ag_region_table`, `ai_form_gov`, `au_after_election`, `au_control`, `au_fraud_shares`, `au_on`, `au_opp_mult`, `church_vote_mult`, `coal_feasible`, `coal_manual`, `coal_talks_start`, `coalition_names`, `cu_nat_tension`, `cult_vote_mult`, `form_government`, `gov_ok`, `gov_seats`, `is_cordon`, `log_header`, `martial_blocks`, `mil_at_war`, `opp_after_election`, `opp_campaign`, `opp_enter`, `opp_gov_seats`, `opp_gov_text`, `opp_to_gov`, `pact_mult`, `present_event`, `radical_text`, `show_election`, `show_head_election`, `swap_idx`, `upper_renew`, `gov_roles`, `gov_pm_party`, `vote_weights`, `reg_loy_start`, `region_shares`, `region_shares_legacy`, `parl_shares`, `hare_seats`, `smd_frac`, `smd_power`, `allocate_seats`, `sorted_parties`, `head_cand_ok`, `head_cand_name`, `head_row`, `head_term_months`, `hold_head`, `hold_head_core`, `head_outcome`, `head_present`, `hold_head_direct`, `hold_head_indirect`, `hold_head_council`, `head_campaign_check`, `hold_parliament`, `hold_parliament_core`, `election_title`, `campaign_check`, `party_attitude`, `electorate_text`, `national_shares`, `democracy_index`, `democracy_name`, `apply_competition`, `democracy_text`, `sham_shares`, `er_on`, `er_crisis`, `er_gov`, `er_gov_years`, `er_arch`, `er_populist`, `er_mig_mult`, `er_neff`, `er_ceiling`, `er_swing`, `er_apply`, `er_tip`

Константы (6): `ER_DEM`, `ER_CAP0`, `ER_CAP_MAX`, `ER_SWING0`, `ER_SWING_MAX`, `ER_VOLATILE`

### `scripts/logic/coalition.gd`  (1543 строк)
Коалиция и правительство: партии, министры, требования, вотум недоверия.

Функции (110): `bud_neg_open`, `cn_auto_open`, `cn_close`, `council_expel_vote`, `council_invite_vote`, `council_min_vote`, `end_game`, `invite_offer_w`, `party_abbr`, `party_lean`, `rel_add`, `show_crisis_exit`, `war_sat_term`, `can_govern`, `is_cordon`, `tolerates`, `against_seats`, `gov_ok`, `gov_margin`, `seat_pad`, `gov_seats`, `coalition_names`, `opp_bloc`, `check_impeachment`, `party_stance`, `floor_share`, `auto_floor`, `demand_value`, `demand_met`, `demand_score`, `demand_lines`, `port_score`, `sat_target`, `sat_reason`, `grant_ministries`, `release_ministries`, `assign_ministries`, `add_member`, `remove_member`, `cycle_ministry`, `select_party`, `do_concession`, `fulfill_demands`, `fulfill_party_demands`, `fulfill_coalition_demands`, `form_government`, `check_government`, `show_no_confidence`, `resolve_no_confidence`, `toggle_coalition`, `ministries_of`, `ministry_fx`, `ministry_is_special`, `ministry_role_text`, `ministry_items`, `new_minister`, `sync_ministers`, `cabinet_items`, `assign_ministry`, `replace_minister`, `reshuffle_cabinet`, `quota_for`, `sat_breakdown`, `willingness`, `add_commitment`, `check_commitments`, `invite_party`, `coal_text`, `pick_weighted_partner`, `coal_pick`, `show_coal_event`, `apply_psat`, `coal_manual`, `coal_cands`, `coal_feasible`, `coal_talks_start`, `coal_talks_done`, `coal_w_text`, `coal_talks_event`, `coal_resolve`, `cn_min_w`, `cn_w_total`, `cn_why`, `cn_can_talk`, `cn_parties`, `cn_new_draft`, `cn_ensure`, `cn_seats`, `cn_got_w`, `cn_fair_w`, `cn_auto_mins`, `cn_toggle_party`, `cn_set_tol`, `cn_set_pm`, `cn_set_min`, `cn_toggle_list`, `cn_law_open`, `cn_bud_open`, `cn_voters`, `cn_score`, `cn_verdict`, `cn_against`, `cn_block`, `cn_cost`, `cn_neg_reasons`, `cn_propose`, `cn_sign`, `cn_month`, `cn_breach`, `cn_deal_holder`

Константы (5): `GOV_EXCLUDE`, `CORDON_JOIN`, `CN_MIN_W`, `CN_PAT`, `CN_PAY`

### `scripts/logic/events.gd`  (974 строк)
События и новости.

Функции (59): `auto_event_ok`, `auto_event_pick`, `auto_resolve_event`, `cap_swap`, `cap_unswap`, `council_event`, `council_event_note`, `council_event_ok`, `council_split`, `ev_ext_val`, `fleet_resolve`, `flt_has_sea`, `inbox_route`, `io_member`, `io_members`, `io_ready`, `mil_resolve`, `opp_resolve_offer`, `radical_events`, `realism_resolve`, `resolve_crisis`, `revolt_resolve`, `set_time_btns`, `win_fade_in`, `ev_de_only`, `ev_org_blocked`, `event_ok`, `ev_id`, `ev_cond_ok`, `ev_weight`, `ev_pick`, `ev_by_id`, `ev_text`, `ev_rand_region`, `ev_opt_score`, `ev_fx_score`, `ev_title`, `strip_capital_note`, `fx_no_capital`, `ev_opt_block`, `ev_first_ok`, `_ev_chain_due`, `ev_tick`, `ev_after_choice`, `show_news`, `ev_kind_info`, `ev_kind_info0`, `ev_style`, `ev_context_text`, `ev_for_player`, `present_event`, `econ_pool`, `show_event`, `choose`, `dip_events`, `dip_summit_orgs`, `gen_dip_event`, `w_help_event`, `fire_scripted`

Константы (4): `EV_ORG_WORDS`, `EV_COOLDOWN`, `EV_LATER_MAX`, `SUMMIT_ORGS`

### `scripts/logic/turn.gd`  (901 строк)
Ход игры: один месяц, конец игры, начальная установка состояния.

Функции (106): `adm_month`, `ag_build`, `ag_step`, `ai_init`, `ai_parties_step`, `ate_reset`, `au_init`, `autopilot_run`, `bills_step`, `cap_mults`, `cap_sources`, `church_init`, `church_month`, `con_init`, `con_month`, `council_budget`, `cult_g`, `cult_init`, `cult_month`, `dip_init`, `dip_step`, `diplo_month`, `dx_init`, `es_init`, `ex_g`, `ex_infl`, `ex_init`, `ex_month`, `fa_init`, `fa_month`, `fed_init`, `fed_month`, `fleet_day`, `fleet_g`, `fleet_infl`, `fleet_init`, `fleet_month`, `h12_snap`, `idl_step`, `inbox_month`, `ind_g`, `ind_init`, `ind_month`, `io_init`, `junior_quit`, `log_add`, `map_cam_step`, `martial_step`, `mil_day`, `mil_g`, `mil_infl`, `mil_init`, `mil_month`, `mil_start_ongoing`, `mil_unemp`, `observer_step`, `opp_init`, `opp_step`, `pa_month`, `radical_step`, `realism_month`, `revolt_g`, `revolt_init`, `revolt_month`, `revolt_nationwide_uprising`, `revolt_unemp`, `rl_g`, `rl_infl`, `rl_init`, `rules_month`, `soc_g`, `soc_init`, `soc_month`, `soc_unemp`, `tech_init`, `tech_month`, `ui_anim_step`, `world_init`, `world_spill_g`, `world_spill_infl`, `wsim_step`, `set_speed`, `on_play_toggled`, `on_speed_selected`, `set_time_btns`, `blocked`, `day_tick`, `advance_day`, `advance_days`, `advance_month`, `_process`, `log_policy_changes`, `macro_step`, `cap_rate`, `debt_erode`, `debt_drag`, `rt`, `week_tick`, `take_month_snap`, `next_turn`, `next_turn_core`, `log_month`, `log_year_summary`, `end_game`, `init_state`, `skip_months`

### `scripts/logic/world.gd`  (825 строк)
Дипломатия и живой мир.

Функции (58): `con_ai_g`, `ex_bot_g`, `fa_explain`, `fa_hit`, `fa_rel_term`, `hist_mult`, `hist_rel`, `mil_dip_term`, `open_mult`, `foreign_region_text`, `dip_init`, `dip_rel_name`, `dip_target`, `dip_rel_factor`, `dip_growth`, `dip_sec`, `dip_infra_bonus`, `dip_avg_rel`, `dip_apply_mods`, `dip_change`, `dip_step`, `track_name`, `dip_fx_apply`, `dip_fx_text`, `dip_do_action`, `dip_track_cost`, `dip_upgrade`, `dip_downgrade`, `w_codes`, `w_unrec`, `w_minor`, `world_init`, `w_stance_name`, `w_link`, `w_share`, `w_cur_growth`, `w_pot`, `world_spill_g`, `w_shock_g`, `world_spill_infl`, `world_ea_update`, `w_start_crisis`, `world_help`, `w_election`, `w_player_stance`, `w_shock_step`, `w_party_name`, `w_party_for`, `w_fund_parties`, `w_fund_check`, `w_fund`, `w_fund_step`, `wsim_step`, `world_infl_bias`, `world_news`, `world_info`, `remap_base_ps`, `dip_all`

Константы (5): `W_SANCT0`, `W_SANCT_JOIN`, `W_ARCH_STANCE`, `W_FUND_CAP`, `W_FUND_MONTHS`

### `scripts/logic/federation.gd`  (1265 строк)
Федерация, автономия субъектов и передача территорий (покупка региона, добровольное объединение стран).

Функции (76): `ate_unit_has_capital`, `church_init_region`, `cult_init_region`, `map_rebuild`, `soc_init_region`, `fed_cfg`, `fed_reset_world`, `fed_init`, `fed_region_init`, `fed_new_sub`, `fed_d`, `fed_shock`, `fed_loy_term`, `fed_unr_term`, `fed_dev_term`, `fed_auto_term`, `fed_tax_leak`, `fed_max_level`, `fed_coal_share`, `fed_dom`, `fed_upper`, `fed_ref_p`, `fed_roll`, `fed_cd_get`, `fed_cap_ok`, `fed_comp_cost`, `fed_comp_check`, `fed_comp_step`, `fed_comp_all`, `fed_status_check`, `fed_status_step`, `fed_set_eq`, `fed_reform_check`, `fed_reform`, `fed_party_for_bloc`, `fed_make_upper`, `fed_admit_check`, `fed_admit`, `fed_month`, `fed_idx_of_uid`, `fed_demand_of`, `fed_demand_text`, `fed_demand_decide`, `fed_world_cc`, `fed_wreg`, `fed_wreg_gdp`, `fed_unit_is_capital`, `fed_unit_cc`, `fed_set_unit_cc`, `fed_backup_world`, `fed_adjacent_units`, `fed_rel`, `fed_court`, `fed_pc_ratio`, `fed_avg_dict`, `fed_take_unit`, `fed_rebuild_world_side`, `fed_rebuild`, `fed_calibrate_new`, `fed_news_world`, `terr_price`, `terr_buy_quote`, `terr_buy`, `terr_sell_buyers`, `fed_ui_of_region`, `terr_sell_quote`, `terr_sell`, `terr_transfer`, `fed_drop_region`, `union_candidates`, `union_quote`, `union_do`, `union_absorb`, `fed_comp_text`, `fed_region_line`, `fed_stats`

Константы (9): `FED_SPH`, `FED_LV`, `FED_LV_DESC`, `FED_LVL_NAMES`, `FED_ST`, `FED_EQ`, `FED_W`, `FED_K`, `FED_SHOCK`

Переменные (6): `FED`, `fst`, `fed_u0`, `fed_w0`, `fed_ui`, `fed_rng`

### `scripts/logic/admin.gd`  (923 строк)
v36: административно-территориальные единицы (АТЕ) и административные реформы.

Функции (47): `ate_load`, `ate_nbs`, `ate_at_point`, `ate_reset`, `ate_rebuild`, `ate_unit_center`, `ate_alive`, `ate_unit_has_capital`, `ate_cc`, `ate_region`, `ate_share`, `ate_pop`, `ate_name`, `ate_groups`, `ate_touches`, `adm_region_ui`, `adm_region_ates`, `adm_region_km`, `adm_region_nbs`, `adm_devf`, `adm_pot`, `adm_mix_blend`, `adm_blend`, `adm_absorb`, `adm_new_region`, `adm_upper_seat`, `adm_cost`, `adm_common_check`, `adm_sel_own`, `adm_sel_pop`, `adm_left_check`, `adm_move_check`, `adm_create_check`, `adm_delete_check`, `adm_aftermath`, `adm_dev_term`, `adm_month`, `adm_admin_mult`, `adm_apply_moves`, `adm_move`, `adm_create`, `adm_delete`, `adm_rename`, `ate_buy_quote`, `adm_sel_km`, `ate_buy`, `ate_attach`

Константы (5): `ADM_CD`, `ADM_SHOCK`, `ADM_MAX_REG`, `ADM_BLEND`, `ADM_BLEND_D`

Переменные (1): `ate_k`

### `scripts/logic/society.gd`  (542 строк)
Религии и миграция. У каждого региона — религиозный состав; у каждого агента — своя вера.

Функции (39): `cult_mig`, `ex_fx`, `ex_rel_change`, `soc_cfg`, `soc_dyn`, `soc_vec`, `soc_init`, `soc_init_region`, `soc_national`, `soc_div`, `soc_delta_dot`, `soc_abs_dot`, `soc_nat_delta`, `soc_nat_abs`, `soc_din`, `soc_dout`, `soc_skill`, `soc_skill0`, `soc_mix_eff`, `soc_mig_faith`, `soc_loy_term`, `soc_unr_term`, `soc_g`, `soc_unemp`, `soc_tax`, `soc_month`, `soc_push_event`, `soc_events`, `soc_fx`, `soc_cd_get`, `soc_spend`, `soc_set_mig`, `soc_set_prog`, `soc_set_sel`, `soc_set_sec`, `soc_set_fund`, `soc_dialog`, `soc_dominant`, `soc_effect_text`

Константы (10): `SOC_FAITH`, `SOC_FCOL`, `SOC_FX`, `SOC_FNOTE`, `SOC_MIGM`, `SOC_IN_CAP`, `SOC_MIGN`, `SOC_PROG`, `SOC_SEC`, `SOC_SEL`

Переменные (3): `SOC`, `soc`, `soc_rng`

### `scripts/logic/culture.gd`  (840 строк)
v55_1: народы (культуры). У каждого региона — состав по народам (словарь id → доля), народы объединены в группы.

Функции (61): `con_rb`, `rv_add_hate`, `cu_cfg`, `cu_def`, `cu_name`, `cu_grp`, `cu_grp_name`, `cu_col`, `cu_vec`, `cu_pw`, `cu_on`, `cult_init`, `cult_init_region`, `cu_tit_list`, `cu_is_tit`, `cu_is_prot`, `cu_is_mig`, `cu_home`, `cu_prox`, `cu_country_prox`, `cu_national`, `cu_national0`, `cu_sorted`, `cu_minority_share`, `cu_dominant`, `cu_region_tit`, `cu_restrict`, `cu_dr`, `cu_griev`, `cu_target_t`, `cu_nat_tension`, `cu_dt`, `cult_loy_term`, `cult_unr_term`, `cult_sep_term`, `cult_g`, `cu_mig_share`, `cult_vote_mult`, `cu_party_cult`, `cult_month`, `cu_norm`, `cu_tit_share`, `cult_mig`, `cu_mig_mix`, `cu_kin_list`, `cu_kin_month`, `cu_diaspora`, `cu_dia_month`, `cu_events`, `cu_region_minority`, `cu_fire`, `cult_fx`, `cu_cd_get`, `cu_spend`, `cu_pol_names`, `cu_set_pol`, `cu_dialog`, `cu_region_autonomy`, `cu_set_dia`, `cu_diplomacy`, `cu_effect_text`

Константы (11): `CU_LANG`, `CU_SCHOOL`, `CU_AUTO`, `CU_COURSE`, `CU_FUND`, `CU_POL_MAX`, `CU_POL_COST`, `CU_MIG_GROUPS`, `CU_LOY_K`, `CU_UNR_K`, `CU_SEP_K`

Переменные (3): `CU`, `cu`, `cu_rng`

### `scripts/logic/church.gd`  (612 строк)
v55_1: церковь и религиозная политика. Главная церковь страны (из data/cult.dat): влияние, отношения с властью,

Функции (43): `con_rb_nat`, `ch_on`, `ch_law_label`, `church_init`, `ch_init_piety`, `church_init_region`, `ch_nat_piety`, `ch_riv_target`, `ch_believers`, `ch_faith_name`, `ch_state_name`, `ch_is_moral`, `ch_score`, `ch_laws`, `ch_mismatch`, `ch_rel_target`, `ch_drel`, `church_loy_term`, `ch_state_other`, `ch_state_other0`, `church_unr_term`, `church_vote_mult`, `church_month`, `ch_fin_cost_now`, `ch_prom_step`, `ch_holi_list`, `ch_holidays`, `ch_fire_holiday`, `ch_fire_minority_holiday`, `ch_push`, `ch_events`, `ch_cd_get`, `ch_fire_demand`, `ch_fire_temple`, `ch_fire`, `church_fx`, `ch_spend`, `ch_set_state`, `ch_set_fin`, `ch_meet`, `ch_criticize`, `ch_rival`, `ch_effect_text`

Константы (7): `CH_FIN`, `CH_FIN_COST`, `CH_LAW_KEYS`, `CH_LAW_SKIP`, `CH_HOLI`, `CH_LOY_K`, `CH_VOTE_K`

Переменные (2): `ch`, `ch_rng`

### `scripts/logic/industry.gd`  (417 строк)
v55_1: подробные товары и промышленность.

Функции (32): `ar_ind`, `con_ind`, `fa_ws_lvl`, `ind_on`, `ind_dyn`, `gi_def`, `gx_def`, `gi_ids`, `gx_ids`, `gx_of_cat`, `ind_init`, `ind_ss`, `ind_ss0`, `ind_block`, `ind_prem_step`, `ind_dprem`, `ind_cat_term`, `ind_g`, `ind_arms_price`, `ind_month`, `ind_hist`, `ind_yoy`, `gx_price`, `gi_price`, `gx_name`, `gi_name`, `ind_add_boost`, `ind_exports`, `region_goods`, `ind_imports`, `ind_events`, `ind_fx`

Константы (3): `IND_BLOCK`, `IND_TECH`, `IND_W`

Переменные (2): `ind`, `ind_rng`

### `scripts/logic/tech.gd`  (886 строк)
Технологии (v39_1): три ветки исследований, специальные сооружения, скорость исследований с мягким потолком.

Функции (64): `ex_dep`, `ex_partners`, `mil_land_neighbor`, `tech_init`, `tech_def`, `tech_bdef`, `tech_done`, `tech_alts`, `tech_lane`, `tech_lanes_build`, `tech_lane_name`, `tech_swap_check`, `tech_swap`, `tech_is_choice`, `tech_tier_done`, `tech_missing`, `tech_avail`, `tech_freedom`, `tech_sum`, `tech_bsum`, `tech_power`, `tech_edu_term`, `tech_cap`, `tech_raw`, `tech_soft`, `tech_refresh_rates`, `tech_apply_mods`, `tech_edu_upkeep`, `tech_build_missing`, `tech_build`, `tech_select`, `tech_set_weight`, `tech_auto_pick`, `tech_rq`, `tech_never`, `tech_q_add`, `tech_q_del`, `tech_q_move`, `tech_q_next`, `tech_choice_waiting`, `tech_progress`, `tech_total`, `tech_count`, `tech_month`, `tech_fx_text`, `tech_nb`, `tech_hash`, `tech_nb_pace`, `tech_nb_tiers`, `tech_nb_has`, `tech_nb_who`, `tech_nb_share`, `tech_passive_rate`, `tech_state_player`, `tech_state_neutral`, `tech_needs_player`, `tech_needs_from`, `tech_threat`, `tech_needs_bot`, `tech_score`, `tech_score_text`, `tech_ai_pick`, `tech_nb_pick`, `tech_audit_profiles`

Константы (1): `TECH_SUBS`

Переменные (3): `tech`, `tech_idx`, `tech_lane_cache`

### `scripts/logic/influence.gd`  (368 строк)
Экономическое влияние и зависимость: ваша страна ⇄ остальные страны мира (боты).

Функции (22): `fa_notify`, `fa_sanctioning`, `ex_init`, `ex_partners`, `ex_rel_change`, `ex_cd_get`, `ex_dep`, `ex_leverage`, `ex_leverage_on_us`, `ex_g`, `ex_infl`, `ex_bot_g`, `ex_month`, `ex_events`, `ex_fx`, `ex_cap`, `ex_deal_set`, `ex_tariff_set`, `ex_aid_give`, `ex_dbuy_amt`, `ex_dbuy_set`, `ex_favor`

Константы (4): `EX_DEAL`, `EX_TAR`, `EX_GAIN`, `EX_LOSS`

Переменные (2): `ex`, `ex_rng`

### `scripts/logic/fleet.gd`  (544 строк)
Флот и морская торговля (v30): порты, морские пути, инциденты, военно-морской флот.

Функции (33): `fleet_load`, `flt_ports_of`, `flt_port`, `flt_has_sea`, `flt_port_split`, `flt_path`, `flt_path_len`, `fleet_init`, `fleet_power`, `fleet_class`, `fleet_cover`, `fleet_scale`, `fleet_port_util`, `fleet_util`, `fleet_sea_gdp`, `fleet_g`, `fleet_infl`, `fleet_recalc_f`, `fleet_log`, `fleet_day`, `fleet_incident`, `fleet_present_event`, `fleet_resolve`, `fleet_month`, `fleet_port_cost`, `fleet_port_invest`, `fleet_can_build`, `fleet_order`, `fleet_set_mission`, `fleet_merch`, `fleet_ports_summary`, `fleet_lane_edges`, `fleet_status_text`

Константы (2): `FLT_KINDS`, `FLT_MISSIONS`

Переменные (5): `FLEET`, `flt`, `flt_rng`, `flt_nodes`, `flt_path_cache`

### `scripts/logic/military.gd`  (2364 строк)
v37: армии, войны и захват территорий.

Функции (152): `ar_air_mult`, `ar_ammo_use`, `ar_att`, `ar_auto_type`, `ar_cap_mult`, `ar_combined`, `ar_def`, `ar_deterred`, `ar_eq`, `ar_init`, `ar_mis_k`, `ar_mob_speed`, `ar_month`, `ar_org_mult`, `ar_pow_mult`, `ar_q_mult`, `ar_rsv`, `ar_unit_name`, `ar_war_g`, `ar_war_infl`, `ar_war_start`, `ar_wm`, `fa_war_ended`, `talk_apply`, `talk_avail`, `talk_border_ates`, `talk_budget`, `talk_ceasefire`, `talk_cost`, `talk_mediator`, `talk_pkg_text`, `talk_terms`, `war_demo`, `war_dip_extra`, `war_intl`, `war_intl_g`, `war_intl_infl`, `war_intl_init`, `war_intl_month`, `war_on_declare`, `war_sanctions_update`, `war_timers_month`, `war_trade_g`, `war_vote`, `war_vote_text`, `mil_is_nato`, `mil_init`, `mil_start_ongoing`, `mil_on`, `mil_n_units`, `mil_cap`, `mil_spend_ratio`, `mil_q`, `mil_unit_name`, `mil_new_unit`, `mil_unit`, `mil_units_of`, `mil_cc_ates`, `mil_home_spots`, `mil_border_spots`, `mil_owner`, `mil_ctl`, `mil_at_war`, `mil_side`, `mil_at_war_with`, `mil_hostile`, `mil_side_ccs`, `mil_pw`, `mil_side_power`, `mil_total`, `mil_regular_total`, `mil_reserve_k`, `mil_mob_k`, `mil_country_power`, `mil_log`, `mil_idx`, `mil_un_build`, `mil_passable`, `mil_bfs`, `mil_reached`, `mil_path_to`, `mil_coast_build`, `mil_home_node`, `mil_port_nodes`, `mil_recruit_check`, `mil_min_unit`, `mil_recruit`, `mil_mob_check`, `mil_mobilize`, `mil_mob_arrive`, `mil_order_move`, `mil_order_mode`, `mil_targets`, `mil_land_neighbor`, `mil_allies_for`, `mil_declare_check`, `mil_declare`, `mil_start_war`, `mil_spawn_army`, `mil_day`, `mil_hostile_units_at`, `mil_units_at`, `mil_set_ctl`, `mil_take`, `mil_move_all`, `mil_local_odds`, `mil_battle_at`, `mil_join_battles`, `mil_def_mult`, `mil_battles`, `mil_battle_end`, `mil_retreat`, `mil_cleanup`, `mil_recover`, `mil_supply_update`, `mil_plan`, `mil_amp_cap`, `mil_land_check`, `mil_land_order`, `mil_sea_day`, `mil_land`, `mil_evacuate`, `mil_nav_station_set`, `mil_navy_day`, `mil_naval_battle`, `mil_occ`, `mil_cap_held`, `mil_score_update`, `mil_month`, `mil_war_month`, `mil_fix_positions`, `mil_mob_g`, `mil_g`, `mil_infl`, `mil_unemp`, `mil_dip_term`, `mil_occupied_by_us`, `mil_peace_quote`, `mil_peace_propose`, `mil_peace`, `mil_annex`, `mil_cede`, `mil_ai_peace`, `mil_event`, `mil_resolve`, `mil_ai_declare`, `mil_status_text`, `martial_on`, `martial_check`, `martial_set`, `martial_step`, `martial_blocks`

Константы (8): `MIL_BASE`, `MIL_NATO`, `MIL_COMBAT`, `MIL_DIV`, `MIL_TRUCE`, `MIL_PEACE_KINDS`, `MIL_ONGOING`, `MIL_PATRON`

Переменные (14): `mil`, `mil_rng`, `mil_coast`, `mil_coast_ok`, `mil_supply`, `mil_plan_t`, `mil_os`, `mil_cs`, `mil_un`, `mil_seen`, `mil_par`, `mil_stamp`, `mil_iver`, `mil_dirty`

### `scripts/logic/army.gd`  (1164 строк)
v48_1: вооружённые силы.

Функции (82): `con_mil`, `dx_has_treaty`, `dx_on`, `fa_bots`, `fa_eu_sanc`, `fa_on`, `fa_pers`, `ar_init`, `ar_on`, `ar_tp`, `ar_info`, `ar_data`, `ar_auto_type`, `ar_unit_name`, `ar_bs`, `ar_cap_mult`, `ar_mis_k`, `ar_rd`, `ar_q_mult`, `ar_mob_speed`, `ar_rsv`, `ar_ammo`, `ar_ammo_mult`, `ar_eq`, `ar_pow_mult`, `ar_mor`, `ar_mor_mult`, `ar_drone_mult`, `ar_att`, `ar_def`, `ar_combined`, `ar_air`, `ar_ad`, `ar_side_air`, `ar_air_mult`, `ar_strike_g`, `ar_wm`, `ar_deterred`, `ar_world_month`, `ar_log`, `ar_cd`, `ar_month`, `ar_ind`, `ar_apply_mods`, `ar_war_start`, `ar_war_month`, `ar_ammo_use`, `ar_war_g`, `ar_war_infl`, `ar_org_mult`, `ar_shift_bs`, `ar_svc_check`, `ar_set_svc`, `ar_td_check`, `ar_td_form`, `ar_ammo_price`, `ar_buy_check`, `ar_buy_ammo`, `ar_wecon_check`, `ar_wecon_toggle`, `ar_prog_info`, `ar_prog_cost`, `ar_prog_running`, `ar_prog_check`, `ar_prog_year_need`, `ar_prog_start`, `ar_inf_units`, `ar_prog_month`, `ar_ex_check`, `ar_defense_partners`, `ar_exercise`, `ar_mis_info`, `ar_mis_check`, `ar_mis_toggle`, `ar_mis_month`, `ar_exp_check`, `ar_set_exp`, `ar_exp_rev`, `ar_exp_month`, `ar_nato_pct`, `ar_comp`, `ar_rival_rows`

Константы (10): `AR_TYPES`, `AR_INFO`, `AR_DATA`, `AR_SVC`, `AR_BS0`, `AR_BS_KEYS`, `AR_BS_NAMES`, `AR_BS_TIPS`, `AR_PROG`, `AR_MIS`

Переменные (1): `ar`

### `scripts/logic/warpol.gd`  (925 строк)
v38: политика войны.

Функции (49): `fa_ws_annex_has`, `war_demo`, `war_hawk`, `war_rel`, `war_both_eu`, `war_vote`, `war_vote_text`, `war_anger_add`, `war_anger`, `war_sat_term`, `war_prel_term`, `war_on_declare`, `war_anger_month`, `talk_sel`, `talk_border_ates`, `talk_avail`, `talk_cost`, `talk_package`, `talk_budget`, `talk_quote`, `talk_pkg_text`, `talk_terms`, `talk_propose`, `talk_ceasefire_check`, `talk_ceasefire`, `talk_ceasefire_break`, `talk_mediator_name`, `talk_mediator`, `talk_apply`, `war_intl`, `war_aggressor`, `war_victim`, `war_cond0`, `war_eu0`, `war_intl_init`, `war_sanc_list`, `war_sanctions_update`, `war_preview_text`, `war_intl_month`, `war_join_check`, `war_join`, `war_intl_g`, `war_intl_infl`, `war_nonrec_any`, `war_prem`, `war_dip_extra`, `war_timers_month`, `war_trade_g`, `war_intl_text`

Константы (5): `WAR_HAWK`, `TALK_IDS`, `TALK_GIVE`, `TALK_INFO`, `TALK_REPAR`

Переменные (1): `peace_name`

### `scripts/logic/opposition.gd`  (774 строк)
Выбор партии, оппозиция и соглашения между партиями.

Функции (38): `idl_react`, `prm_init`, `party_name_playable`, `party_lean`, `party_sim`, `prel_base`, `prel_init`, `pact_left`, `pact_has`, `pact_mult`, `cd_left`, `player_swap_ok`, `swap_idx`, `apply_player_party`, `ai_coalition`, `ai_form_gov`, `opp_set_gov`, `opp_gov_text`, `opp_gov_seats`, `opp_init`, `opp_ap_force`, `opp_enter`, `junior_quit`, `opp_to_gov`, `gov_pop`, `opp_step`, `opp_act`, `pact_need`, `pact_can`, `pact_do`, `pacts_tick`, `pacts_after_election`, `opp_after_election`, `opp_show_offer`, `_gov_names`, `opp_resolve_offer`, `opp_status_text`, `opp_campaign`

Константы (6): `NO_PLAY_SLOTS`, `NO_PLAY_NAMES`, `NO_GOV_SLOTS`, `OPP_ACTS`, `PACT_KINDS`, `PM_LEAD_START`

### `scripts/logic/aiparty.gd`  (1752 строк)
Партийный ИИ: идеологии, политический капитал партий, правление без вас, законопроекты и поправки.

Функции (96): `autobalance_step`, `autopilot_step`, `corp_state_share`, `gov_style_step`, `nt_toast`, `tip_make`, `vote_plan_live`, `vote_plan_open`, `vt_plan_busy`, `ideo_keys`, `ideo_valid`, `lean_share`, `ideo_d`, `ideo_stat`, `party_arch`, `ideo_stance`, `ideo_target`, `gov_stance`, `gov_target`, `ai_def_lim`, `ai_policy_step`, `ideo_label`, `idl_planks`, `plank_dev`, `idl_mult`, `idl_step`, `idl_react`, `ideology_text`, `junior_info`, `junior_power`, `cap_vote_share`, `cap_sources`, `cap_mults`, `cap_tip`, `rel`, `rel_add`, `prm_base`, `prm_init`, `ai_init`, `ai_note`, `cap_swap`, `cap_unswap`, `autopilot_run`, `ai_parties_step`, `ai_party_act`, `ai_bloc_plan`, `ai_gov_rule`, `ai_recruit`, `ai_reshuffle`, `ai_pick_law`, `bill_of`, `bill_index`, `bill_forced`, `bill_preview`, `propose_variant`, `bill_request_new`, `bill_request`, `bill_pow_block`, `bill_amend`, `bill_rider_list`, `bill_rider_check`, `bill_rider_add`, `_lean_sum`, `bill_riders_apply`, `conc_all_groups_cost`, `bills_step`, `bill_warn_short`, `bills_attention`, `bills_due_step`, `bill_run_vote`, `bill_plan_wanted`, `bill_deal_cost`, `bill_press_ok`, `bill_press_cost`, `bill_swing_parties`, `bill_plan_preview`, `bill_plan_apply`, `pa_trade_value`, `pa_trade`, `pa_amend`, `bill_vote`, `ai_bill_vote`, `pa_power`, `pa_veto_cost`, `pa_month`, `pa_quarter`, `pa_options`, `pa_pick_bill`, `pa_do`, `pa_line`, `pa_set_vote`, `pa_bill_vote`, `pa_vote_after`, `pa_veto_bill`, `pa_veto_prop`, `pa_prop_text`

Константы (7): `ARCH`, `CAP_K`, `CAP_W`, `RIDER_CHARS`, `RIDER_MAX`, `MIN_BUD`, `PA_VOTE_NAMES`

Переменные (2): `cap_vs_turn`, `cap_vs`

### `scripts/logic/council.gd`  (498 строк)
Совет коалиции (v35): партнёры голосуют по событиям, кабинету, бюджету и приёму новых партий;

Функции (27): `coal_members`, `coal_share`, `council_on`, `fx_utility`, `council_backers`, `council_fav`, `council_event_ok`, `council_event`, `council_split`, `council_event_note`, `council_min_yes`, `council_min_vote`, `council_budget`, `invite_offer_w`, `council_invite_vote`, `council_expel_vote`, `crisis_tol_pick`, `crisis_grand_pick`, `show_crisis_exit`, `resolve_crisis`, `party_abbr`, `upper_on`, `upper_gov`, `upper_renew`, `upper_summary`, `observer_start`, `observer_step`

Константы (2): `COUNCIL_TOL`, `UPPER_RENEW`

### `scripts/logic/radical.gd`  (521 строк)
Радикальные законы: форма правления, строй, выход из ЕС и т.д.

Функции (30): `au_dyn`, `au_fat_months`, `au_risk_add`, `au_step`, `es_dyn`, `es_step`, `hist_dyn`, `io_dyn`, `io_step`, `arch_ps`, `RV`, `rid_of`, `regime_id`, `econ_id`, `decree_power`, `radical_bypass`, `radical_req`, `law_locked`, `auth_idx`, `radical_enact`, `open_mult`, `radical_dyn`, `radical_step`, `show_uprising`, `radical_roll`, `radical_text`, `active_rids`, `radical_events`, `radical_add_variants`, `radical_inject`

### `scripts/logic/revolt.gd`  (1624 строк)
Протесты, недовольство, сепаратизм, революция, гражданская война, война за отделение, независимость и государственные перевороты (v43_1).

Функции (68): `au_sep_term`, `rv_lvl`, `rv_on`, `revolt_init`, `rv_add_hate`, `rv_uid`, `rv_reg`, `rv_idx`, `rv_log`, `rv_cd`, `rv_cd_set`, `rv_cd_tick`, `rv_clamp`, `rv_conf_count`, `revolt_g`, `revolt_unemp`, `revolt_month`, `rv_nat_step`, `rv_identity_gap`, `rv_sep_target`, `rv_region_step`, `rv_is_capital`, `rv_stage_news`, `rv_reg_act_def`, `rv_reg_act_check`, `rv_region_act`, `rv_agreed_referendum`, `rv_yes_share`, `rv_referendum`, `rv_new_state_code`, `rv_can_secede`, `rv_secede`, `rv_conf_of`, `rv_aid0`, `rv_conf_start`, `rv_gov_power`, `rv_conf_month`, `rv_conf_step`, `rv_conf_end`, `rv_take_power`, `rv_conf_act_check`, `rv_conf_act`, `rv_event`, `rv_events`, `rv_event_wave`, `rv_event_rev`, `rv_event_coup`, `rv_event_referendum_demand`, `rv_event_udi`, `rv_event_ref_yes`, `revolt_resolve`, `rv_regime_options`, `rv_install_regime`, `democracy_index_before`, `rv_selfcoup_prob`, `rv_selfcoup_check`, `rv_selfcoup`, `rv_event_regime_choice`, `rv_oppcoup_prob`, `rv_oppcoup_check`, `rv_oppcoup`, `rv_uprising_check`, `rv_uprising`, `rv_coup_measure_check`, `rv_coup_measure`, `rv_ai_choice`, `rv_ai_step`, `revolt_nationwide_uprising`

Константы (7): `RV_STAGE_NAMES`, `RV_STAGE_COL`, `RV_STAGE_G`, `RV_STAGE_U`, `RV_REG_ACTS`, `RV_CONF_ACTS`, `RV_COUP_MEASURES`

Переменные (1): `rv`

### `scripts/logic/regime.gd`  (939 строк)
v51_1: недемократические режимы изнутри. Власть держится не на парламенте, а на кланах элиты (их лояльности

Функции (52): `au2_act`, `au2_after_election`, `au2_check`, `au2_clan_t`, `au2_def`, `au2_dyn`, `au2_has`, `au2_risk`, `au2_stage`, `au2_step`, `au2_und_t`, `au_fe`, `au_pe`, `regime_class`, `au_on`, `au_auth`, `au_class_name`, `au_init`, `au_set_class`, `au_clan_def`, `au_und_def`, `au_type_loy`, `au_lib`, `au_und_total`, `au_und_max`, `au_clan_target`, `au_und_target`, `au_step`, `au_risk_add`, `au_fat_months`, `au_dyn`, `au_official_approval`, `au_pp`, `au_control`, `au_note_start`, `au_fraud_shares`, `au_fraud_base`, `au_after_election`, `au_act_def`, `au_check`, `au_cd`, `au_clan_add`, `au_clan_of_kind`, `au_und_add`, `au_act`, `au_log`, `au_set_gov`, `au_events`, `au_event_clan`, `au_event_protest`, `au_fx`, `au_ai`

Константы (6): `AU2`, `AU_CLASS_NAMES`, `AU_CLASS_MOTTO`, `AU_CLANS`, `AU_UNDER`, `AU_ACTS`

Переменные (1): `au`

### `scripts/logic/econsys.gd`  (717 строк)
v51_1: система управления экономикой зависит от экономической модели (рынок, смешанная, социальная,

Функции (22): `econ_class`, `es_init`, `es_class_changed`, `es_bonus`, `es_step`, `es_dyn`, `es_log`, `es_act_def`, `es_check`, `es_act`, `corp_init`, `corp_step`, `corp_growth`, `corp_name`, `corp_owner_text`, `co_act_def`, `co_check`, `co_act`, `co_foreign_check`, `co_foreign`, `corp_log`, `corp_state_share`

Константы (10): `ES_NAMES`, `ES_DESK`, `ES_MOTTO`, `ES_PLAN_SECT`, `ES_PLAN_LVL`, `ES_SECT_NAMES`, `ES_ACTS`, `ES_ONEOFF`, `CO_ONEOFF`, `CO_ACTS`

Переменные (2): `es`, `corp`

### `scripts/logic/construct.gd`  (953 строк)
v55_1: сооружения второго поколения. Ещё 42 вида сооружений (культура, религия, образование, здравоохранение, энергетика,

Функции (54): `con_dyn`, `con_init`, `con_projects`, `con_mega_def`, `con_mega`, `con_mega_region`, `con_lvl`, `con_upgrade_cost`, `con_upgrade_check`, `con_upgrade_start`, `con_upgrade_done`, `con_repair_cost`, `con_repair`, `con_struct_extra`, `con_rb`, `con_rb_nat`, `con_ind`, `con_mil`, `con_unr_term`, `con_start_check`, `con_mega_done`, `con_month`, `con_accidents`, `con_fx`, `con_corp_month`, `con_log`, `con_ai_month`, `con_log_world`, `con_ai_g`, `con_ai_rows`, `bld_budget_init`, `bld_budget_ok`, `bld_set`, `bld_money_month`, `bld_cap_month`, `bq_find`, `bq_in_region`, `bq_has`, `bq_rate`, `bq_add`, `bq_alloc`, `bq_eta`, `bq_move`, `bq_cancel`, `bq_migrate`, `bq_month`, `bq_priv_done`, `bld_payback`, `bld_profitable`, `bq_priv_spawn`, `bld_toggle_break`, `bld_plan_make`, `bld_plan_step`, `bld_plan_toggle`

Константы (9): `CS_LVL_MAX`, `CS_UPG_COST`, `CS_UPG_TIME`, `CS_PROJECTS`, `CS_CORP_MAP`, `BQ_BRK_SHARE`, `BQ_PRIV_MAX`, `BQ_CAT_MIN`, `BQ_PUBLIC`

Переменные (2): `cs`, `cs_rng`

### `scripts/logic/history.gd`  (69 строк)
v52_1: исторические предпосылки. Черты национального характера (HIST_TRAITS, COUNTRY_TRAITS) дают постоянные

Функции (7): `hist_traits`, `hist_dyn`, `hist_rel`, `hist_why`, `hist_name`, `hist_mult`, `hist_text_rel`

### `scripts/logic/intorg.gd`  (654 строк)
v52_1: международные организации (данные — data_orgs.gd). Членство, вступление и выход, влияние внутри

Функции (28): `rl_acts`, `rl_cor_add`, `rl_do`, `rl_on`, `rl_pc`, `io_init`, `io_ready`, `io_member`, `io_members`, `io_avg_rel`, `io_infl`, `io_log`, `io_req`, `io_reqs`, `io_step`, `io_cand_step`, `io_dyn`, `io_item`, `io_stance`, `io_ru_title`, `io_ai_vote`, `io_tally`, `io_vote`, `io_apply_yes`, `io_act_list`, `io_check`, `io_act`, `io_special`

Константы (5): `IO_EAST`, `IO_POSTSOV`, `IO_BLACKSEA`, `IO_GEO`, `IO_GEN_ACTS`

Переменные (3): `io`, `rl`, `io_ru_titles`

### `scripts/logic/realism.gd`  (847 строк)
Реализм (v44_1): блоки и союзы (ЕС, евро, НАТО, Шенген), демография и пенсии, энергия и климат,

Функции (33): `diplo_resolve`, `sv_auto`, `rl_on`, `rl_init`, `rl_log`, `rl_cd_get`, `rl_cd_set`, `rl_rec_hist`, `rl_g`, `rl_infl`, `realism_month`, `rl_pc`, `rl_deficit_ema`, `rl_blocs_step`, `rl_avg_rel`, `rl_bloc_name`, `rl_accept`, `rl_demo_step`, `rl_energy_step`, `rl_cor_add`, `rl_law_step`, `rl_media_step`, `rl_region_step`, `rl_cohab`, `rl_parl_step`, `rl_event`, `rl_events`, `realism_resolve`, `rl_pending_step`, `rl_acts`, `rl_do`, `rl_summary_text`, `rl_yn`

Константы (13): `RL_EU`, `RL_EURO`, `RL_SCHENGEN`, `RL_CPI`, `RL_JUD`, `RL_AGE`, `RL_TFR`, `RL_PRESS`, `RL_ENDEP`, `RL_GREEN`, `RL_CONSTR`, `RL_HIST_MAX`, `RL_LEVELS`

### `scripts/logic/diplo2.gd`  (957 строк)
Дипломатия, разведка, вмешательство в конфликты, признание новых государств, армия как политический игрок,

Функции (39): `fpai_resolve`, `dx_on`, `dx_init`, `dx_log`, `dx_cd_get`, `dx_countries`, `dx_name`, `diplo_month`, `dx_treaty_step`, `dx_has_treaty`, `dx_spy_step`, `dx_target_ok`, `dx_conf_month`, `dx_conf_by_id`, `dx_conf_acts`, `dx_conf_do`, `dx_pick_neighbor`, `dx_rec_step`, `dx_rec_text`, `dx_rec_acts`, `dx_rec_do`, `dx_army_step`, `dx_army_acts`, `dx_army_do`, `dx_science_step`, `dx_discovery_event`, `diplo_resolve`, `dx_treaty_acts`, `dx_treaty_do`, `dx_clause`, `dx_draft_eval`, `dx_draft_propose`, `dx_named_break`, `dx_spy_acts`, `dx_spy_do`, `dx_eth_acts`, `dx_eth_do`, `dx_summary_text`, `ev_ext_val`

Константы (4): `DX_TREATIES`, `DX_SPY`, `DX_CI_COST`, `DX_CLAUSES`

Переменные (1): `dx`

### `scripts/logic/fpai.gd`  (825 строк)
Внешнеполитический ИИ стран (v47_1). Состояние — словарь fa.

Функции (40): `au_evade`, `fa_on`, `fa_init`, `fa_pers`, `fa_bots`, `fa_is_eu`, `fa_me_eu`, `fa_log`, `fa_hit`, `fa_notify`, `fa_standing`, `fa_sanc_score`, `fa_rel_term`, `fa_month`, `fa_sanctions_step`, `fa_initiatives`, `fa_eu_sanc`, `fa_sanctioning`, `fa_cd`, `fpai_resolve`, `fa_ws`, `fa_ws_init`, `fa_ws_lvl`, `fa_west`, `fa_ws_forced`, `fa_ws_war_sanct`, `fa_ws_g`, `fa_ws_set`, `fa_ws_month`, `fa_war_ended`, `fa_ws_annex_has`, `fa_ws_need_dem`, `fa_ws_conds`, `fa_ws_step_ok`, `fa_world`, `fa_world_name`, `fa_ws_acts`, `fa_ws_do`, `fa_ws_text`, `fa_explain`

Константы (9): `FA_PERS`, `FA_MEM_DECAY`, `FA_SANC_AT`, `FA_SANC_LIFT`, `FA_WS_NAMES`, `FA_WS_PEN`, `FA_WS_WEST`, `FA_WS0`, `FA_WS_WHY`

Переменные (1): `fa`

### `scripts/logic/regime2.gd`  (961 строк)
0.56 (доп. 3 и 4): недемократические режимы, часть вторая.

Функции (41): `au2_def`, `au2_has`, `au_x`, `au_fe`, `au_pe`, `au_dfe`, `au_dpe`, `au_med`, `au2_med_base`, `au_med_avg`, `au2_n_sanc`, `au_evade`, `au2_bm_target`, `au2_und_t`, `au2_clan_t`, `au2_risk`, `au_sep_term`, `au_unr_term`, `au_ag_term`, `au_opp_mult`, `au2_dyn`, `au2_step`, `au2_age`, `au2_ruler_gone`, `au2_check`, `au2_act`, `au2_stage`, `au2_after_election`, `au2_report`, `au2_dec_def`, `au2_dec_done`, `au2_dec_orgs`, `au2_dec_econ_variants`, `au2_dec_avail`, `au2_dec_cost_raw`, `au2_dec_cost`, `au2_dec_check`, `au2_dec_sign`, `au2_dec_apply`, `au2_set_law_idx`, `au2_dec_preview`

Константы (4): `AU2_ACTS`, `AU_PATRONS`, `AU_DECS`, `AU_NEW_NAMES`

### `scripts/logic/agents.gd`  (368 строк)
Население: подключение агентов к голосованию, шагу и протестам.

Функции (19): `show_desk`, `update_pop_windows`, `ag_k`, `ag_make_pos`, `ag_support_arr`, `ag_build`, `ag_calibrate`, `ag_zs`, `ag_zg`, `ag_step`, `ag_unrest_term`, `ag_region_table`, `group_party_shares`, `ag_exit_report`, `ag_party_shift_check`, `ag_party_shift`, `ag_pick`, `ag_random_agent`, `ag_reset_ui`

Переменные (3): `gp_cache`, `ag_shift_cd`, `ag_shift`

### `scripts/logic/autopilot.gd`  (296 строк)
Помощник и автопилот.

Функции (16): `ap_can_adj`, `ap_note_change`, `ap_flush_log`, `autobalance_step`, `balance_now`, `apply_preset`, `fx_score`, `auto_event_pick`, `auto_event_ok`, `auto_resolve_event`, `autobuild_step`, `autopilot_step`, `party_style`, `party_style_text`, `gov_style_step`, `advisor_lines`

Константы (1): `GOV_STYLES`

Переменные (1): `gs_drift`

### `scripts/logic/log.gd`  (272 строк)
Структурированный журнал.

Функции (26): `log_is_big`, `log_ui_add`, `log_ui_bump`, `log_ui_rebuild`, `notify_log`, `log_guess_cat`, `log_match`, `log_add`, `log_chip`, `log_render`, `log_cell`, `log_render_month`, `log_render_year`, `log_rebuild`, `log_clear`, `on_log_filter`, `build_log_filters`, `log_line`, `log_sys`, `log_header`, `log_tag`, `h12_push`, `h12_ago`, `h12_months`, `h12_label`, `h12_snap`

### `scripts/logic/saves.gd`  (167 строк)
Сохранения, автосохранения и откат на год назад (v44_1).

Функции (10): `sv_clean`, `sv_collect`, `sv_pack`, `sv_apply`, `sv_path`, `sv_save`, `sv_info`, `sv_load`, `sv_auto`, `sv_rollback`

Константы (3): `SV_DIR`, `SV_SKIP`, `SV_KEEP`

Переменные (2): `sv_clean_cache`, `sv_hist`

### `scripts/ui/ui_core.gd`  (2730 строк)
Интерфейс: окна, тема, верхняя панель, экран «Бюджет», обновление.

Функции (183): `build_army_windows`, `build_bud_oneoff`, `build_bud_transfer`, `build_build_window`, `build_cn_overlay`, `build_crisis_windows`, `build_dip_windows`, `build_econ_windows`, `build_econsys_windows`, `build_election_window`, `build_event_window`, `build_fed_windows`, `build_fleet_windows`, `build_goods_windows`, `build_gov_windows`, `build_io_windows`, `build_law_windows`, `build_map_windows`, `build_meas_overlay`, `build_more_menu`, `build_notify_ui`, `build_opp_windows`, `build_politics_windows`, `build_pop_windows`, `build_realm_windows`, `build_regime_windows`, `build_settings_button`, `build_soc_windows`, `build_society_windows`, `build_tech_windows`, `build_today_windows`, `build_war_windows`, `click_name`, `cn_is_open`, `crisis_is_open`, `es_ui_sync`, `io_bar_h`, `make_crisis_button`, `make_meas_button`, `make_tech_button`, `map_apply_mode`, `meas_is_open`, `music_dirs`, `nav_init`, `nav_note`, `on_bud_accept`, `on_win_help`, `on_win_star`, `overlays_lock`, `reg_ui_sync`, `set_crisis_open`, `set_meas_open`, `set_tech_open`, `show_country_menu`, `subbar_hide_absent`, `tech_is_open`, `update_army_windows`, `update_bud_head`, `update_build_window`, `update_chips_extra`, `update_cn_window`, `update_corp_windows`, `update_crisis_windows`, `update_dip_windows`, `update_econ_windows`, `update_es_windows`, `update_fed_windows`, `update_fleet_windows`, `update_goods_detail`, `update_goods_windows`, `update_gov_windows`, `update_io_windows`, `update_law_windows`, `update_meas_window`, `update_opp_windows`, `update_parliament`, `update_realm_windows`, `update_regime_windows`, `update_regions_ui`, `update_soc_windows`, `update_society_windows`, `update_tech_windows`, `update_today`, `update_ui_extras`, `update_war_windows`, `win_menu_extra`, `win_menu_pick`, `win_mode_ok`, `new_window`, `win_vis`, `win_fade_in`, `on_win_close`, `win_menu_fill`, `on_win_menu`, `layout_windows`, `fix_wraps`, `fix_wraps_later`, `on_wrap_timer`, `reset_layout`, `desk_tab`, `show_desk`, `build_ui`, `add_title`, `add_note`, `make_fold`, `make_tail`, `set_tail_text`, `on_fold_toggled`, `on_detail_toggled`, `add_wrap_label`, `make_button`, `tone_button`, `make_rt`, `fmt_sections`, `fmt_pass`, `add_slider`, `set_bar`, `build_budget_windows`, `build_log_and_event`, `update_slider_label`, `update_forecast`, `update_stats`, `update_polls`, `add_bar`, `color_button`, `refresh`, `update_win_locks`, `on_slider`, `nudge_step`, `slider_nudge`, `slider_shrink`, `slider_value_for`, `configure_slider_range`, `configure_slider`, `toggle_slider_mode`, `make_theme`, `tip_setup`, `tip_make`, `tip_num_text`, `tip_color_nums`, `tip_is_row`, `tip_bbcode`, `tip_on_added`, `tip_show_later`, `log_is_big`, `log_groups`, `log_ui_rebuild`, `log_ui_new_group`, `log_ui_put`, `log_ui_head`, `log_ui_toggle`, `log_ui_add`, `log_ui_card`, `log_ui_bump`, `log_ui_scroll_end`, `sdepth`, `accent_for_desk`, `polish_tree`, `make_chip`, `set_chip`, `set_chip_num`, `update_chips`, `draw_budget_viz`, `on_log_detail`, `overlay_tabs_sync`, `show_tab`, `update_subbar`, `btn_icon`, `build_subbar`, `build_auto_window`, `on_ap_toggle`, `on_ap_target`, `on_ap_style`, `update_auto_window`, `update_group_parties`, `on_floor_toggle`, `audio_ok`, `audio_load`, `audio_init`, `audio_apply_volume`, `music_next`, `sfx`, `toggle_music`

Константы (15): `WIN_DEFAULT_CLOSED`, `TONE_UP`, `TONE_DN`, `BUD_GROUPS`, `WIN_GOV_ONLY`, `WIN_PARL_ONLY`, `TIP_SIZES`, `TIP_WIDTHS`, `TIP_DELAYS`, `TIP_WARN_HEADS`, `TIP_BAD_UP`, `LOG_KEEP_OPEN`, `LOG_BIG_TAGS`, `LOG_QUIET_TAGS`, `LOG_BIG_WORDS`

Переменные (26): `fmt_rts`, `viz_rev0_t`, `bud_head`, `bud_head_rt`, `bud_prev_rt`, `bud_tbl_rt`, `bud_tbl_btn`, `bud_accept_btn`, `bud_cancel_btn`, `floor_btns`, `viz_exp0_t`, `tip_re_num`, `tip_re_row`, `gp_rt`, `selfcoup_btn`, `ui_bg`, `ui_top`, `io_bar`, `ui_top_h`, `selfcoup_note`, `music_player`, `sfx_players`, `sfx_cache`, `music_list`, `music_idx`, `sfx_last`

### `scripts/ui/ui_map.gd`  (2455 строк)
Интерфейс: карта, таблица регионов, региональная экономика.

Функции (90): `bld_cancel`, `bld_open`, `build_click`, `draw_struct_icons`, `draw_war_overlay`, `draw_war_tokens`, `fed_btn`, `fed_opt`, `fed_pct`, `update_fregion`, `war_hover`, `war_map_click`, `on_layer_selected`, `fill_table_rows`, `fill_transfer_rows`, `rebuild_region_widgets`, `map_rebuild`, `map_prepare`, `map_is_disputed`, `map_prepare_labels`, `map_tri_mesh`, `map_border_segs`, `map_view`, `map_country_rect`, `map_free_rect`, `map_fit_rect`, `map_zoom_cmd`, `map_zoom_at`, `map_clamp`, `map_cam_snap`, `map_cam_step`, `map_pin_layout`, `map_pin_pos`, `unit_is_tiny`, `ate_at`, `unit_at`, `ctx_at`, `unit_tip`, `map_click`, `on_region_picked`, `map_apply_mode`, `on_map_input`, `build_map_windows`, `on_transfer_slider`, `bud_tr_equalize`, `on_table_row`, `set_sort`, `is_world_layer`, `layer_info`, `layer_leader`, `layer_color`, `cl_info`, `cl_color`, `unit_color`, `map_draw_sea`, `map_sea_points`, `map_draw_seas`, `draw_map`, `region_tip`, `region_sort_value`, `update_regions_ui`, `update_region_table`, `update_transfer_ui`, `build_bud_transfer`, `on_bud_tr`, `bud_tr_hi`, `bud_tr_nudge`, `bud_tr_shrink`, `build_bud_tr_window`, `bud_tr_open`, `update_region_info`, `on_tool_selected`, `build_regecon_window`, `update_regecon`, `regecon_inject`, `ate_tip`, `fmt_people`, `ate_click`, `build_adm_window`, `adm_open`, `adm_opt_fill`, `adm_sel_regions_adjacent`, `update_adm_ui`, `on_adm_move`, `on_adm_create`, `on_adm_delete`, `on_adm_buy`, `ui_anim_step`, `map_cloud_tex`, `draw_map_fx`

Константы (4): `MapLabels`, `MAP_HCELL`, `MAP_OCCUPIED`, `MAP_OCC_SINCE`

Переменные (27): `map_lab`, `map_lab_pts`, `map_fx`, `map_fx_t`, `map_fx_acc`, `map_cloud`, `map_hatch`, `map_front`, `map_own_rect`, `map_own_mix`, `reg_grid`, `transfer_parent`, `map_ate_tris`, `map_all_mesh`, `map_unit_mesh`, `map_ln_ate`, `map_ln_reg`, `map_ln_cty`, `map_sea_cache`, `map_ln_coast`, `map_hash`, `map_seg_cache`, `map_hover_ate`, `map_fit_cc`, `adm_ui`, `map_pin_cache`, `map_pin_key`

### `scripts/ui/ui_politics.gd`  (472 строк)
Интерфейс: парламент, полукруг, таблица партий.

Функции (14): `on_cr_power`, `select_neg_party`, `build_hemicycle`, `build_politics_windows`, `on_party_button`, `head_state_text`, `update_parliament`, `draw_hemi`, `on_hemi_input`, `update_party_table`, `update_party_detail`, `ministry_effect_text`, `draw_upper`, `upper_tip`

### `scripts/ui/ui_laws.gd`  (683 строк)
Интерфейс: окно законов.

Функции (22): `update_bill_window`, `build_law_windows`, `on_law_search`, `on_law_filter`, `law_demand_map`, `on_law_cat`, `on_topic_pressed`, `first_other_variant`, `on_card_input`, `on_adopt`, `on_negotiate`, `update_law_windows`, `update_law_effects`, `refit_law_cards`, `update_law_votes`, `build_law_slider`, `on_law_pow`, `on_law_slider`, `build_law_list`, `law_icon`, `update_law_headers`, `update_law_detail`

Константы (1): `LAW_ICON_KEYS`

### `scripts/ui/ui_gov.gd`  (908 строк)
Интерфейс: правительство и коалиционные переговоры.

Функции (38): `build_gov_windows`, `select_ministry`, `select_neg_party`, `on_neg_selected`, `on_neg_promise`, `on_neg_mins`, `on_neg_main`, `on_neg_conc`, `on_neg_dem`, `on_assign_ministry`, `on_replace_minister`, `update_gov_windows`, `update_coal_summary`, `update_cabinet`, `update_min_detail`, `refit_gov`, `update_neg`, `refit_neg`, `update_cabfx`, `update_pa_box`, `update_commit`, `cn_is_open`, `cn_open`, `cn_close`, `cn_auto_open`, `cn_mk_rt`, `cn_card`, `cn_col`, `build_cn_overlay`, `cn_clear`, `cn_pc`, `cn_pname`, `cn_verdict_text`, `update_cn_window`, `cn_build_left`, `cn_opt`, `cn_build_mid`, `cn_build_right`

Переменные (8): `pa_box`, `pa_sig`, `cn_ov`, `cn_left`, `cn_mid`, `cn_right`, `cn_head_rt`, `cn_sig`

### `scripts/ui/ui_econ.gd`  (518 строк)
Интерфейс: экран «Экономика».

Функции (16): `ec_slider`, `build_econ_windows`, `on_cb_auto`, `on_rate_slider`, `on_tariff_slider`, `on_roy_slider`, `on_focus_selected`, `on_chart_selected`, `update_chart`, `update_econ_windows`, `build_goods_windows`, `on_goods_row`, `goods_market_color`, `update_goods_windows`, `_hot_txt`, `struct_lines`

### `scripts/ui/ui_world.gd`  (254 строк)
Интерфейс: дипломатия.

Функции (7): `treaty_sheet_open`, `select_dip`, `on_dip_far_ex`, `build_dip_windows`, `update_dip_fund`, `dip_nohead`, `update_dip_windows`

Переменные (6): `dip_fund_opt`, `dip_fund_btn`, `dip_fund_rt`, `dip_fund_cc`, `dip_flag`, `dip_flag_lbl`

### `scripts/ui/ui_pop.gd`  (553 строк)
Интерфейс: вкладка «Население».

Функции (11): `build_pop_windows`, `demo_cohorts`, `demo_rates`, `draw_pyramid`, `update_demo_window`, `ag_tip`, `ag_agent_text`, `update_pop_windows`, `nat_fx_text`, `update_nat_window`, `draw_nat_rel`

Константы (1): `AG_GROUP_COLS`

Переменные (4): `demo_rt`, `demo_ctl`, `nat_traits_box`, `nat_rel_ctl`

### `scripts/ui/ui_events.gd`  (340 строк)
Интерфейс: окна событий и выборов.

Функции (6): `show_head_election`, `build_election_window`, `show_election`, `election_continue`, `build_event_window`, `refit_event`

### `scripts/ui/ui_fed.gd`  (608 строк)
Интерфейс: «Регионы и автономия» (desk 8) и «Территории» (desk 9).

Функции (28): `fed_btn`, `fed_opt`, `build_fregion_window`, `on_fregion_back`, `on_fregion_buy`, `fmap_sel_unit_valid`, `update_fregion`, `build_fed_windows`, `on_fed_reform`, `on_fed_eq`, `on_fed_meta`, `on_fed_comp`, `on_fed_bulk`, `on_fed_status`, `on_fed_admit`, `on_fed_demand`, `on_tw_changed`, `on_tw_buy`, `on_tw_union`, `on_tw_court`, `on_tw_sell`, `on_tw_admit`, `update_fed_windows`, `fed_pct`, `update_fed_desk`, `fed_why_text`, `tw_fill_options`, `update_terr_desk`

Константы (1): `TW_MULT`

Переменные (37): `fw_state_rt`, `fw_upper_rt`, `fw_btn_up`, `fw_btn_down`, `fw_eq_btns`, `fw_list_rt`, `fw_reg_rt`, `fw_comp_rows`, `fw_st_dn`, `fw_st_up`, `fw_admit_btn`, `fw_bulk_rows`, `fw_dem_box`, `tw_buy_pick`, `tw_buy_mult`, `tw_buy_how`, `tw_buy_rt`, `tw_buy_btn`, `tw_buy_units`, `tw_un_pick`, `tw_un_terms`, `tw_un_rt`, `tw_un_btn`, `tw_court_btn`, `tw_un_cc`, `tw_sell_lbl`, `tw_sell_pick`, `tw_sell_mult`, `tw_sell_rt`, `tw_sell_btn`, `tw_sell_cc`, `tw_sell_for`, `tw_terr_box`, `tw_stat_rt`, `fr_rt`, `fr_buy_btn`, `fr_back_btn`

### `scripts/ui/ui_soc.gd`  (352 строк)
Интерфейс: «Религия и миграция» (desk 11) и «Влияние и зависимость» (desk 10).

Функции (22): `rm_dirty_all`, `soc_btn`, `build_soc_windows`, `on_soc_sec`, `on_soc_fund`, `on_soc_dialog`, `on_soc_mig`, `on_soc_prog`, `on_soc_sel`, `on_ex_meta`, `on_ex_deal`, `on_ex_tar`, `on_ex_aid`, `on_ex_dbuy`, `on_ex_favor`, `soc_eff_line`, `update_soc_windows`, `update_soc_desk`, `regions_rel0_vec`, `regions_rel0_nat`, `_soc_btn_state`, `update_ex_desk`

Константы (1): `XW_SORTS`

Переменные (17): `sw_rel_rt`, `sw_pol_rt`, `sw_mig_rt`, `sw_reg_rt`, `sw_btn`, `xw_list_rt`, `xw_sort`, `xw_sort_desc`, `xw_info_rt`, `xw_fa_rt`, `xw_btn`, `sw_chart`, `sw_regchart`, `sw_spk_t`, `sw_spk_n`, `xw_chart`, `xw_spk`

### `scripts/ui/ui_society.gd`  (409 строк)
v55_1: рамка «Общество»: вкладки «Религия и миграция» (11), «Церковь и государство» (20), «Культура» (19);

Функции (8): `build_society_windows`, `on_cult_meta`, `update_society_windows`, `cu_status`, `cu_segs`, `update_cult_desk`, `update_church_desk`, `update_goods_detail`

Константы (1): `CultChart`

Переменные (15): `cw_nat_rt`, `cw_nat_chart`, `cw_pol_rt`, `cw_reg_chart`, `cw_reg_rt`, `cw_kin_rt`, `cw_spk`, `cw_btn`, `chw_main_rt`, `chw_law_rt`, `chw_reg_rt`, `chw_spk`, `chw_btn`, `gdw_all_rt`, `gdw_ind_rt`

### `scripts/ui/ui_tech.gd`  (620 строк)
Интерфейс: окно «Технологии» (v42_1) — отдельное окно поверх игры: схема технологий, сводка, сооружения.

Функции (24): `make_tech_button`, `tech_is_open`, `on_tech_toggle`, `set_tech_open`, `tech_scroll_to_frontier`, `build_tech_windows`, `on_tech_filter`, `on_tech_weight`, `on_tech_auto`, `on_tech_ai_all`, `on_tech_hover`, `on_tech_pick`, `on_tech_build`, `tech_bar`, `tech_info_text`, `tech_swap_note`, `tech_info_update`, `tech_idle_branches`, `tech_tab_mark`, `update_tech_windows`, `tech_queue_ui`, `tech_clear`, `tech_build_buildings`, `tech_buildings_text`

Переменные (20): `tech_ov`, `tech_btn`, `tech_view`, `tech_scroll`, `tw_left_box`, `tw_sum_rt`, `tw_info_rt`, `tw_spk`, `tw_bld_rt`, `tw_bld_box`, `tw_wlbl`, `tw_wbtn`, `tw_auto`, `tw_ai_all`, `tw_filter`, `tw_hover`, `tw_sig`, `tw_first`, `tw_q_box`, `tw_q_sig`

### `scripts/ui/ui_crisis.gd`  (452 строк)
Интерфейс: окно «Кризисы» (v43_1) — протесты, сепаратизм, войны за отделение, революция, гражданская война, перевороты.

Функции (21): `make_crisis_button`, `on_crisis_toggle`, `crisis_is_open`, `set_crisis_open`, `cr_section`, `build_crisis_windows`, `cr_col_for`, `cr_bar`, `on_cr_reg_meta`, `on_cr_conf_meta`, `cr_sel_region_idx`, `cr_sel_conf_idx`, `on_cr_reg_act`, `on_cr_conf_act`, `on_cr_coup_measure`, `on_cr_power`, `on_cr_confirmed`, `update_crisis_windows`, `date_after_turn`, `ov_lock_banner`, `overlays_lock`

Переменные (18): `cr_ov`, `cr_btn`, `cr_sum_rt`, `cr_reg_rt`, `cr_sel_rt`, `cr_conf_rt`, `cr_log_rt`, `cr_state_rt`, `cr_coup_rt`, `cr_spk`, `cr_reg_btn`, `cr_conf_btn`, `cr_coup_btn`, `cr_sel_reg`, `cr_sel_conf`, `cr_confirm`, `cr_pending`, `cr_right_box`

### `scripts/ui/ui_realm.gd`  (677 строк)
Интерфейс v44_1: «Государство и мир» без отдельного окна — секции встроены в существующие разделы:

Функции (40): `rm_reg`, `rm_win`, `rm_attach`, `build_realm_windows`, `rm_dirty_all`, `update_realm_windows`, `rm_act_btn`, `rm_acts_box`, `rm_text`, `rm_do_rl`, `rm_flags_row`, `rl_eu_status`, `rl_nato_status`, `rm_dip_target`, `rm_b_treaty`, `rm_b_world`, `rm_b_spy`, `rm_b_energy`, `rm_b_demo`, `rm_b_law`, `rm_b_parl`, `rm_b_eq`, `rm_b_army`, `rm_b_hist`, `rm_slot_row`, `rm_b_game`, `rm_b_conf`, `rm_b_science`, `build_tutorial`, `on_tut_start`, `on_tut_next`, `on_tut_back`, `on_tut_skip`, `on_tut_never`, `tut_target`, `tut_do`, `update_tutorial`, `tut_place`, `tut_tick`, `tut_draw`

Константы (1): `TUT_STEPS`

Переменные (13): `rm_boxes`, `rm_ver`, `tut_panel`, `tut_label`, `tut_idx`, `rm_partner`, `tut_fx`, `tut_btns`, `tut_offer_btns`, `tut_title`, `tut_done`, `tut_timer`, `tut_tr`

### `scripts/ui/ui_opp.gd`  (501 строк)
Интерфейс: оппозиция и переговоры между партиями (экран «Политика»).

Функции (14): `build_opp_windows`, `on_bill_req`, `on_bill_amend`, `rider_fill`, `on_rider_add`, `update_bill_window`, `bill_cards_build`, `bill_card_btn`, `bill_make_card`, `on_opp_act`, `on_pact_party`, `on_pact_do`, `powers_text`, `update_opp_windows`

Переменные (23): `opp_rt`, `opp_btns`, `pact_rt`, `pact_opt`, `pact_btns`, `pact_sel`, `bill_rt`, `bill_acc`, `bill_rej`, `bill_am`, `rider_kind`, `rider_arg`, `rider_btn`, `rider_args`, `bill_veto`, `bill_sort`, `bill_rest_open`, `bill_sig`, `bill_att_title`, `bill_att_box`, `bill_rest_btn`, `bill_rest_box`, `bill_sel_title`

### `scripts/ui/ui_fleet.gd`  (194 строк)
Экран «Флот» (desk 14): морская торговля, порты, военный флот, война на море.

Функции (7): `build_fleet_windows`, `on_fleet_merch`, `on_fleet_order`, `on_fleet_mission`, `on_fleet_port`, `on_fleet_station`, `update_fleet_windows`

Переменные (11): `fw_info_rt`, `fw_navy_rt`, `fw_inc_rt`, `fw_sea_rt`, `fw_pbox`, `fw_pkey`, `fw_btn`, `fw_btn_ports`, `fw_spk`, `fw_station`, `fw_station_ids`

### `scripts/ui/ui_war.gd`  (720 строк)
Экран «Армия и война» (desk 13): армия, мобилизация, объявление войны, ход войны, мир.

Функции (19): `build_war_windows`, `on_war_declare`, `update_war_talk`, `on_war_peace`, `war_select`, `update_war_windows`, `mil_side_total`, `war_map_on`, `war_occ_build`, `draw_war_overlay`, `war_token_pos`, `draw_war_tokens`, `draw_sea_lanes`, `war_ship`, `war_token_at`, `war_node_at`, `war_map_click`, `war_tip`, `war_hover`

Константы (3): `ArmySym`, `WAR_C0`, `WAR_C1`

Переменные (19): `war_army_rt`, `war_unit_rt`, `war_ops_rt`, `war_log_rt`, `war_list`, `war_list_key`, `war_btn`, `war_tgt`, `war_tgt_ids`, `war_note`, `war_msg`, `war_occ_ver`, `war_occ_tris`, `war_front`, `war_hover_tok`, `war_talk_rt`, `war_intl_rt`, `war_talk_chk`, `war_repar`

### `scripts/ui/ui_army.gd`  (352 строк)
v48_1: экран «Вооружённые силы» (desk 15): обзор, оборонный бюджет и его структура, комплектование и резерв,

Функции (4): `build_army_windows`, `ar_ui_bs`, `ar_card_fmt`, `update_army_windows`

Константы (2): `ArmyView`, `StatBarA`

Переменные (2): `arw`, `ar_msg`

### `scripts/ui/ui_settings.gd`  (446 строк)
v50_1: настройки (кнопка ⚙ в правом верхнем углу): графика (тема интерфейса, море на карте, анимации, масштаб),

Функции (18): `settings_extra_pages`, `settings_load`, `settings_save`, `settings_apply_static`, `music_dirs`, `click_name`, `build_settings_button`, `settings_open`, `build_settings_window`, `st_page`, `st_row`, `st_option`, `st_check`, `st_slider`, `settings_fill_saves`, `music_reload`, `show_start_window`, `start_text`

Константы (7): `UI_THEMES`, `SEA_NAMES`, `MUSIC_SETS`, `CLICK_SETS`, `UI_SCALES`, `SETTINGS_PATH`, `SETTINGS_KEYS`

Переменные (5): `st_ov`, `st_tabs`, `st_save_box`, `st_btn`, `start_ov`

### `scripts/ui/ui_budget.gd`  (490 строк)
v50_1: черновик бюджета и коалиционные переговоры о нём.

Функции (18): `bud_draft_on`, `bud_preview`, `bud_preview_text`, `bud_table_text`, `update_bud_head`, `on_bud_accept`, `bud_neg_open`, `bud_neg_close`, `bud_neg_fill`, `_all_agree`, `build_bud_oneoff`, `bud_oo_nudge`, `update_bud_oneoff`, `make_meas_button`, `meas_is_open`, `set_meas_open`, `build_meas_overlay`, `update_meas_window`

Константы (2): `BUD_WIN`, `BUD_PAY`

Переменные (9): `bn_ov`, `bn_rt`, `bn_box`, `meas_ov`, `meas_btn`, `meas_grid`, `meas_head_rt`, `meas_cards`, `meas_sig`

### `scripts/ui/ui_build.gd`  (550 строк)
v50_1: окно «Строительство». Выберите сооружение — справа видно, сколько стоит, что даст, как отнесутся группы

Функции (16): `build_build_window`, `bld_open`, `bld_clear`, `bld_bar`, `bld_sbtn`, `bld_row_card`, `bld_lbl`, `update_build_queues`, `bld_update_moved`, `bld_cancel`, `on_bld_meta`, `update_build_window`, `update_build_extra`, `bld_demand_text`, `build_click`, `draw_struct_icons`

Константы (2): `PROJ_CATS`, `PROJ_CAT_ICO`

Переменные (21): `bld_btns`, `bld_info_rt`, `bld_list_rt`, `bld_hint`, `bld_reg_rt`, `bld_mega_rt`, `bld_corp_rt`, `bld_cancel_btn`, `bld_sum_rt`, `bld_state_box`, `bld_priv_box`, `bld_prof_box`, `bld_plan_box`, `bld_auto_btn`, `bld_sci_rt`, `bld_sci_box`, `bld_port_title`, `bld_port_box`, `bld_st_rt`, `bld_sig`, `bld_rep_btn`

### `scripts/ui/ui_treaty.gd`  (204 строк)
v50_1: конструктор договоров — «чистый лист». Игрок выбирает партнёра, отмечает пункты, даёт договору название

Функции (5): `paper_style`, `ink_label`, `treaty_sheet_open`, `treaty_sheet_build`, `treaty_sheet_update`

Константы (3): `PAPER`, `INK`, `INK_DIM`

Переменные (7): `ts_ov`, `ts_title`, `ts_partner`, `ts_partners`, `ts_checks`, `ts_eval`, `ts_go`

### `scripts/ui/ui_vote.gd`  (673 строк)
v51_1: окно итогового голосования. Зал заседаний загорается место за местом: плитка в цвет партии, кружок в ней

Функции (20): `vote_plan_live`, `vt_plan_busy`, `vote_show`, `vote_build`, `vote_btn_pressed`, `vote_plan_open`, `vt_party_tag`, `vt_toggle_btn`, `vt_label`, `vote_plan_refresh`, `vote_plan_own`, `vote_plan_other`, `vote_plan_later`, `vote_plan_go`, `vote_layout_seats`, `vote_legend_text`, `vote_step`, `vote_draw`, `vt_stance_text`, `vote_done`

Константы (1): `VT_ANIM`

Переменные (30): `vt_ov`, `vt_hall`, `vt_title`, `vt_sub`, `vt_board`, `vt_table`, `vt_btn`, `vt_legend`, `vt_next`, `vt_next_btn`, `vt_res_box`, `vt_plan_box`, `vt_fc_lbl`, `vt_fc_bar`, `vt_mode_row`, `vt_plan_list`, `vt_plan_note`, `vt_later_btn`, `vt_seats`, `vt_tile`, `vt_t`, `vt_tw`, `vt_data`, `vt_stage`, `vt_plan_bid`, `vt_from_plan`, `vt_mode`, `vt_deals`, `vt_press`, `vt_pv`

### `scripts/ui/ui_regime.gd`  (831 строк)
v51_1: раздел «Политика» при недемократическом режиме. Вместо парламента, партий и опросов — «Вертикаль власти»

Функции (32): `es_skin_acc`, `reg_skin`, `reg_acc`, `build_regime_windows`, `reg_do`, `win_mode_ok`, `reg_ui_sync`, `reg_layout`, `reg_tabs`, `reg_tab_set`, `reg_apply_skin`, `reg_draw_watermark`, `reg_emblem`, `reg_transition`, `reg_build_rows`, `update_regime_windows`, `reg_clan_hint`, `reg_draw_head`, `reg_loy_col`, `reg_draw_map`, `reg_draw_meters`, `reg_draw_gauge`, `reg_draw_facade`, `reg_draw_und`, `build_dec_window`, `dec_changed`, `dec_changed_i`, `dec_open`, `dec_sel`, `dec_opts`, `dec_update`, `dec_sign`

Константы (6): `REG_SKIN`, `REG_POL_DESKS`, `REG_HIDE_AUTH`, `REG_HIDE_HYB`, `REG_WINS_HYB`, `REG_TOOL_GROUPS`

Переменные (28): `ui_reg_cls`, `rg_head`, `rg_map`, `rg_clan_box`, `rg_clan_rows`, `rg_tool_btns`, `rg_meters`, `rg_gauge`, `rg_mood_rt`, `rg_log_rt`, `rg_facade`, `rg_facade_rt`, `rg_und_box`, `rg_und_rows`, `rg_repr_rt`, `rg_repr_btns`, `rg_trans`, `rg_clan_cls`, `dec_checks`, `dec_opt`, `dec_orgs_box`, `dec_orgs_sig`, `dec_orgs`, `dec_rt`, `dec_cost`, `dec_btn`, `dec_open_btn`, `reg_sync_busy`

### `scripts/ui/ui_econsys.gd`  (637 строк)
v51_1: «Экономика» → «Управление экономикой» (у каждой модели свой пульт: Госплан, промполитика, социальное

Функции (23): `es_acc`, `es_skin_acc`, `build_econsys_windows`, `es_ui_sync`, `reg_tab_set_plain`, `es_flash`, `es_build_controls`, `es_add_btn`, `es_do`, `update_es_windows`, `es_draw_head`, `es_draw_dash`, `es_draw_index`, `es_draw_gauge`, `es_draw_donut`, `es_draw_bars`, `es_draw_plan`, `update_corp_windows`, `co_initials`, `co_list_input`, `co_draw_list`, `co_draw_head`, `co_draw_bar`

Константы (3): `ES_SKIN`, `ECON_DESKS`, `SECT_COL`

Переменные (15): `ui_es_cls`, `es_head`, `es_ctl_box`, `es_btns`, `es_dash`, `es_info_rt`, `es_log_rt`, `co_listc`, `co_head`, `co_card_rt`, `co_btns`, `co_bar`, `co_for_rt`, `co_for_btns`, `co_row_h`

### `scripts/ui/ui_orgs.gd`  (448 строк)
v52_1: рамка «Организации». Вкладки — международные организации (ваши — с отметкой ●). Окна: шапка организации,

Функции (13): `io_bar_h`, `io_bar_row`, `io_group`, `io_bar_layout`, `io_bar_groups`, `io_col`, `build_io_windows`, `update_io_windows`, `io_fx_text`, `io_agenda_fx_text`, `io_draw_head`, `io_draw_members`, `io_cap1`

Константы (1): `IO_TYPE_COL`

Переменные (17): `io_tabs`, `io_head_ctl`, `io_mem_ctl`, `io_ext_rt`, `io_info_rt`, `io_act_box`, `io_ses_rt`, `io_vote_btns`, `io_hist_rt`, `io_built_for`, `io_row_mem`, `io_row_oth`, `io_lbl_cand`, `io_lbl_oth`, `io_other_opt`, `io_groups_key`, `io_bar_hh`

### `scripts/ui/ui_today.gd`  (683 строк)
0.57: разгрузка игрока. Рамка «Сегодня», рамка «Мир» (бывшие «Карта» и «Организации»), поиск по игре (Ctrl+K),

Функции (29): `bm_sig`, `inbox_todo`, `layout_remember`, `rules_open`, `rules_todo`, `srch_extra`, `today_bm_defs`, `build_today_windows`, `today_problems`, `today_todo`, `today_dates`, `today_nums`, `today_row`, `today_tip`, `update_today`, `goto_win`, `nav_note`, `nav_back`, `update_chips_extra`, `spark_text`, `chip_tip`, `srch_collect`, `srch_open`, `srch_build`, `srch_key`, `srch_fill`, `srch_run`, `ui_hotkey`, `esc_close`

Константы (7): `DESK_TODAY`, `FRAME_ORDER`, `DESK_NAMES`, `DAY_TIPS`, `CHIP_HELP`, `SPARK`, `CHIP_HKEY`

Переменные (17): `td_todo_box`, `td_todo_sig`, `td_prob_rt`, `td_prob_more`, `td_dates_rt`, `td_nums_rt`, `td_tip_rt`, `td_act_box`, `td_act_sig`, `nav_hist`, `nav_skip`, `srch_ov`, `srch_edit`, `srch_list`, `srch_hint`, `srch_items`, `srch_map`

### `scripts/ui/ui_inbox.gd`  (168 строк)
0.57: «Входящие» — малые события не прерывают игру. Они ждут в списке на рамке «Сегодня» несколько месяцев,

Функции (11): `inbox_on`, `inbox_important`, `inbox_route`, `notify_inbox`, `inbox_title`, `inbox_pick`, `inbox_auto`, `inbox_open`, `inbox_all_auto`, `inbox_month`, `inbox_todo`

Константы (4): `INBOX_MONTHS`, `INBOX_MAX`, `INBOX_ASK_YEAR`, `INBOX_ALWAYS_CATS`

Переменные (5): `inbox`, `inbox_year`, `inbox_asked`, `inbox_bypass`, `inbox_done_month`

### `scripts/ui/ui_notify.gd`  (240 строк)
0.57: уведомления. Плашки с звуком только для важного, точки на вкладках (красная — решить сейчас, жёлтая — можно улучшить,

Функции (12): `nav_extras`, `nt_class`, `nt_mode`, `nt_plain`, `notify_log`, `nt_stop_check`, `build_notify_ui`, `nt_toast`, `nt_dot_state`, `update_ui_extras`, `nt_autoslow`, `settings_extra_pages`

Константы (4): `NOTIFY_TAG`, `NOTIFY_CLASSES`, `NOTIFY_MODES`, `NT_MAX_TOASTS`

Переменные (8): `nt_layer`, `nt_box`, `nt_last_text`, `nt_new`, `nt_dots`, `nt_crisis`, `nt_rx`, `nt_hist`

### `scripts/ui/ui_nav.gd`  (533 строк)
0.57: навигация. Кнопки «?» и «★» в окнах, закладки, раскладки окон (плиткой, готовые наборы, «своя»), меню «Ещё»,

Функции (31): `win_id_of`, `win_help_text`, `on_win_help`, `help_open`, `help_term`, `help_build`, `bm_list`, `bm_has`, `bm_toggle`, `on_win_star`, `bm_entry`, `today_bm_defs`, `bm_sig`, `srch_extra`, `layout_ids`, `layout_tile_ids`, `layout_tile`, `layout_preset`, `layout_snapshot`, `layout_apply_snapshot`, `layout_own_save`, `layout_own_load`, `layout_remember`, `lay_is_old_default`, `layout_restore_all`, `win_menu_extra`, `win_menu_pick`, `build_more_menu`, `nav_extras`, `nav_init`, `subbar_hide_absent`

Константы (5): `WIN_HELP`, `GLOSSARY`, `LAYOUT_PRESETS`, `TILE_LEFT`, `LAY_MIGRATE`

Переменные (6): `help_ov`, `help_title`, `help_rt`, `lay_prev`, `more_btn`, `show_all_btn`

### `scripts/ui/ui_rules.gd`  (367 строк)
0.57: правила автоматики «если — то». Игрок задаёт условие, действие и предел; игра либо делает сама, либо предлагает

Функции (17): `rule_ind_val`, `rule_actions`, `rule_act_title`, `rule_text`, `rule_cond_ok`, `rule_hot_regions`, `rules_month`, `rule_prop_has`, `rule_do`, `rule_accept`, `rule_reject`, `rules_undo_last`, `rules_todo`, `rules_open`, `rules_build`, `rule_add_from_form`, `rules_fill`

Константы (5): `RULE_INDS`, `RULE_IND_ORDER`, `RULE_COOL`, `RULE_MAX`, `RULE_STEP_CAP`

Переменные (12): `rules`, `rule_props`, `rule_undo`, `ru_ov`, `ru_list`, `ru_ind`, `ru_op`, `ru_val`, `ru_act`, `ru_amt`, `ru_mode`, `ru_acts`

### `main.gd`  (1332 строк)
Symphony: корневой скрипт (вершина цепочки наследования, см. scripts/CHAIN.txt).

Функции (40): `country_arg`, `party_arg`, `seed_arg`, `apply_country`, `game_version`, `apply_markets`, `de_base_snap`, `cdat`, `diff_color`, `menu_title`, `menu_rt`, `menu_bar`, `sector_shares`, `country_strengths`, `fill_country_card`, `opt_index`, `menu_update_est`, `opt_row`, `opt_choice`, `opt_slider`, `fmt_mult`, `fmt_k`, `build_settings_panel`, `opts_from_args`, `show_country_menu`, `menu_vis_col`, `menu_seats_txt`, `menu_gdp`, `menu_in_org`, `menu_govform`, `menu_country_ok`, `menu_apply_filters`, `menu_party_rows`, `menu_fill_parties`, `menu_party_card`, `update_menu_party`, `choose_country`, `_ready`, `_input`, `_unhandled_input`

Константы (7): `DE_BASE_KEYS`, `OBSERVER_ID`, `MENU_POL_COLS`, `MENU_GOVFORM`, `MENU_GOVFORM_N`, `MENU_FILTERS`, `MENU_ROLE_N`

Переменные (12): `de_base`, `menu_est_code`, `menu_sit_rt`, `menu_sit_code`, `menu_est_lbl`, `menu_ag_k`, `menu_flt`, `menu_leg`, `menu_hemi`, `menu_party_grid`, `menu_party_lbl`, `menu_party_sel`

## Классы (`scripts/classes/`)

- `agent_hist_view.gd` — extends Control, 25 строк
- `agent_map_view.gd` — extends Control, 228 строк
- `agent_pop.gd` — extends RefCounted, 761 строк
- `army_view.gd` — extends Control, 164 строк
- `country_map.gd` — extends Control, 661 строк
- `cult_chart.gd` — extends Control, 51 строк
- `dep_chart.gd` — extends Control, 60 строк
- `econ_chart.gd` — extends Control, 86 строк
- `election_view.gd` — extends Control, 187 строк
- `event_art.gd` — extends Control, 102 строк
- `faith_chart.gd` — extends Control, 53 строк
- `flags.gd` — extends RefCounted, 298 строк
- `float_window.gd` — extends Control, 378 строк
- `gfx.gd` — extends RefCounted, 194 строк
- `goods_view.gd` — extends Control, 75 строк
- `head_view.gd` — extends Control, 89 строк
- `ico.gd` — extends Control, 223 строк
- `map_labels.gd` — extends RefCounted, 276 строк
- `market_bar.gd` — extends Control, 68 строк
- `party_hemi.gd` — extends Control, 105 строк
- `pie_chart.gd` — extends Control, 45 строк
- `spark.gd` — extends Control, 71 строк
- `stat_bar.gd` — extends Control, 47 строк
- `tech_view.gd` — extends Control, 317 строк
