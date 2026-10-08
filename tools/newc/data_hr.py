# ЗАГОТОВКА HR — заменить настоящими данными (docs/NEWC_SPEC.md)
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
D = datio.loadn(os.path.join(HERE, "ph", "hr_D.dat"))
E = json.load(open(os.path.join(HERE, "ph", "hr_E.json")))
WORLD = {'name': 'Хорватия', 'cap': 'Загреб', 'latlon': (45.81, 15.98), 'pop': 3.86, 'gdp': 90.0, 'debt': 54.0, 'growth': 1.5, 'infl': 2.5, 'unemp': 5.5, 'def': 3.0, 'stab': 60, 'appr': 35, 'gov': 'заготовка', 'gov_party': 'заготовка', 'pot': 1.5, 'ecb_w': 0.01, 'stance': {'eu': 0.5, 'aus': 0.2, 'trd': 0.6, 'brd': 0.0, 'nuk': 0.0}, 'desc': 'Заготовка', 'leader': 'Премьер-министр', 'pn': ['П1', 'П2', 'П3', 'П4', 'П5', 'П6', 'Др.', 'П8', 'П9', 'П10'], 'eu': True, 'euro': True, 'likes': 'заготовка', 'dislikes': 'заготовка', 'open': 0.7, 'stance0': 0.1, 'ccol': (0.62, 0.4, 0.42, 1.0), 'rel': {'DE': 70, 'FR': 70, 'NL': 70, 'BE': 70, 'LU': 70, 'CH': 70, 'AT': 70, 'PL': 70, 'CZ': 70, 'DK': 70, 'NO': 70, 'SE': 70, 'IT': 70, 'ES': 70, 'PT': 70, 'GB': 70, 'IE': 70, 'SI': 70, 'SK': 70, 'HU': 70, 'FI': 70, 'RS': 70, 'BA': 70, 'ME': 70, 'MK': 70, 'AL': 70, 'XK': 70, 'BG': 70, 'RO': 70, 'GR': 70, 'EE': 70, 'LV': 70, 'LT': 70}, 'trade_x': {'DE': 15.4, 'FR': 12.6, 'NL': 8.1, 'BE': 5.8, 'LU': 2.1, 'CH': 6.4, 'AT': 5.0, 'PL': 6.7, 'CZ': 4.0, 'DK': 4.6, 'NO': 4.7, 'SE': 5.4, 'IT': 10.7, 'ES': 9.2, 'PT': 3.9, 'GB': 13.3, 'IE': 5.3, 'SI': 1.9, 'SK': 2.7, 'HU': 3.4, 'FI': 3.8, 'RS': 2.0, 'BA': 1.2, 'ME': 0.6, 'MK': 0.9, 'AL': 1.1, 'XK': 0.8, 'BG': 2.3, 'RO': 4.3, 'GR': 3.5, 'EE': 1.4, 'LV': 1.5, 'LT': 2.0}, 'trade_m': {'DE': 15.4, 'FR': 12.6, 'NL': 8.1, 'BE': 5.8, 'LU': 2.1, 'CH': 6.4, 'AT': 5.0, 'PL': 6.7, 'CZ': 4.0, 'DK': 4.6, 'NO': 4.7, 'SE': 5.4, 'IT': 10.7, 'ES': 9.2, 'PT': 3.9, 'GB': 13.3, 'IE': 5.3, 'SI': 1.9, 'SK': 2.7, 'HU': 3.4, 'FI': 3.8, 'RS': 2.0, 'BA': 1.2, 'ME': 0.6, 'MK': 0.9, 'AL': 1.1, 'XK': 0.8, 'BG': 2.3, 'RO': 4.3, 'GR': 3.5, 'EE': 1.4, 'LV': 1.5, 'LT': 2.0}}
REG_EVENTS = []
ELEC = {"sys": "Заготовка", "turn": 0.65, "note": "", "head": "monarch"}
RAD_CUR = "Заготовка"
MONARCHY = False
