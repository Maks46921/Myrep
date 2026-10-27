#!/usr/bin/env python3
"""0.65: данные политических движений 38 стран.

  python3 tools/gen_move65.py        # пишет scripts/data/data_move65.gd и i18n/en/65_move.json

Для каждой страны: шесть типовых движений (профсоюзное, климатическое, студенческое, гражданское против коррупции,
национал-радикальное, фермерское) и особые — реальные движения этой страны. Числа здесь — только стартовые: дальше
поддержка движения следует за недовольством в стране (см. scripts/logic/move65.gd).
"""
import hashlib, json, os

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))


def sid(s):
    return hashlib.sha1(s.encode("utf-8")).hexdigest()[:12]


# --- типы: tp -> (русское имя, английское имя, описание ru, описание en, B — типичная поддержка %, организованность, радикальность) ---
TYP = {
    "lab": ("Профсоюзное движение", "Trade-union movement",
            "Профсоюзы, стачкомы и рабочие инициативы: забастовки и митинги за зарплаты, пенсии и условия труда. Сильно там, где много рабочих и бюджетников.",
            "Trade unions, strike committees and workers' initiatives: strikes and rallies over pay, pensions and working conditions. Strong where there are many workers and public employees.",
            6.0, 45, 15),
    "clim": ("Климатическое движение", "Climate movement",
             "Молодые активисты и экологи: марши, блокады дорог, акции у зданий власти. Требуют быстрого отказа от угля и нефти.",
             "Young activists and environmentalists: marches, road blockades, actions outside government buildings. They demand a fast exit from coal and oil.",
             3.5, 35, 28),
    "stud": ("Студенческое движение", "Student movement",
             "Студенческие советы и инициативные группы: протесты против платы за обучение, за свободы и против произвола. Растёт быстро и так же быстро выдыхается.",
             "Student councils and initiative groups: protests against tuition fees and for freedoms and against arbitrary rule. It grows fast and burns out just as fast.",
             3.0, 30, 20),
    "civ": ("Гражданское движение против коррупции", "Civic anti-corruption movement",
            "Журналисты, юристы и волонтёры: расследования, петиции и акции против коррупции. Мирное, но настойчивое.",
            "Journalists, lawyers and volunteers: investigations, petitions and actions against corruption. Peaceful but persistent.",
            4.5, 25, 12),
    "nat": ("Национал-радикальное движение", "National-radical movement",
            "Радикальные националисты и «стражи традиций»: шествия, уличное давление и угрозы оппонентам. Опирается на недовольных миграцией и «элитами».",
            "Radical nationalists and “guardians of tradition”: marches, street pressure and threats to opponents. It draws on those angry about migration and “the elites”.",
            3.0, 30, 58),
    "farm": ("Фермерское движение", "Farmers' movement",
             "Фермеры и сельские сообщества: блокады дорог тракторами и протесты против цен, квот и экологических правил.",
             "Farmers and rural communities: tractor blockades and protests against prices, quotas and environmental rules.",
             2.5, 45, 25),
}

# --- особые движения: cc -> [(id, tp, ru, en, desc_ru, desc_en, B, org, rad, flags)] flags: "pro" — за власть, "reg" — региональное ---
SPEC = {
    "RU": [
        ("ru_nonsys", "civ", "Несистемная оппозиция", "Non-systemic opposition",
         "Независимые политики, их штабы и сторонники. Не допущены к выборам и не имеют партии; живут на митингах, в сетях и на пожертвованиях. Сейчас это движение, а не партия.",
         "Independent politicians, their campaign offices and supporters. Barred from elections and without a party, it lives on rallies, social networks and donations. Today a movement, not a party.",
         9.0, 20, 18, ""),
        ("ru_antiwar", "peace", "Антивоенное движение", "Anti-war movement",
         "Родственники мобилизованных, волонтёры и активисты: одиночные пикеты, письма и помощь уехавшим. Каждый акт здесь рискован.",
         "Relatives of conscripts, volunteers and activists: single-person pickets, letters and help for those who left. Every act is risky here.",
         6.0, 15, 10, ""),
        ("ru_voenkor", "nat", "Патриотические военкоры", "Patriotic war correspondents",
         "Блогеры и добровольцы, поддерживающие войну и требующие вести её жёстче. Власти они удобны, пока критикуют генералов, а не Кремль.",
         "Bloggers and volunteers who back the war and demand that it be fought harder. Useful to the authorities as long as they criticise generals, not the Kremlin.",
         5.0, 35, 45, "pro"),
    ],
    "BY": [
        ("by_democ", "civ", "Демократическое движение", "Democratic movement",
         "Штабы оппозиции, сети соседей и «Чат-революция» 2020 года. Большинство лидеров в тюрьме или за границей, но сети живут.",
         "Opposition campaign teams, neighbourhood networks and the 2020 “chat revolution”. Most leaders are in prison or abroad, but the networks live on.",
         10.0, 15, 12, ""),
        ("by_strike", "lab", "Забастовочные комитеты заводов", "Factory strike committees",
         "Рабочие крупных заводов, которые в 2020 году вышли на забастовку. Сейчас под наблюдением, но остаются главным страхом власти.",
         "Workers of the big factories who struck in 2020. Now under watch, yet still the authorities' main fear.",
         4.0, 25, 12, ""),
        ("by_partisan", "nat", "Железнодорожные партизаны", "Railway partisans",
         "Небольшие группы, которые саботируют переброску войск на железной дороге. Малочисленны, но опасны для власти.",
         "Small groups sabotaging troop movements on the railways. Few in number but dangerous for the authorities.",
         0.8, 40, 80, ""),
    ],
    "UA": [
        ("ua_volunt", "civ", "Волонтёрское движение", "Volunteer movement",
         "Сети, которые собирают деньги и технику для армии и помогают переселенцам. Пользуются огромным доверием и умеют спрашивать с власти.",
         "Networks that raise money and equipment for the army and help displaced people. They enjoy huge trust and know how to hold the authorities to account.",
         9.0, 55, 6, ""),
        ("ua_antikor", "civ", "Антикоррупционные активисты", "Anti-corruption activists",
         "Журналисты-расследователи и общественные советы. В 2025 году выводили людей на улицы из-за атаки на антикоррупционные органы.",
         "Investigative journalists and public councils. In 2025 they brought people onto the streets over the attack on anti-corruption bodies.",
         4.0, 45, 10, ""),
        ("ua_nat", "nat", "Радикальные националисты", "Radical nationalists",
         "Ветеранские добровольческие объединения и ультраправые. Сильны на фронте и в тылу, жёстко возражают против любых уступок.",
         "Veteran volunteer associations and the far right. Strong at the front and in the rear, they firmly oppose any concessions.",
         3.0, 40, 55, ""),
    ],
    "MD": [
        ("md_shor", "nat", "Сеть Шора", "The Shor network",
         "Сеть связанных с Шором организаций: поддержка деньгами, оплаченные митинги и вещание на русском. Партии запрещены, сеть меняет вывески.",
         "A network of Shor-linked organisations: money, paid rallies and Russian-language broadcasting. The parties were banned; the network changes its signs.",
         6.0, 55, 40, ""),
        ("md_dp", "civ", "Платформа «Достоинство и правда»", "“Dignity and Truth” platform",
         "Гражданское движение 2015–2016 годов, давшее многим политикам старт. Требует расследований и честных выборов.",
         "The civic movement of 2015–2016 that launched many politicians. It demands investigations and honest elections.",
         3.5, 25, 12, ""),
        ("md_union", "nat", "Унионистское движение", "Unionist movement",
         "Сторонники объединения с Румынией. Заметно в Кишинёве, слабо на юге и в Гагаузии.",
         "Supporters of union with Romania. Visible in Chisinau, weak in the south and in Gagauzia.",
         2.5, 25, 20, ""),
    ],
    "RS": [
        ("rs_stud", "stud", "Студенческое движение", "Student movement",
         "Студенческие пленумы после обрушения навеса в Нови-Саде (2024). Организованы горизонтально, без вождей; привлекли родителей, преподавателей и фермеров.",
         "Student plenums after the Novi Sad canopy collapse (2024). Organised horizontally, without leaders; they drew in parents, teachers and farmers.",
         14.0, 45, 10, ""),
        ("rs_lith", "clim", "Протесты против литиевого проекта", "Anti-lithium-mine protests",
         "Экологи и жители долины Ядар: блокады дорог и митинги против проекта Рио Тинто.",
         "Ecologists and residents of the Jadar valley: road blockades and rallies against the Rio Tinto project.",
         4.5, 40, 22, ""),
        ("rs_nat", "nat", "Радикальные националисты", "Radical nationalists",
         "Ультраправые и околофутбольные группы. Выступают против компромиссов по Косову и против Запада.",
         "Ultra-right and football-hooligan groups. They oppose compromises on Kosovo and oppose the West.",
         3.0, 35, 62, ""),
    ],
    "FR": [
        ("fr_gilets", "soc", "Жёлтые жилеты", "Yellow vests",
         "Самоорганизованное движение 2018 года против налогов на топливо и неравенства. Без лидеров и без партии, поэтому трудно договориться, но и трудно разгромить.",
         "The self-organised movement of 2018 against fuel taxes and inequality. No leaders and no party: hard to negotiate with, but also hard to crush.",
         8.0, 30, 35, ""),
        ("fr_greve", "lab", "Интерсиндикальные забастовки", "Intersyndical strikes",
         "Профсоюзный фронт против пенсионных реформ: многомесячные забастовки на транспорте и в энергетике.",
         "The trade-union front against pension reform: months-long strikes in transport and energy.",
         9.0, 65, 20, ""),
        ("fr_soul", "clim", "«Восстания земли»", "“Soulèvements de la Terre”",
         "Радикальные экологи: акции против водохранилищ и карьеров. Власть называет их экотеррористами.",
         "Radical ecologists: actions against reservoirs and quarries. The authorities call them eco-terrorists.",
         1.5, 45, 62, ""),
    ],
    "DE": [
        ("de_lg", "clim", "«Последнее поколение»", "“Last Generation”",
         "Климатические активисты, приклеивающиеся к дорогам. Заметны в СМИ, непопулярны в обществе; против них возбуждают дела.",
         "Climate activists who glue themselves to roads. Highly visible in the media, unpopular with the public; criminal cases are brought against them.",
         1.5, 40, 48, ""),
        ("de_pegida", "nat", "Пегида и радикальные правые", "Pegida and the radical right",
         "Шествия против миграции и ислама, особенно в Саксонии. Часть группировок находится под наблюдением ведомства по защите конституции.",
         "Marches against migration and Islam, especially in Saxony. Some groups are under surveillance by the domestic intelligence service.",
         3.5, 35, 62, ""),
        ("de_gegen", "civ", "Движение «против правых»", "“Against the right” movement",
         "Массовые демонстрации 2024 года против идей «ремиграции»: миллионы людей, церкви, профсоюзы, клубы.",
         "The mass demonstrations of 2024 against “remigration” ideas: millions of people, churches, unions, clubs.",
         6.0, 40, 6, ""),
        ("de_bauern", "farm", "Протесты фермеров", "Farmers' protests",
         "Тракторные колонны зимы 2024 года против отмены льгот на дизельное топливо.",
         "The tractor convoys of winter 2024 against the removal of diesel subsidies.",
         3.5, 55, 25, ""),
    ],
    "GB": [
        ("gb_xr", "clim", "Extinction Rebellion и Just Stop Oil", "Extinction Rebellion and Just Stop Oil",
         "Климатические активисты: блокады, краска на витринах, акции в музеях. Новый закон об общественном порядке сильно ограничил их.",
         "Climate activists: blockades, paint on shopfronts, museum actions. The new public-order law has restricted them heavily.",
         1.8, 45, 45, ""),
        ("gb_scot", "reg", "Шотландское движение за независимость", "Scottish independence movement",
         "Массовое, мирное и очень организованное. Требует нового референдума.",
         "Mass, peaceful and highly organised. It demands a new referendum.",
         12.0, 60, 6, "reg"),
        ("gb_doctors", "lab", "Забастовки врачей и учителей", "Doctors' and teachers' strikes",
         "Многодневные забастовки в здравоохранении и образовании из-за зарплат.",
         "Multi-day strikes in health and education over pay.",
         5.0, 55, 12, ""),
    ],
    "ES": [
        ("es_15m", "civ", "Движение 15-М (индигнадос)", "15-M movement (indignados)",
         "Площади Мадрида 2011 года: массовые палаточные лагеря против сокращений и политической «касты». Из него вышли новые партии.",
         "The Madrid squares of 2011: mass tent camps against austerity and the political “caste”. New parties grew out of it.",
         7.0, 30, 8, ""),
        ("es_cat", "reg", "Каталонское движение за независимость", "Catalan independence movement",
         "Сильные гражданские организации, ежегодные многотысячные демонстрации. С 2017 года часть лидеров в изгнании.",
         "Strong civic organisations and annual demonstrations of hundreds of thousands. Since 2017 part of the leadership has been in exile.",
         14.0, 65, 12, "reg"),
    ],
    "IT": [
        ("it_sardine", "civ", "«Сардины»", "“Sardines”",
         "Площадные собрания 2019 года против агрессивной политики Салвини: «мы тесно, как сардины, но мы здесь».",
         "The square gatherings of 2019 against Salvini's aggressive politics: “packed like sardines, but here”.",
         4.0, 25, 4, ""),
        ("it_forconi", "farm", "«Вилы» (Forconi)", "“Pitchforks” (Forconi)",
         "Фермеры, перевозчики и торговцы: блокады дорог против налогов и цен.",
         "Farmers, hauliers and traders: road blockades against taxes and prices.",
         2.5, 35, 38, ""),
    ],
    "GR": [
        ("gr_tempi", "civ", "Движение «Темпи 2023»", "“Tempi 2023” movement",
         "Родственники погибших при железнодорожной катастрофе и сочувствующие: массовые демонстрации за правду и ответственность.",
         "Relatives of those killed in the rail disaster and sympathisers: mass demonstrations for truth and accountability.",
         8.0, 40, 8, ""),
        ("gr_anarch", "clim", "Анархисты Экзархии", "Exarchia anarchists",
         "Радикальные левые и анархисты Афин: уличные столкновения и поджоги.",
         "Radical left and Athens anarchists: street clashes and arson.",
         1.2, 40, 70, ""),
    ],
    "PT": [
        ("pt_prof", "lab", "Учительские забастовки", "Teachers' strikes",
         "Многолетняя борьба учителей за стаж и зарплаты, поддержанная другими работниками бюджетной сферы.",
         "A years-long teachers' struggle over seniority and pay, backed by other public-sector workers.",
         4.0, 55, 8, ""),
    ],
    "IE": [
        ("ie_water", "civ", "Движение «Право на воду»", "“Right2Water” movement",
         "Массовые марши против платы за воду (2014–2016) и против коммерциализации услуг.",
         "Mass marches against water charges (2014–2016) and against commercialising public services.",
         4.5, 40, 8, ""),
        ("ie_anti", "nat", "Антииммиграционное движение", "Anti-immigration movement",
         "Уличные группы против размещения беженцев; после беспорядков в Дублине 2023 года попали под пристальное наблюдение.",
         "Street groups against housing refugees; after the 2023 Dublin riots they are under close watch.",
         2.5, 25, 55, ""),
    ],
    "NL": [
        ("nl_bbb", "farm", "Фермерский протест против азотных норм", "Farmers' protest against nitrogen rules",
         "Тракторы на дорогах и у домов министров: борьба против сокращения поголовья и выбросов азота.",
         "Tractors on the roads and outside ministers' homes: a fight against herd cuts and nitrogen limits.",
         4.5, 55, 22, ""),
        ("nl_xr", "clim", "Extinction Rebellion Нидерландов", "Extinction Rebellion Netherlands",
         "Регулярные блокады автострады A12; тысячи задержаний.",
         "Regular blockades of the A12 motorway; thousands of detentions.",
         2.0, 50, 35, ""),
    ],
    "BE": [
        ("be_vl", "reg", "Фламандское движение", "Flemish movement",
         "Культурные и общественные организации Фландрии, поддерживающие автономию и независимость.",
         "Flanders' cultural and civic organisations backing autonomy and independence.",
         9.0, 50, 10, "reg"),
        ("be_strike", "lab", "Национальные забастовки против реформ", "National strikes against reforms",
         "Общенациональные забастовки против пенсионной и трудовой реформ; парализуют транспорт.",
         "Nationwide strikes against pension and labour reforms; they paralyse transport.",
         8.0, 65, 15, ""),
    ],
    "AT": [
        ("at_covid", "civ", "Движение против ковидных мер", "Anti-Covid-measures movement",
         "Многотысячные демонстрации в Вене против обязательной вакцинации и ограничений. Включает и радикальные группы.",
         "Demonstrations of tens of thousands in Vienna against mandatory vaccination and restrictions. Includes radical groups too.",
         3.0, 25, 40, ""),
    ],
    "CH": [
        ("ch_senior", "clim", "«Климатические пенсионерки»", "“Senior Women for Climate”",
         "Пенсионерки, выигравшие в Страсбурге дело о климате против Швейцарии.",
         "Senior women who won the climate case against Switzerland in Strasbourg.",
         1.5, 55, 6, ""),
    ],
    "CZ": [
        ("cz_mil", "civ", "«Миллион моментов за демократию»", "“Million Moments for Democracy”",
         "Гражданская инициатива, собравшая сотни тысяч человек на площади Праги в 2018–2021 годах.",
         "A civic initiative that gathered hundreds of thousands on Prague's squares in 2018–2021.",
         6.0, 40, 4, ""),
        ("cz_energo", "nat", "Протесты против цен на энергию", "Energy-price protests",
         "Митинги на Вацлавской площади на фоне роста цен; к ним присоединились и радикалы.",
         "Rallies on Wenceslas Square amid rising prices; radicals joined them too.",
         3.5, 30, 45, ""),
    ],
    "SK": [
        ("sk_kuciak", "civ", "«Достойная Словакия»", "“For a Decent Slovakia”",
         "Волна 2018 года после убийства журналиста Яна Куцака: самые массовые демонстрации со времён 1989 года.",
         "The 2018 wave after the murder of journalist Ján Kuciak: the largest demonstrations since 1989.",
         7.0, 40, 5, ""),
        ("sk_mir", "nat", "Движение за нейтралитет и «мир»", "Neutrality and “peace” movement",
         "Митинги против помощи Украине и за выход из НАТО; близки к пророссийским группам.",
         "Rallies against aid to Ukraine and for leaving NATO; close to pro-Russian groups.",
         3.0, 30, 35, ""),
    ],
    "HU": [
        ("hu_student", "stud", "Студенческая сеть", "Student network",
         "Студенты и преподаватели университетов, выступающие против передачи вузов фондам. Блокады, акции у парламента.",
         "Students and academics protesting the handover of universities to foundations. Blockades, actions at parliament.",
         4.0, 40, 12, ""),
        ("hu_teach", "lab", "Учительские протесты", "Teachers' protests",
         "Гражданское неповиновение учителей против низких зарплат и ограничения права на забастовку.",
         "Civil disobedience by teachers against low pay and curbs on the right to strike.",
         4.5, 45, 10, ""),
    ],
    "PL": [
        ("pl_women", "civ", "Всепольская забастовка женщин", "All-Poland Women's Strike",
         "Массовые протесты 2020 года против запрета абортов. Крупнейшие демонстрации со времён «Солидарности».",
         "The mass protests of 2020 against the abortion ban. The largest demonstrations since Solidarity.",
         9.0, 45, 10, ""),
        ("pl_rolnicy", "farm", "Блокады границы фермерами", "Farmers' border blockades",
         "Фермеры перекрывают границу с Украиной и дороги против украинского зерна и правил ЕС.",
         "Farmers blocking the border with Ukraine and roads against Ukrainian grain and EU rules.",
         4.0, 60, 25, ""),
        ("pl_marsz", "nat", "Марш независимости", "Independence March",
         "Ежегодное шествие 11 ноября, в котором участвуют националисты и радикалы.",
         "The annual march on 11 November, joined by nationalists and radicals.",
         3.0, 40, 50, ""),
    ],
    "RO": [
        ("ro_rosia", "civ", "Протесты «Рошия-Монтана» и #Rezist", "“Roșia Montană” and #Rezist protests",
         "Движения против золотого рудника и против отмены антикоррупционных законов: массовые митинги 2012–2019.",
         "Movements against the gold mine and against rolling back anti-corruption laws: mass rallies 2012–2019.",
         5.0, 35, 6, ""),
        ("ro_diaspora", "civ", "Диаспора", "Diaspora network",
         "Сети румын за границей: онлайн-кампании, помощь родным и акции у посольств.",
         "Romanians abroad: online campaigns, help for relatives and actions outside embassies.",
         3.5, 30, 6, ""),
    ],
    "BG": [
        ("bg_yad", "civ", "Протесты 2020 года («Яд»)", "2020 protests (“Poison”)",
         "Многомесячные протесты против коррупции и олигархических связей. Объединили либералов, националистов и молодёжь.",
         "Months-long protests against corruption and oligarchic ties. They united liberals, nationalists and the young.",
         6.0, 30, 12, ""),
    ],
    "HR": [
        ("hr_edu", "lab", "Профсоюзы образования", "Education unions",
         "Многолетние забастовки учителей и протесты против реформы зарплат бюджетников.",
         "Years of teachers' strikes and protests against the public-sector pay reform.",
         4.0, 50, 8, ""),
    ],
    "SI": [
        ("si_bike", "civ", "«Пятничные велопротесты»", "“Friday bicycle protests”",
         "Протесты 2020–2021 годов на велосипедах против правительства Янши: тысячи людей каждую пятницу.",
         "The bicycle protests of 2020–2021 against the Janša government: thousands of people every Friday.",
         5.0, 35, 4, ""),
    ],
    "LT": [
        ("lt_family", "nat", "Движение «Семейные марши»", "“Family marches” movement",
         "Консервативные организации и церковные сети: акции против «гендерной идеологии» и за традиционную семью.",
         "Conservative organisations and church networks: actions against “gender ideology” and for the traditional family.",
         4.0, 40, 30, ""),
    ],
    "LV": [
        ("lv_rus", "reg", "Русскоязычные организации", "Russian-speaking organisations",
         "Общественные организации, выступающие против языковых и гражданских ограничений. Часть находится под наблюдением.",
         "Civic organisations protesting language and citizenship limits. Some are under surveillance.",
         6.0, 35, 15, ""),
    ],
    "EE": [
        ("ee_blue", "nat", "«Синее пробуждение»", "“Blue Awakening”",
         "Молодые консерваторы и националисты: факельные шествия и уличная агитация.",
         "Young conservatives and nationalists: torch marches and street campaigning.",
         2.5, 35, 40, ""),
    ],
    "FI": [
        ("fi_elokapina", "clim", "Elokapina (Extinction Rebellion Финляндии)", "Elokapina (Extinction Rebellion Finland)",
         "Климатические блокады в Хельсинки; запрещённые акции приводят к массовым задержаниям.",
         "Climate blockades in Helsinki; banned actions lead to mass detentions.",
         1.8, 45, 35, ""),
    ],
    "SE": [
        ("se_fff", "clim", "Fridays for Future (Швеция)", "Fridays for Future (Sweden)",
         "Школьные забастовки, начатые Гретой Тунберг. Лучше организованы, чем кажется.",
         "School strikes started by Greta Thunberg. Better organised than they appear.",
         3.5, 45, 10, ""),
    ],
    "DK": [
        ("dk_holiday", "lab", "Протесты против отмены праздника", "Protests against abolishing a public holiday",
         "Профсоюзы, церкви и граждане против отмены Великой молитвенной пятницы ради оборонных расходов.",
         "Unions, churches and citizens against abolishing Great Prayer Day to fund defence.",
         5.0, 50, 5, ""),
    ],
    "NO": [
        ("no_fosen", "clim", "Протест саамов против ветропарков", "Sámi protest against wind farms",
         "Саамские оленеводы и экологи: блокады министерств и акции гражданского неповиновения.",
         "Sámi reindeer herders and environmentalists: ministry blockades and civil-disobedience actions.",
         2.0, 50, 18, ""),
    ],
    "AL": [
        ("al_theatre", "civ", "Протест против сноса театра", "Theatre-demolition protests",
         "Защита Национального театра: самоорганизованные акции граждан против застройки в центре Тираны.",
         "Defending the National Theatre: self-organised citizens' actions against development in central Tirana.",
         3.0, 25, 10, ""),
    ],
    "BA": [
        ("ba_plen", "civ", "Пленумы граждан", "Citizens' plenums",
         "Пленумы 2014 года: горизонтальные собрания граждан против коррупции и этнического раздела.",
         "The 2014 plenums: horizontal citizens' assemblies against corruption and ethnic division.",
         3.5, 25, 8, ""),
        ("ba_rs", "reg", "Движение за самостоятельность Республики Сербской", "Republika Srpska self-rule movement",
         "Организации, добивающиеся отделения Республики Сербской и выхода из общих институтов.",
         "Organisations pressing for the secession of Republika Srpska and withdrawal from common institutions.",
         7.0, 45, 25, "reg"),
    ],
    "ME": [
        ("me_lit", "nat", "Литийное (церковное) движение", "Litije (church) movement",
         "Крестные ходы 2019–2020 годов против закона о религиозных общинах; свергли прежнюю власть.",
         "The processions of 2019–2020 against the law on religious communities; they brought down the former government.",
         10.0, 55, 12, ""),
    ],
    "MK": [
        ("mk_colour", "civ", "«Цветная революция»", "“Colourful Revolution”",
         "Протесты 2016 года против амнистии чиновников: краска на зданиях власти и массовые марши.",
         "The 2016 protests against the amnesty for officials: paint on government buildings and mass marches.",
         5.0, 30, 15, ""),
        ("mk_nat", "nat", "Движение против изменения названия", "Anti-renaming movement",
         "Националисты и церковные круги, возражающие против уступок соседям в вопросах имени и языка.",
         "Nationalists and church circles objecting to concessions to neighbours on name and language.",
         3.5, 30, 40, ""),
    ],
    "XK": [
        ("xk_nat", "nat", "Национал-радикалы", "National radicals",
         "Радикальные организации, требующие объединения с Албанией и жёсткой линии по северу. Уличное давление и угрозы.",
         "Radical organisations demanding union with Albania and a hard line on the north. Street pressure and threats.",
         4.0, 40, 60, ""),
        ("xk_north", "reg", "Сербские организации севера", "Serb organisations of the north",
         "Баррикады и бойкоты на севере страны против центральной власти.",
         "Barricades and boycotts in the north against the central authorities.",
         4.5, 55, 40, "reg"),
    ],
    "LU": [],
}

# типы, которые есть не везде
TYP2 = {
    "peace": ("Движение за мир", "Peace movement",
              "Пацифисты, церкви и левые: митинги против войны и поставок оружия.",
              "Pacifists, churches and the left: rallies against war and arms deliveries.", 3.0, 30, 10),
    "soc": ("Движение за социальную справедливость", "Social-justice movement",
            "Низкооплачиваемые, пенсионеры и безработные: протесты против цен и налогов.",
            "Low earners, pensioners and the unemployed: protests against prices and taxes.", 5.0, 25, 25),
    "reg": ("Региональное движение", "Regional movement",
            "Организации, требующие автономии региона.", "Organisations demanding regional autonomy.", 5.0, 40, 15),
}

# 0.66: малые страны и Кипр
SPEC.update({
    "LI": [
        ("li_prince", "nat", "Круг сторонников князя", "Circle of the Prince's supporters",
         "Консервативные организации и семьи, считающие, что князь должен сохранить вето и власть над судьями. Мирные, но влиятельные.",
         "Conservative groups and families who hold that the Prince must keep his veto and his say over judges. Peaceful but influential.",
         4.0, 45, 8, ""),
        ("li_veto", "civ", "Инициатива «Ограничить вето князя»", "“Limit the Prince's veto” initiative",
         "Граждане, собирающие подписи за референдумы, где последнее слово остаётся за народом. В 2012 году такой референдум проиграл с большим отрывом.",
         "Citizens collecting signatures for referendums where the people have the last word. A 2012 referendum of this kind lost by a wide margin.",
         3.5, 30, 10, ""),
    ],
    "MT": [
        ("mt_repub", "civ", "Движение «Республика» (Repubblika)", "The Repubblika movement",
         "Юристы и журналисты после убийства Дафны Каруаны Галиции: расследования, суды и митинги против коррупции и безнаказанности.",
         "Lawyers and journalists since the murder of Daphne Caruana Galizia: investigations, lawsuits and rallies against corruption and impunity.",
         5.0, 40, 12, ""),
        ("mt_hunt", "farm", "Охотничье и птицеловное лобби", "Hunting and trapping lobby",
         "Охотники и ловцы птиц: давят на партии из-за сезонов и квот, дважды вынесли вопрос на референдум.",
         "Hunters and bird trappers: they press the parties over seasons and quotas and twice forced a referendum.",
         3.0, 55, 15, ""),
        ("mt_patr", "nat", "Движение «Мальтийские патриоты»", "Maltese Patriots movement",
         "Радикальные противники миграции из Африки и «продажи гражданства»: шествия и акции у лагерей мигрантов.",
         "Radical opponents of migration from Africa and of selling citizenship: marches and actions outside migrant centres.",
         2.0, 25, 50, ""),
    ],
    "AD": [
        ("ad_eu", "civ", "Движение за ассоциацию с ЕС", "Movement for EU association",
         "Предприниматели, молодёжь и часть парламента: требуют скорее подписать соглашение, чтобы жить и работать по всей Европе.",
         "Business people, young voters and part of parliament who want the agreement signed soon so they can live and work across Europe.",
         4.5, 35, 8, ""),
        ("ad_rent", "civ", "Жилищное движение", "Housing movement",
         "Работники и семьи, которых вытесняет дорогая аренда; собирают подписи за потолок цен и социальное жильё.",
         "Workers and families priced out by high rents; they gather signatures for a rent cap and social housing.",
         4.0, 30, 12, ""),
    ],
    "SM": [
        ("sm_women", "civ", "Союз сан-маринских женщин", "Union of Sammarinese Women",
         "Женские организации, добившиеся референдума 2021 года о легализации абортов; теперь следят за исполнением закона.",
         "Women's organisations that won the 2021 referendum on legalising abortion; they now watch that the law is carried out.",
         4.0, 40, 10, ""),
        ("sm_eu", "civ", "Движение за ассоциацию с ЕС", "Movement for EU association",
         "Сторонники соглашения с ЕС: в 2013 году референдум не набрал явку, но тема не уходит.",
         "Backers of the EU agreement: the 2013 referendum missed the turnout threshold, but the topic does not go away.",
         5.0, 35, 8, ""),
    ],
    "MC": [
        ("mc_sea", "clim", "Против застройки моря", "Against sea-reclamation building",
         "Жители и экологи, возражающие против новых намывных кварталов: петиции, лодочные акции и иски.",
         "Residents and environmentalists who object to new land-reclamation districts: petitions, boat actions and lawsuits.",
         2.5, 30, 12, ""),
        ("mc_nat", "nat", "Союз коренных монегасков", "Union of native Monegasques",
         "Гражданство даёт круг около 9 тысяч человек: они защищают приоритет коренных жителей в работе и жилье.",
         "Citizenship covers a circle of about 9,000 people who defend priority for natives in jobs and housing.",
         3.0, 50, 10, ""),
    ],
    "PM": [
        ("pm_rus", "nat", "Движение за вхождение в Россию", "Movement to join Russia",
         "Сторонники итогов референдума 2006 года: митинги у Верховного совета и письма в Москву. Опираются на русские части и школы.",
         "Supporters of the 2006 referendum result: rallies by the Supreme Council and letters to Moscow. They rely on Russian schools and units.",
         14.0, 55, 20, ""),
        ("pm_reunif", "civ", "Движение за воссоединение с Молдовой", "Movement for reunification with Moldova",
         "Предприниматели и молодёжь, живущие торговлей через Днестр и ЕС: требуют открытых границ и договорённости с Кишинёвом.",
         "Business people and young people who live by trade across the Dniester and the EU: they want open borders and a deal with Chisinau.",
         9.0, 25, 10, ""),
        ("pm_steel", "lab", "Рабочие Рыбницкого меткомбината", "Rybnitsa steelworkers",
         "Металлурги и энергетики, которых бьют перебои с газом и остановки заводов: стачки и требования к правительству.",
         "Metalworkers and power-plant staff hit by gas shortages and plant stoppages: strikes and demands to the government.",
         6.0, 45, 18, ""),
    ],
    "CY": [
        ("cy_reunif", "peace", "Движение за воссоединение острова", "Movement for reunification of the island",
         "Двухобщинные группы, молодёжь и бизнес: встречи через зелёную линию, давление на переговоры под эгидой ООН.",
         "Bicommunal groups, young people and business: meetings across the green line, pressure for UN-led talks.",
         6.0, 35, 8, ""),
        ("cy_enosis", "nat", "Националисты (Энозис)", "Nationalists (Enosis)",
         "Радикалы, отвергающие федерацию и требующие жёсткой линии к Турции. Заметны в футбольных клубах и среди ветеранов.",
         "Radicals who reject a federation and demand a hard line toward Turkey. Visible in football clubs and among veterans.",
         4.0, 40, 40, ""),
        ("cy_church", "civ", "Церковь и верующие", "The Church and believers",
         "Архиепископия — крупнейший землевладелец и общественная сила; влияет на мнение о воссоединении и школьных программах.",
         "The Archbishopric is the largest landowner and a public force; it shapes opinion on reunification and school curricula.",
         5.0, 55, 8, ""),
    ],
})

COUNTRIES = ["AL", "AT", "BA", "BE", "BG", "BY", "CH", "CZ", "DE", "DK", "EE", "ES", "FI", "FR", "GB", "GR", "HR", "HU", "IE", "IT",
             "LT", "LU", "LV", "MD", "ME", "MK", "NL", "NO", "PL", "PT", "RO", "RS", "RU", "SE", "SI", "SK", "UA", "XK",
             "LI", "MT", "AD", "SM", "MC", "PM", "CY"]
# типовые движения по странам (без LU: нет фермеров)
NO_FARM = {"LU", "MC", "SM", "LI", "PM"}
# сила типовых движений в стране: множитель и поправка — реальные особенности
FACT = {
    "RU": {"lab": 0.5, "clim": 0.2, "stud": 0.5, "civ": 0.6, "nat": 1.0, "farm": 0.6},
    "BY": {"lab": 0.6, "clim": 0.2, "stud": 0.6, "civ": 0.7, "nat": 0.5, "farm": 0.6},
    "FR": {"lab": 1.4, "farm": 1.4, "nat": 1.2}, "IT": {"lab": 1.1}, "GR": {"lab": 1.2},
    "DE": {"clim": 1.3, "lab": 0.8}, "NL": {"clim": 1.1, "farm": 1.5}, "BE": {"lab": 1.3},
    "SE": {"lab": 0.8, "nat": 0.9}, "DK": {"lab": 0.8, "nat": 0.9}, "NO": {"lab": 0.8, "nat": 0.7}, "FI": {"lab": 0.9, "nat": 0.8},
    "CH": {"lab": 0.6, "nat": 0.7, "clim": 0.8}, "LU": {"lab": 0.5, "nat": 0.4, "clim": 0.6},
    "PL": {"farm": 1.4, "nat": 1.2}, "HU": {"nat": 1.1}, "RS": {"stud": 1.3, "nat": 1.2}, "XK": {"nat": 1.4},
    "UA": {"nat": 1.0, "lab": 0.6, "clim": 0.3, "stud": 0.5},
    "MD": {"lab": 0.7, "clim": 0.3}, "BA": {"nat": 1.3, "lab": 0.7, "clim": 0.4}, "AL": {"clim": 0.5, "lab": 0.7},
    "ME": {"clim": 0.5}, "MK": {"clim": 0.5},
    "LI": {"lab": 0.4, "nat": 0.4, "clim": 0.5, "stud": 0.5}, "MT": {"lab": 0.8, "clim": 0.4}, "AD": {"lab": 0.5, "clim": 0.4, "nat": 0.4},
    "SM": {"lab": 0.8, "clim": 0.4, "nat": 0.4}, "MC": {"lab": 0.3, "clim": 0.3, "stud": 0.4}, "PM": {"lab": 0.7, "clim": 0.1, "stud": 0.4},
    "CY": {"lab": 0.9, "clim": 0.5}, "ES": {"stud": 1.1}, "PT": {"nat": 0.6}, "IE": {"nat": 0.8},
}
# типовые не создаются там, где особое движение того же типа уже закрывает нишу
SKIP_TYP = {"RU": ["civ"], "BY": ["civ"], "RS": ["stud"], "FR": ["lab"], "GB": ["lab", "clim"], "DE": ["clim", "nat", "farm"],
            "NL": ["farm", "clim"], "ES": ["civ"], "PL": ["farm"], "UA": ["civ", "nat"], "MD": ["nat"], "XK": ["nat"], "BE": ["lab"],
            "GR": [], "PT": ["lab"], "LI": ["civ"], "MT": ["civ", "farm", "nat"], "AD": ["civ"], "SM": ["civ"], "MC": ["clim", "nat"], "PM": ["nat", "civ", "lab"], "CY": ["nat", "civ"], "HR": ["lab"], "HU": ["stud"], "FI": ["clim"], "SE": ["clim"], "CZ": ["civ"], "SK": ["civ"]}


def q(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def main():
    tr = {}
    out = []
    out.append("# 0.65: данные политических движений (генерируется tools/gen_move65.py, руками не править).")
    out.append('extends "res://scripts/data/data_fin63.gd"')
    out.append("")
    out.append("# тип -> [id, имя, описание, поддержка B, организованность, радикальность]")
    out.append("const MV65_TYPES := {")
    allt = dict(TYP)
    allt.update(TYP2)
    for k, (ru, en, dru, den, b, o, r) in allt.items():
        tr[sid(ru)] = en
        tr[sid(dru)] = den
        out.append("\t%s: [%s, %s, %.1f, %d, %d]," % (q(k), q(ru), q(dru), b, o, r))
    out.append("}")
    out.append("")
    out.append("# страна -> список движений: [id, тип, имя, описание, поддержка %, организованность, радикальность, признаки]")
    out.append("const MV65_DATA := {")
    n_total = 0
    for cc in COUNTRIES:
        rows = []
        spec = SPEC.get(cc, [])
        skip = set(SKIP_TYP.get(cc, []))
        for (sid_, tp, ru, en, dru, den, b, o, r, fl) in spec:
            tr[sid(ru)] = en
            tr[sid(dru)] = den
            rows.append("\t\t[%s, %s, %s, %s, %.1f, %d, %d, %s]" % (q(sid_), q(tp), q(ru), q(dru), b, o, r, q(fl)))
        for tp in ["lab", "clim", "stud", "civ", "nat", "farm"]:
            if tp in skip or (tp == "farm" and cc in NO_FARM):
                continue
            ru, en, dru, den, b, o, r = TYP[tp]
            f = FACT.get(cc, {}).get(tp, 1.0)
            rows.append("\t\t[%s, %s, %s, %s, %.1f, %d, %d, %s]" % (q(cc.lower() + "_" + tp), q(tp), q(ru), q(dru), b * f, o, r, q("")))
        n_total += len(rows)
        out.append("\t%s: [\n%s\n\t]," % (q(cc), ",\n".join(rows)))
    out.append("}")
    out.append("")
    with open(os.path.join(ROOT, "scripts/data/data_move65.gd"), "w", encoding="utf-8") as f:
        f.write("\n".join(out))
    with open(os.path.join(ROOT, "i18n/en/65_move.json"), "w", encoding="utf-8") as f:
        json.dump(tr, f, ensure_ascii=False, indent=1, sort_keys=True)
    print("движений:", n_total, "переводов:", len(tr))


if __name__ == "__main__":
    main()
