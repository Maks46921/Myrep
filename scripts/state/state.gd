# Текущее состояние партии: показатели, законы, парламент, узлы интерфейса.
extends "res://scripts/state/state_data.gd"

static var pending_code := ""
static var pending_party := 0

# Настройки новой игры (задаются в меню перед стартом и не меняются во время игры; переживают перезагрузку сцены)
static var game_opts := {"agents": true, "k": 0, "seed": 0, "ev": 1.0, "news": 1.0, "econ": 1, "volat": 1.0, "cap": 1.0, "detail": false, "fedev": 1, "socev": 1, "exev": 1, "milev": 1, "revev": 1, "rlev": 1, "bldev": 1, "tut": 1, "coal": 1, "observer": false, "music": 0.45, "sfx": 0.6}

var ccode := "DE"
var map_reg_pick: OptionButton = null   # список регионов в окне карты
var emit_note: Label = null   # пояснение под ползунком эмиссии

var risk_prem := 0.0

var minority_ok := false

var turn := 0                # месяцев с начала игры

var year := START_YEAR

var month := 1

var gdp := 4600.0            # годовой ВВП, млрд €

var debt := 2950.0

var growth := 0.8            # годовой темп роста, %

var inflation := 2.2         # годовая инфляция, %

var unemployment := 6.3

var shock := 0.0             # разовые толчки роста, затухают

var other_rev := 6.7

var pol := {}                # текущие значения ползунков

var pol_def := {}

var prev_pol := {}

var policy_by_key := {}

var lvl := {"edu_lvl": 50.0, "health_lvl": 50.0, "security_lvl": 50.0, "infra_lvl": 50.0,
	"env_lvl": 50.0, "equality": 50.0, "corruption": 50.0}

var support := {}            # поддержка власти по группам, 0-100

var bias := {}               # постоянные сдвиги поддержки (от законов)

var mods: Dictionary = BASE_MODS.duplicate()

var cooldown := {}

var capital := 40.0
var cap_ai := false   # 0.55.5: капитал сейчас «одолжен» ИИ-партии (cap_swap) — ей в минус нельзя
var ev_hist := {}             # v46_1: id события -> {"t": последний месяц, "n": сколько раз было, "o": выбранный вариант}
var ev_queue: Array = []      # v46_1: продолжения цепочек [{"id", "due", "rid"}]
var ev_later: Array = []      # v46_1: отложенные последствия [{"due", "fx", "t", "rid"}]
var ev_log: Array = []        # v46_1: последние решения
var noc_constr := false       # v44_1: конструктивный вотум недоверия (нужен преемник)
var tech_adj := 1.0           # v44_1: множитель скорости исследований (договоры, этика, утечка умов)
var tech_pas_mult := 1.0      # v44_1: множитель пассивного изучения (совместные проекты)
var nato_ovr := -1            # v44_1: членство игрока в НАТО (-1 по данным мира, 0 вышел/не член, 1 член)
var free_adj := 0.0           # v44_1: поправка свободы слова от состояния СМИ

var seats: Array[int] = []

var in_coalition: Array[bool] = []

var warned := {}

var crisis_months := 0
var prev_head: Array = []     # v35: доли кандидатов в 1-м туре прошлых выборов главы государства
var h12 := {}                 # v35: помесячная история показателей за последние 12 мес.
var observer := false         # v35: режим наблюдателя — вашей партией управляет ИИ
var deadlock := 0             # v35: досрочных выборов подряд из-за несформированного правительства
var minority_gov := false     # v35: правительство меньшинства на терпимости (выход из кризиса)
var coal_talks := false       # v53: после выборов идут коалиционные переговоры (коалицию собирает игрок)
var coal_tried: Array = []    # v53: партии, с которыми уже говорили в этом раунде переговоров
var pm_lead := false          # v38: глава правительства — игрок, хотя его партия в коалиции не крупнейшая (до первых выборов)
var techno_until := -1        # v35: техническое правительство до этого месяца
var extra_mins := {}          # v35: p -> обещанные министерства сверх квоты
var cn_draft := {}            # 0.56: проект коалиционного соглашения в окне переговоров
var cn_pat := {}              # 0.56: терпение партий на переговорах (p -> раундов до ухода)
var cn_ans := {}              # 0.56: последний ответ партии на проект (p -> текст)
var cn_out := {}              # 0.56: партия ушла из переговоров (p -> ход)
var cn_round := 0             # 0.56: номер раунда переговоров
var coal_deal := {}           # 0.56: подписанное коалиционное соглашение (министерства, глава правительства, программа)
var neg_offer_mins := 0       # v35: министерства сверх квоты в текущем предложении
var crisis_offered := false   # v35: событие выхода из кризиса уже показано

var impeach_warned := false

var last_parl := -11
var gov_born := -99   # 0.58: месяц, когда после выборов сложилось новое правительство («медовый месяц» поддержки)

var last_pres := 0

var pres_due := -1           # номер хода, когда выбирают главу государства (-1 — не предвидится)

var pres_camp := 0.0         # бонус вашему кандидату от кампании

var pres_camp_done := -100

var pres_party := -1         # партия действующего президента (если выбран на выборах в игре)

var hemi_rad := 0.036

var el_head

var game_over := false

var current_event := {}

var event_region := -1

var prev_items := {}

var year_start := {}

var charisma: Array[float] = []

var satis := {}              # довольство партнёров по коалиции

var joined := {}             # когда партия вошла в коалицию (месяц)

var conc := {}               # бонус/штраф от уступок и законов (затухает)

var ministries: Array[int] = []   # кто держит министерство (0 — ваша партия)

var selected_party := 1

var last_nocon := -100
# --- оппозиция и выбор партии (opposition.gd) ---
var group_base0 := {}            # 0.56: стартовая поддержка групп до смены партии игрока (для нейтрального старта)
var reg_loy0 := {}               # 0.56: лояльность регионов на старте (uid -> число)
var player_orig := 0            # какая партия была выбрана игроком (0 — по умолчанию)
var martial := false            # 0.55.4: военное положение (выборы откладываются, роспуск и поправки к конституции запрещены)
var martial_calm := 0           # 0.55.4: месяцев без войны при военном положении (правительство ИИ снимает его через 6)
var opp_mode := false           # вы в оппозиции: бюджет и министерства у других
var opp_gov := {}               # правительство без вас: members, pm, seats, stab
var opp_cd := {}                # перезарядка действий оппозиции и переговоров
var prel := []                  # отношения вашей партии с остальными (0–100)
var pacts := {}                 # действующие соглашения: партия -> {вид: месяцев}
var offer_pending := false
var offer_gov := {}
var opp_ap_saved := {}
# --- партийный ИИ, идеология, законопроекты (aiparty.gd) ---
var pcap := []                  # политический капитал каждой партии (0 — не используется, у вас свой capital)
var prm := []                   # отношения партий друг с другом (prm[0] — это prel)
var ai_pen := {}                # партия -> месяцев штрафа от атак других партий
var ai_blocs := {}              # партия -> партнёр по предвыборному блоку (ИИ)
var ai_stats := {}              # счётчики действий ИИ (для тестов и журнала)
var ideo_c := {}                # кэш идеологии
var idl := 70.0                 # верность партийной линии (0–100)
var idl_low := 0
var idl_warned := false
var bills: Array = []           # законопроекты в работе
var bill_seq := 0
var vote_sponsor := 0           # чья партия вносит закон при голосовании
var cost_mult := 1.0
var vote_pl := ""              # 0.56: как голосует фракция игрока по чужому законопроекту ("" / line / yes / no / abst / free)
var pl_disc := 0.0             # 0.56: ослабление дисциплины фракции после голосований против линии партии (0..1)
var pa_props: Array = []       # 0.56: предложения министров-партнёров по их статьям бюджета (ждут вето игрока)
var pa_seq := 0
var bq: Array = []             # 0.56: очередь госстроек {uid, id, i, ate, cost, done, months, upg, auto}
var bq_priv: Array = []        # 0.56: стройки частных инвесторов {uid, id, i, cost, done, months, corp, brk}
var bq_uid := 0
var bld_budget := -1.0         # 0.56: линия бюджета «Строительство», % ВВП в год (в черновике — новое значение)
var bld_budget0 := -1.0        # 0.56: утверждённое значение, пока в плане бюджета есть правка
var bld_breaks := {}           # 0.56: pid -> налоговая льгота частным инвесторам
var bld_plan: Array = []       # 0.56: годовой план автостроительства министерств
var bld_plan_year := -1
var bq_spent := 0.0            # 0.56: потрачено на госстройки за прошлый месяц, млрд
var bq_priv_spent := 0.0
var bq_brk_spent := 0.0
var pa_fail := {}              # 0.56: tid -> ход, когда чужой законопроект провалился (год его не вносят снова)
var pa_drift := {}             # 0.56: на сколько министры-партнёры сдвинули статьи за этот год
var bill_sel := -1

var pop_w: Array[float] = []

var gdp_w: Array[float] = []

var neighbors: Array = []

var auto0 := 12.0

var pol_abs := {}            # суммы статей в млрд/год (для режима «млрд»)

var pol_abs_mode := {}       # key -> true, если ползунок в режиме «млрд»

var locks := {}              # обязательства: key -> {dir, share, amount, until}

var slider_busy := false

var growth_ema := 0.8
var def_ref := -99.0          # v35: опорный дефицит для бюджетного импульса (см. macro_step)
var tax_ref := -99.0          # v35: опора налоговой нагрузки для роста (см. macro_step)
var debt_start := -99.0       # v35: долг на старте, % ВВП (см. debt_drag)
var g_target_last := 0.0      # последняя цель роста (для отладки и подсказок)
var growth_trend := -99.0      # v35: медленный тренд роста (≈5 лет) — от него, а не от постоянного G_NEU, безработица реагирует на рост

var gdp_base := 4600.0       # ВВП без учёта развития регионов

var pot0 := 1.0

var pop0 := 80.0

var hemi_pos: Array = []

var hemi_party: Array[int] = []

var hemi_px: Array = []

var hemi_dot := 5.0

var hemi_hover := -1

var table_order: Array[int] = []

var sort_col := 0

var sort_desc := false

var regions: Array = []      # состояние регионов

var reg_mix: Array = []      # доли групп в регионах

var ag_on := true

var ag_k_pref := 0           # 0 = авто

var ag_exact := false        # true: считать всех агентов (выборы), false: выборка (опросы)

var ag_cache := {}

var ag_ver := 0

var ag_phase := 0

var ag_pos: Array = []       # позиции партий (стандартизованные)

var ag_pos_raw: Array = []   # позиции партий в осях групп

var ag_prot0: Array = []

var ag_sel := -1

var ag_ui := {}

var ag_ui_ver := -1

var reg_cd: Array = []       # перерывы действий по регионам

var reg_poll: Array = []     # доли партий по регионам (для карты)

var region_polys: Array = [] # полигоны регионов (0..100)

var region_centers: Array = []

var selected_region := 0

var hover_region := -1

var map_layer := 0

# ============================================================
#  ЭЛЕМЕНТЫ ИНТЕРФЕЙСА
# ============================================================

var workspace: Control
var meas_q := -1                   # 0.56: квартал, в котором считаются разовые меры
var meas_qn := 0                   # сколько мер проведено в этом квартале
var modal_layer: Control = null   # 0.56: слой поверх «Технологий» и «Кризисов» — окна события и выборов

var wins := {}

var current_desk := 0

var desk_buttons: Array = []

var top_label: Label

var next_btn: Button
var map_base: Control        # карта на всю рабочую область (основа интерфейса); остальные окна лежат поверх
var win_menu: MenuButton
var fmap_sel_unit := -1      # чужой регион, открытый вторым щелчком по стране
var fmap_win_open := false

var play_btn: Button
var speed_opt: OptionButton
var speed_last := 1
var day_btn: Button
var week_btn: Button

var day := 1                  # день месяца (календарь; месячный шаг экономики — на границе месяцев)
var month_done := 0.0
var last_ecf := {"g": 0.0, "infl": 0.0, "unemp": 0.0}
var last_deficit_pct := 0.0
var month_snap := {}
var day_total := 0            # дней с начала игры
var play_idx := 0             # скорость авто-хода: индекс в PLAY_SPEEDS (0 — пауза)
var day_acc := 0.0

var sliders := {}            # key -> {"slider", "label", "title"}

var bars := {}

var tax_total_label: Label

var spend_total_label: Label

var forecast_rt: RichTextLabel
var forecast_sum_rt: RichTextLabel
var ec_pp_fold: RichTextLabel
var ec_cb_fold: RichTextLabel
var ec_gf_fold: RichTextLabel
var ec_st_fold: RichTextLabel
var ui_detail: bool = true    # v35: пояснения всегда показаны
var note_nodes: Array = []
var tails: Dictionary = {}
var fold_nodes: Array = []

var stats_label: RichTextLabel

var measure_rows := {}
var meas_note_rt: RichTextLabel = null   # 0.56: сводка в окне «Разовые меры» на вкладке «Бюджет»

var action_rows := {}

var party_rows: Array = []

var seat_bar: HBoxContainer

var pol_header: Label

var polls_rt: RichTextLabel

var log_box: VBoxContainer       # 0.56: журнал — список рамок месяцев (раньше RichTextLabel)
var log_scroll: ScrollContainer = null
var log_open := {}               # 0.56: месяц журнала -> раскрыт ли (выбор игрока; по умолчанию открыты последние 3)
var log_ui_gs: Array = []        # 0.56: рамки месяцев на экране: {key, title, closed, fr, head, body, es, n, nbig, open}

var event_label: RichTextLabel

var ev_art: Control = null      # v46_1: иллюстрированная шапка события
var ev_adv: RichTextLabel = null # v46_1: совет и память о прошлых решениях
var ev_banner: PanelContainer

var ev_glyph: Label

var ev_kind_lbl: Label

var ev_meta_lbl: Label

var ev_ctx: RichTextLabel

var ev_hint: Label

var election_open := false

var elec_end := ""

var prev_vote: Array = []
var prev_raw: Array = []      # 0.56: голоса партий (до барьера) на прошлых выборах — от них считается предел сдвига

var camp_turn := -100

var el_view

var el_banner: PanelContainer

var el_title: Label

var el_sub: Label

var el_meta: Label

var el_verdict_box: PanelContainer

var el_verdict_title: Label

var el_verdict_rt: RichTextLabel

var el_btn: Button

var el_tween: Tween

var event_text := ""

var event_buttons: Array = []

var map_ctl: Control

var map_legend: Label

var reg_info_rt: RichTextLabel

var reg_action_rows := {}

var reg_table := {}

var hemi_ctl: Control
var upper_ctl: Control = null
var upper_pos: Array = []
var upper_rad := 0.04
var upper_lay_n := -1

var hemi_legend: RichTextLabel

var party_detail_rt: RichTextLabel

var party_btns: Array = []

var gov_header: Label

var min_buttons: Array = []

var reg_table_rows: Array = []

var reg_summary: Label

var gov_info_rt: RichTextLabel

var gov_buttons: Array = []

var proj_option: OptionButton

var proj_start: Button

var proj_cancel: Button

var proj_label: Label

var reg_transfer_slider: HSlider

var reg_transfer_label: Label

var transfer_sliders: Array = []

var transfer_labels: Array = []

var bud_tr_slider: HSlider = null   # 0.55.5: «Трансферты регионам» — строка с ползунком в бюджете

var bud_tr_label: Label = null
var bud_oo_label: Label = null          # 0.56: резерв на разовые меры
var bud_oo_rt: RichTextLabel = null
var bud_eq_box: VBoxContainer = null    # 0.56: место для программы «Выравнивание регионов» в «Бюджете»

var level_fx_rt: RichTextLabel

var chips := {}

var top_prev := {}

var log_detail := false

var log_toggle: Button

var event_boxes: Array = []

var event_fx_rts: Array = []

var budget_viz: Control

var viz_rev: Array = []

var viz_exp: Array = []

var low_months := 0

var wrap_timer: Timer

var wrap_pass := 0

var law_state := {}

var law_cd := {}

var rg_drip: Array = []   # 0.57.2: региональные сдвиги закона, растянутые на 12 месяцев: {d, n}

var law_index := {}

var sel_topic := "elect_threshold"

var sel_variant := 1

var law_cat := 0

var politics_page := 1
var econ_page := 5
var law_filter := 0
var law_query := ""
var law_search: LineEdit = null
var law_filter_btns: Array = []
var law_prog: Array = []
var law_demand_rt: RichTextLabel = null
var subbar2: HBoxContainer = null
var subbar3: HBoxContainer = null
var subbar4: HBoxContainer = null     # v55_1: рамка «Общество»
var sub4_buttons: Array = []
var society_page := 11
var sub3_buttons: Array = []
var map_page := 2
var sub2_buttons: Array = []
var gv_goods: Control = null
var gd_open := {}                # 0.55.5: раскрытые виды расходов (подробные товары) в окне «Товары: цены и спрос»
var gd_row_keys: Array = []      # 0.55.5: какой вид расходов в какой строке списка
var gv_groups: Control = null
var gd_head_rt: RichTextLabel = null
var gd_drv_rt: RichTextLabel = null
var gd_grp_rt: RichTextLabel = null
var gd_mode_opt: OptionButton = null

var subbar: HBoxContainer

var sub_buttons: Array = []

var law_cat_buttons: Array = []

var law_list_box: VBoxContainer

var law_topic_buttons := {}

var law_effects_rt: RichTextLabel

var law_detail_head: RichTextLabel

var law_cards: Array = []

var lv_head: RichTextLabel

var lv_bar: StatBar

var lv_sum: Label

var lv_rows: Array = []

var lv_neg: Button

var ministers: Array = []

var commitments: Array = []

var used_names := {}

var event_party := -1

var event_min := -1

var sel_ministry := 0

var neg_party := 1

var neg_promise := false
var coal_pie: PieChart = null
var music_btn: Button = null
var upper_rt: RichTextLabel = null   # v35: верхняя палата в окне парламента   # v35: круговая диаграмма влияния в коалиции

var coal_head: RichTextLabel

var coal_rows: Array = []

var cab_buttons: Array = []

var min_head: RichTextLabel

var min_cand_rows: Array = []

var min_replace_btn: Button

var neg_option: OptionButton

var neg_rt: RichTextLabel

var neg_promise_btn: Button

var neg_main_btn: Button
var neg_mins_btn: Button

var neg_conc_btn: Button

var neg_dem_btn: Button

var cabfx_rt: RichTextLabel

var commit_rt: RichTextLabel

# ============================================================
#  ЗАПУСК
# ============================================================

var end_reason := ""

var map_zoom := 1.0

var map_center := Vector2(300.0, 250.0)

# v49: плавная камера карты — цель, к которой масштаб и центр подтягиваются каждый кадр
var map_zoom_t := 1.0

var top_flag: TextureRect = null      # v49: флаг своей страны на кнопке смены страны

var map_center_t := Vector2(300.0, 250.0)

var map_inited := false

var map_drag := false

var map_drag_moved := false

var map_drag_start := Vector2.ZERO

var map_unit_parts: Array = []

var map_unit_rect: Array = []

var map_unit_local: Dictionary = {}

var map_ctx_parts: Array = []

var map_ctx_cent: Array = []

var map_bounds := Rect2()
var map_cc_outline: Dictionary = {}   # v35: кэш контура целой страны (код -> массив колец в координатах карты)

var map_hover_unit := -1

var map_hover_ctx := -1

var map_sel_unit := -1

var map_mode := "own"

# ============================================================
#  ЭКОНОМИКА v9: модель
# ============================================================
var ec := {}

# ============================================================
#  ЭКОНОМИКА v9: экран и окна
# ============================================================
var ec_mk_bars := {}

var ec_head_rt: RichTextLabel

var ec_pp_rt: RichTextLabel

var ec_bz_rt: RichTextLabel

var ec_cb_rt: RichTextLabel

var ec_cb_auto: CheckButton

var ec_cb_slider: HSlider

var ec_cb_val: Label

var ec_gf_rt: RichTextLabel

var ec_tariff: HSlider

var ec_tariff_val: Label

var ec_roy: HSlider

var ec_roy_val: Label

var ec_focus_opt: OptionButton

var ec_st_rt: RichTextLabel

var ec_repair_btn: Button

var ec_chart: EconChart

var ec_chart_opt: OptionButton

var ec_chart_keys: Array = ["growth", "infl", "unemp", "rate", "bconf", "cconf", "inv", "util", "ppi", "cpi", "fxs", "nx"]

var comp_loss := 0.0          # сколько голосов партия власти потеряла из-за конкуренции (доля) на последнем подсчёте

# ============================================================
#  ОКНО ЗАКОНОВ: ползунок для числовых законов, фундаментальные законы, список по разделам
# ============================================================
var law_slider_box: VBoxContainer

var law_slider: HSlider

var law_slider_val: Label

var law_slider_range: Label

var law_slider_busy := false
var law_pow := {}              # tid -> сила действия принятого варианта (0.5…1.5)
var law_pow_sel := {}          # tid -> сила, выбранная в окне законов
var law_sel_key := ""
var law_pow_slider: HSlider
var law_pow_box: VBoxContainer
var law_pow_lbl: Label

var law_headers: Array = []

var log_entries: Array = []

var log_filter := 0
var log_query := ""          # 0.57: поиск по тексту журнала
var log_big := false          # 0.57: только важное
var log_uid := 0              # 0.57: номер записи (для склейки повторов)

var log_filter_btns: Array = []

# ============================================================
#  ПОМОЩНИК И АВТОПИЛОТ
# ============================================================
var auto_floor_on := false
var bld_pick := ""               # v50: выбранное в окне «Строительство» сооружение (щелчок по карте ставит его)
var floor_keys := {}            # v50: авто-подъём отдельных статей расходов
var floor_check: CheckButton
var ap := {"bal": false, "target": 0.5, "events": false, "style": 0, "repair": false, "build": false}

var ap_log := {}

var ap_checks := {}

var ap_target_slider: HSlider

var ap_target_label: Label

var ap_style_opt: OptionButton

var ap_advisor_rt: RichTextLabel

var ap_btns: Array = []

var def0 := 3.0                # дефицит бюджета на старте, % ВВП (с него начинается опорный def_ref)

var loy_off: Array[float] = []

var unr_off: Array[float] = []

var region_parts: Array = []

# --- долговой тормоз ---
var fund_left := 500.0

var brake_over := 0

var dip := {}

var dip_sel := "FR"

var dip_layer := 0

var dip_hover := ""

var dip_ctl: Control

var dip_polys := {}

var dip_info_rt: RichTextLabel

var dip_table_rt: RichTextLabel

var dip_legend: Label

var dip_act_box: VBoxContainer
var dip_far_box: VBoxContainer
var dip_far_lbl: Label
var ex_sel := ""

var dip_act_btns := {}

var dip_track_btns := {}

var dip_track_lbls := {}

var dip_mod_rt: RichTextLabel

var dip_bonus0 := 1.0

var dip_last_summit := -10

var ea_infl := 2.1


# ============================================================
#  ЖИВОЙ МИР: страны, которыми управляет компьютер
# ============================================================

var wsim := {}

var w_shock := {}

var w_stress := 0.0

var w_crises_log: Array = []

var ea_rest := 2.0

var w_pot_player := 1.0

var scripted_done := {}

var regime_risk := 0.0

var regime_t := 0

var last_regime := ""

var shortage := 0.0

var plan_t := 0

var default_t := -999

var eu_left_t := -999

var last_uprising := -99

var rad_enacted := {}

var law_index_pre := {}

var res_price := 1.0

var agr_wx := 1.0

var re_rt: RichTextLabel

var re_tool_label: Label

var re_tool_opt: OptionButton

var re_tool_btn: Button

var re_tool_note: Label

# v36: административно-территориальные единицы (АТЕ). Статические данные — ATE (data/ate.dat), остальное считается в admin.gd
var ate_n := 0
var ate_c := PackedVector2Array()       # точка подписи АТЕ
var ate_rect: Array = []                # Rect2 АТЕ
var ate_km := PackedFloat32Array()
var ate_pw := PackedFloat32Array()      # доля АТЕ в населении исходного региона
var ate_gw := PackedFloat32Array()      # доля АТЕ в ВВП исходного региона
var ate_unit0 := PackedInt32Array()
var ate_unit := PackedInt32Array()      # АТЕ -> единица карты (WORLD_UNITS) — регион своей или чужой страны
var ate_lists: Array = []               # единица карты -> PackedInt32Array её АТЕ
var ate_cap := {}                       # код страны -> АТЕ со столицей
var ate_sea: Array = []                 # морские связи исходных единиц [ui, uj]
var ate_ver := 0                        # растёт при каждом изменении принадлежности АТЕ
var ate_sel: Array = []                 # АТЕ, выделенные на карте
var ate_mode := false                   # щелчок по карте выделяет АТЕ
var wu_n0 := 0
var wu_cc0: Array = []
var wu_nb0: Array = []
var wu_c0: Array = []
var adm_count := 0                      # число проведённых административных реформ
var adm_new_n := 0                      # счётчик новых регионов (для кодов)
