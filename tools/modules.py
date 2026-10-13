# Распределение функций по модулям (порядок = цепочка наследования, от основы к вершине)
import re

MODULES = [
    ('util', 'logic', 'Мелкие помощники: перевод, форматирование, цвета, даты.'),
    ('policy', 'logic', 'Бюджетная политика: ползунки, блокировки, уровни, эффекты, моды законов.'),
    ('laws', 'logic', 'Законы: варианты, голосование, числовые законы, меры и действия.'),
    ('economy', 'logic', 'Экономика: рынки, сооружения, центробанк, торговля, шаг экономики.'),
    ('regions', 'logic', 'Регионы: лояльность, недовольство, проекты, региональная экономика.'),
    ('elections', 'logic', 'Выборы: голоса, места, президентские и парламентские выборы, конкуренция партий.'),
    ('coalition', 'logic', 'Коалиция и правительство: партии, министры, требования, вотум недоверия.'),
    ('events', 'logic', 'События и новости.'),
    ('turn', 'logic', 'Ход игры: один месяц, конец игры, начальная установка состояния.'),
    ('world', 'logic', 'Дипломатия и живой мир.'),
    ('radical', 'logic', 'Радикальные законы: форма правления, строй, выход из ЕС и т.д.'),
    ('agents', 'logic', 'Население: подключение агентов к голосованию, шагу и протестам.'),
    ('autopilot', 'logic', 'Помощник и автопилот.'),
    ('log', 'logic', 'Структурированный журнал.'),
    ('ui_core', 'ui', 'Интерфейс: окна, тема, верхняя панель, экран «Бюджет», обновление.'),
    ('ui_map', 'ui', 'Интерфейс: карта, таблица регионов, региональная экономика.'),
    ('ui_politics', 'ui', 'Интерфейс: парламент, полукруг, таблица партий.'),
    ('ui_laws', 'ui', 'Интерфейс: окно законов.'),
    ('ui_gov', 'ui', 'Интерфейс: правительство и коалиционные переговоры.'),
    ('ui_econ', 'ui', 'Интерфейс: экран «Экономика».'),
    ('ui_world', 'ui', 'Интерфейс: дипломатия.'),
    ('ui_pop', 'ui', 'Интерфейс: вкладка «Население».'),
    ('ui_events', 'ui', 'Интерфейс: окна событий и выборов.'),
    ('main', 'main', 'Symphony: корневой скрипт (вершина цепочки наследования, см. scripts/CHAIN.txt).'),
]

W = lambda s: s.split()

EXPLICIT = {
    'main': W('country_arg apply_country apply_markets show_country_menu choose_country _ready _unhandled_input'),
    'util': W('tm cap1 low1 build_loc loc loc_tree sg col_delta find_by_id policy_title sat mrate years_passed date_text months_text date_after date_short fmt_n fmt_sg months_short arrow_text delta_col col_signed sbox make_dot_tex scale_color fx_col stat_color good_col turn_date total_pop pop_ratio amt std_index polygon_area jag_edge hint_line bit_text'),
    'policy': W('approval add_support add_all_support set_policy apply_reg_delta describe_reg region_support expected factor fatigue target_support pp0 expected_pp is_abs abs_range sync_abs_policies lock_active add_lock lock_allowed lock_allowed_share lock_until_text lock_note expire_locks emit_safe_pct emit_excess lvl_sum issue_multiplier regional_potential per_capita avg_per_capita tier_name dev_gain_mult tax_ratio project_cost_pct roi_estimate roi_text effective_reg demand_cur compute_budget update_levels budget_changes apply_fx describe_fx init_laws compute_mods recompute_mods parl_term pres_term impeach_seats crisis_limit debt_rate scale_fx mod_good_dir boost_good describe_econ'),
    'laws': W('variant_of variant_part cur_idx law_cost dict_diff support_delta variant_stance variant_votes upper_check upper_text negotiate_variant adopt_variant mod_item variant_effect_items items_pros_cons law_reform_count law_demand_of law_demand_met law_demand_text fmt_param param_grid make_param_topic build_law_topics is_fund law_need demand_idx demand_dict_met param_scale_text de_law_params de_fix_ps de_adapt_topics brake_allowed brake_active brake_step brake_text pres_needs_runoff fx_items reg_item fx_pros_cons layer_ramp level_effect_list level_effects_text variant_swing do_measure do_action'),
    'economy': W('mk_def init_economy tariff_rev_share import_share roy_rev_share ec_budget_lines struct_count struct_total struct_cond_factor struct_step complete_struct repair_cost_pct repair_all struct_total_count world_step cb_target cb_name cb_step set_rate income_parts households_step bconf_reasons business_step gov_idx markets_step trade_step economy_step hist_push apply_econ region_struct_text struct_effect_text'),
    'regions': W('recalc_weights new_governor transfer_avg reg_avg update_regions complete_project start_project cancel_project appoint_governor set_transfer equalize_transfers do_region_action region_ok calibrate_regions build_geometry de_start_parliament sec_idx sec_cur dominant_sector reg_growth rdebt_target reg_zones_end reg_econ_step reg_year_report reg_events_all tool_req tool_effect_text reg_tool_factor tool_cost_pct reg_tool_buy select_region'),
    'elections': W('vote_weights region_shares region_shares_legacy parl_shares allocate_seats sorted_parties head_cand_ok head_cand_name head_row head_term_months hold_head hold_head_core head_outcome head_present hold_head_direct hold_head_indirect hold_head_council head_campaign_check hold_parliament hold_parliament_core election_title campaign_check electorate_text national_shares democracy_index democracy_name apply_competition democracy_text sham_shares party_attitude'),
    'coalition': W('tolerates against_seats gov_ok gov_margin seat_pad gov_seats coalition_names opp_bloc check_impeachment party_stance demand_value demand_met demand_score demand_lines port_score sat_target sat_reason grant_ministries release_ministries assign_ministries add_member remove_member cycle_ministry select_party do_concession fulfill_demands fulfill_party_demands fulfill_coalition_demands form_government check_government show_no_confidence resolve_no_confidence toggle_coalition ministries_of ministry_fx ministry_is_special ministry_role_text ministry_items new_minister sync_ministers cabinet_items assign_ministry replace_minister reshuffle_cabinet quota_for sat_breakdown willingness add_commitment check_commitments invite_party coal_text pick_weighted_partner coal_pick show_coal_event apply_psat'),
    'events': W('ev_de_only event_ok show_news ev_kind_info ev_style ev_context_text present_event show_event choose fire_scripted gen_dip_event dip_events w_help_event'),
    'turn': W('next_turn log_month log_year_summary log_policy_changes end_game skip_months on_auto_toggled on_auto_tick init_state'),
    'world': W('dip_init dip_rel_name dip_target dip_rel_factor dip_growth dip_sec dip_infra_bonus dip_avg_rel dip_apply_mods dip_change dip_step track_name dip_fx_apply dip_fx_text dip_do_action dip_track_cost dip_upgrade dip_downgrade dip_all w_codes world_init w_stance_name w_share w_cur_growth w_pot world_spill_g w_shock_g world_spill_infl world_ea_update w_start_crisis world_help w_election w_player_stance w_shock_step w_party_name w_party_for wsim_step world_infl_bias world_news world_info remap_base_ps foreign_region_text'),
    'radical': W('arch_ps RV rid_of regime_id econ_id decree_power radical_bypass radical_req law_locked auth_idx radical_enact open_mult radical_dyn radical_step show_uprising radical_roll radical_text active_rids radical_events radical_add_variants radical_inject'),
    'agents': W('ag_k ag_make_pos ag_support_arr ag_build ag_calibrate ag_zs ag_step ag_unrest_term ag_region_table ag_exit_report ag_toggle ag_set_k ag_pick ag_random_agent ag_reset_ui'),
    'autopilot': W('ap_can_adj ap_note_change ap_flush_log autobalance_step balance_now apply_preset fx_score auto_event_pick auto_event_ok auto_resolve_event autobuild_step autopilot_step advisor_lines'),
    'log': W('log_guess_cat log_match log_add log_chip log_render log_cell log_render_month log_render_year log_rebuild log_clear on_log_filter build_log_filters log_line log_sys log_header log_tag'),
    'ui_core': W('new_window layout_windows fix_wraps fix_wraps_later on_wrap_timer reset_layout show_desk build_ui add_title add_note add_wrap_label make_button make_rt add_slider set_bar add_bar color_button make_theme accent_for_desk polish_tree make_chip set_chip update_chips build_subbar update_subbar show_tab build_budget_windows build_log_and_event update_slider_label update_forecast update_stats update_polls refresh on_slider configure_slider toggle_slider_mode slider_value_for draw_budget_viz on_log_detail build_auto_window on_ap_toggle on_ap_target on_ap_style update_auto_window'),
    'ui_map': W('map_prepare map_view map_country_rect map_fit_rect map_zoom_cmd map_zoom_at map_clamp unit_at ctx_at unit_tip map_click map_apply_mode on_map_input on_layer_selected layer_info layer_leader layer_color cl_info cl_color unit_color draw_map region_tip region_sort_value update_regions_ui update_region_table update_transfer_ui update_region_info on_transfer_slider on_table_row set_sort build_map_windows build_regecon_window update_regecon regecon_inject on_tool_selected'),
    'ui_politics': W('build_politics_windows build_hemicycle draw_hemi on_hemi_input update_parliament on_party_button update_party_table update_party_detail ministry_effect_text'),
    'ui_laws': W('build_law_windows on_law_cat on_topic_pressed first_other_variant on_card_input on_adopt on_negotiate update_law_windows update_law_effects refit_law_cards update_law_votes build_law_slider on_law_slider build_law_list update_law_headers update_law_detail'),
    'ui_gov': W('build_gov_windows select_ministry select_neg_party on_neg_selected on_neg_promise on_neg_main on_neg_conc on_neg_dem on_assign_ministry on_replace_minister update_gov_windows update_coal_summary update_cabinet update_min_detail refit_gov update_neg refit_neg update_cabfx update_commit'),
    'ui_econ': W('ec_slider build_econ_windows on_cb_auto on_rate_slider on_tariff_slider on_roy_slider on_focus_selected on_chart_selected update_chart update_econ_windows'),
    'ui_world': W('select_dip build_dip_windows update_dip_windows'),
    'ui_pop': W('build_pop_windows ag_agent_text update_pop_windows'),
    'ui_events': W('build_election_window show_election show_head_election election_continue build_event_window refit_event'),
}
_owner = {}
for m, names in EXPLICIT.items():
    for n in names:
        assert n not in _owner, n
        _owner[n] = m


def assign(name):
    return _owner.get(name)
