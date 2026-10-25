# Распределение всех законов по 11 областям: сначала явные id, затем ключевые слова в id и названии.
import re
ECO, SOC, ARMY, EDU, ECOL, LAW, MEDIA, MIG, REG, REL, ELEC = range(11)

EXPLICIT = {
    # экономика и налоги
    "econ_model": ECO, "fiscal_rule": ECO, "debt_default": ECO, "state_property": ECO, "trade_policy": ECO, "invest_code": ECO, "small_biz_law": ECO,
    "antimonopoly": ECO, "bankruptcy_law": ECO, "income_tax_law": ECO, "corp_tax_law": ECO, "vat_law": ECO, "carbon_tax": ECO, "property_rights": ECO,
    "central_bank": ECO, "export_duty": ECO, "tariff_cap": ECO, "agri_law": ECO, "regional_econ": ECO, "debt_brake": ECO, "rent_control": ECO, "housing": ECO,
    "lobbying_law": ELEC, "party_funding": ELEC,
    # социальная политика и труд
    "social_model": SOC, "min_wage": SOC, "pension_age": SOC, "paid_leave": SOC, "unemp_benefit": SOC, "labor_code": SOC, "family_policy": SOC,
    "healthcare": SOC, "copay": SOC,
    # армия и безопасность
    "military_state": ARMY, "mil_service": ARMY, "security_law": ARMY, "police_size": ARMY, "protest_rules": LAW,
    # образование и наука
    "education_law": EDU, "uni_places": EDU,
    # экология и энергетика
    "ecology_law": ECOL, "energy_policy": ECOL,
    # право, суды, полиция
    "judiciary": LAW, "civil_rights": LAW, "civil_service": LAW, "staff_size": LAW, "impeach_rule": LAW,
    # медиа и цифра
    "media_law": MEDIA, "digital_law": MEDIA,
    # миграция
    "migration": MIG, "citizenship_law": MIG, "schengen": MIG,
    # регионы и федерализм
    "state_structure": REG, "regional_policy": REG, "regional_gov": REG, "federal_balance": REG,
    # религия и культура
    "state_church": REL,
    # выборы и партии
    "gov_form": ELEC, "elect_threshold": ELEC, "parl_term_law": ELEC, "pres_term_law": ELEC, "referendum_law": ELEC, "seat_system": ELEC,
    "pres_vote_rule": ELEC, "censure_rule": ELEC, "eu_policy": ARMY,
}

KEYWORDS = [  # (область, регулярное выражение по id и названию в нижнем регистре)
    (ARMY, r"армия|армии|военн|призыв|оборон|нато|мобилиз|ядерн|оружи|разведк|безопасност|спецслужб|армейск|army|mil_|defen|war|nato|conscr|nuclear_wea|secur|intel|garrison|veteran|ветеран|казач"),
    (ELEC, r"выбор|избират|партий|партии|парламент|референдум|голосован|депутат|мандат|президент|coalition|elect|party|parl|vote|seat|ballot|мажорит|пропорц|список"),
    (MIG, r"миграц|мигрант|беженц|гражданств|убежищ|виз|границ|граница|иммигр|diaspor|диаспор|asyl|migr|citizen|border|visa|refugee"),
    (REG, r"регион|федерал|област|автоном|земл|кантон|муниципал|самоуправ|децентрал|община|сепарат|канто|region|federal|canton|munic|autonom|devol|municip|island|остров|территори|округ"),
    (REL, r"церк|религ|монаст|храм|конфесс|ислам|православ|католик|мечет|священ|культур|язык|языки|традиц|брак|аборт|эвтаназ|лгбт|семья|семей|празд|church|relig|lang|cultur|marri|abort|lgbt|famil|euthan|holiday|monast|orthodox"),
    (ECOL, r"эколог|климат|энерг|лес|вод|углерод|зелен|зелён|нефть|газ |газ$|газов|атом|мусор|отход|природ|заповед|ветр|солнеч|угол|шахт|добыч|ресурс|рыбо|охот|eco|clima|energy|forest|water|carbon|green|oil|gas|coal|nuclear|waste|mining|fish|hunt|solar|wind|hydro|river|lake|sea_|baltic"),
    (EDU, r"школ|образован|универс|наук|вуз|студент|учител|исследов|инновац|технолог|educ|school|univ|scien|research|innov|tech|student|teach|academ"),
    (MEDIA, r"медиа|сми|интернет|цифр|данн|связь|телеканал|телевиден|пропаганд|цензур|кибер|персональн|платформ|медиа|ии |искусствен|media|digital|internet|cyber|censor|press|broadcast|data|ai_|tv|propag|platform"),
    (LAW, r"суд|полици|закон|прав[оа]|кодекс|тюрьм|наказан|преступ|коррупц|юстиц|прокуратур|следств|адвокат|амнист|смерт|наркот|безопасн|порядок|law|court|judic|police|crime|prison|corrupt|justice|prosec|amnest|death|drug|order|jury|ombuds|rights"),
    (SOC, r"пенси|зарплат|труд|занятост|безработ|социальн|здравоохран|медицин|жиль[ёе]|аренд|профсоюз|забастов|бедност|семь|детск|ребёнк|ребенк|инвалид|рабоч|отпуск|welfare|pension|wage|labor|labour|health|social|union|strike|poverty|child|unemp|housing|rent|care|benefit|leave|work"),
    (ECO, r"налог|бюджет|долг|банк|торгов|тариф|инвестиц|промышленн|приватиз|субсиди|экономи|финанс|валют|евро|рынок|предприним|бизнес|монопол|корпорац|собственност|земля и|сельск|аграр|ферм|экспорт|импорт|санкц|энергетик|tax|budget|debt|bank|trade|tariff|invest|industr|privat|subsid|econom|financ|currency|euro|market|business|monop|corpor|propert|agri|farm|export|import|sanction|fiscal"),
]


def area_of(tid, name):
    if tid in EXPLICIT:
        return EXPLICIT[tid]
    s = (tid + " " + name).lower()
    for a, rx in KEYWORDS:
        if re.search(rx, s):
            return a
    return None

MANUAL = {
    ECO: "railways tourism highways pnrr_funds price_caps rail_transport tourism_policy ukraine_grain airport_lisbon alpine_tourism bnr_policy brain_drain broadband bridge_messina "
         "cpk_project coast_tourism corridor8 corridor_vc deregulation eu_mercosur eu_reform_agenda excise_policy expo2027 fehmarn_infra food_vat free_transport high_speed_rail highway "
         "hsr_tgv ina_mol infra_transport infrastructure_planning it_sector kap_aluminium klaipeda_port lithium_jadar maritime_domain metro_transport mezzogiorno_zes motorways "
         "orlen_refinery planning_reform port_koper ports_policy ports_transit ppp_concessions price_control rail_mobility railway8 railway_port rainy_day road_tolls schiphol_aviation "
         "shipyards state_enterprises sunday_trading superbonus tourism_model tourist_flats toll_roads transport_policy transport_vsr vat_food vat_policy vat_rates tourism_kopaonik "
         "brezovica_tourism trepca fund_charter fund_ethics velika_plaza demography gambling gambling_ads alcohol_policy ida_viru latgale_dev north_development sport_youth transit_brenner "
         "kaliningrad_transit state_admin",
    SOC: "housebuilding parasitism heating_renovation",
    ARMY: "ukraine_aid ukraine_support ukraine_russia albania_relations balkans_open china_relations china_taiwan cyprus_policy dialogue_serbia eaeu_csto gibraltar_falklands gibraltar_treaty "
          "kosovo_policy kosovo_relations macedonia_veto military_alliance north_macedonia pivot_east prespa_deal russia_relations russian_troops serbia_relations shadow_fleet svalbard "
          "us_dialogue us_relations v4_policy chagos_deal northern_route ohr_bonn transnistria unification szch_desertion piran_bay srpski_svet hungarians_abroad",
    ECOL: "air_pollution air_quality ets2_smog ev_policy jek2 kozloduy lignite_exit paks2 power_grid power_price wildfires_civil bears_wolves sinjajevina urban_policy",
    LAW: "billion_theft canopy_case conflict_interest istanbul",
    MEDIA: "bbc_charter rte_licence yle_funding",
    REL: "roma_inclusion roma_communities roma_minorities blood_feud historical_memory history_memory communist_past memory_politics missing_persons prayer_day soviet_legacy "
         "soviet_monuments srebrenica_memory thrace_minority assisted_dying end_of_life civil_partnership albanian_pm",
    REG: "local_admin rural_depopulation brussels_reform ten_million",
    ELEC: "senate_reform seanad_reform lords_reform constitution_new constitution_values constitution eu_constitution sejdic_finci sixth_republic grand_duke_role",
}
for _a, _s in MANUAL.items():
    for _i in _s.split():
        EXPLICIT.setdefault(_i, _a)

AREA_NAMES = ["Экономика и налоги", "Социальная политика и труд", "Армия, безопасность и внешняя политика", "Образование и наука", "Экология и энергетика",
              "Право, суды и полиция", "Медиа и цифровая среда", "Миграция и гражданство", "Регионы и федерализм", "Религия и культура", "Выборы и партии"]

for _i, _a in (("ngo_funding", LAW), ("post_brexit", ARMY), ("coe_membership", ARMY), ("albania_ties", ARMY), ("aid_budget", ARMY),
               ("agri_methane", ECOL), ("agri_nitrogen", ECOL), ("flanders_nitrogen", ECOL), ("eurogauge", ECO)):
    EXPLICIT[_i] = _a
