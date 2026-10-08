# ЗАГОТОВКА ME — заменить настоящими данными (docs/NEWC_SPEC.md)
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
D = datio.loadn(os.path.join(HERE, "ph", "me_D.dat"))
E = json.load(open(os.path.join(HERE, "ph", "me_E.json")))
WORLD = {'name': 'Черногория', 'cap': 'Подгорица', 'latlon': (42.44, 19.26), 'pop': 0.62, 'gdp': 7.5, 'debt': 4.5, 'growth': 1.5, 'infl': 2.5, 'unemp': 5.5, 'def': 3.0, 'stab': 60, 'appr': 35, 'gov': 'заготовка', 'gov_party': 'заготовка', 'pot': 1.5, 'ecb_w': 0.01, 'stance': {'eu': 0.5, 'aus': 0.2, 'trd': 0.6, 'brd': 0.0, 'nuk': 0.0}, 'desc': 'Заготовка', 'leader': 'Премьер-министр', 'pn': ['П1', 'П2', 'П3', 'П4', 'П5', 'П6', 'Др.', 'П8', 'П9', 'П10'], 'eu': False, 'euro': True, 'likes': 'заготовка', 'dislikes': 'заготовка', 'open': 0.7, 'stance0': 0.1, 'ccol': (0.66, 0.52, 0.32, 1.0), 'rel': {'DE': 70, 'FR': 70, 'NL': 70, 'BE': 70, 'LU': 70, 'CH': 70, 'AT': 70, 'PL': 70, 'CZ': 70, 'DK': 70, 'NO': 70, 'SE': 70, 'IT': 70, 'ES': 70, 'PT': 70, 'GB': 70, 'IE': 70, 'SI': 70, 'SK': 70, 'HU': 70, 'FI': 70, 'HR': 70, 'RS': 70, 'BA': 70, 'MK': 70, 'AL': 70, 'XK': 70, 'BG': 70, 'RO': 70, 'GR': 70, 'EE': 70, 'LV': 70, 'LT': 70}, 'trade_x': {'DE': 4.5, 'FR': 3.6, 'NL': 2.3, 'BE': 1.7, 'LU': 0.6, 'CH': 1.9, 'AT': 1.4, 'PL': 1.9, 'CZ': 1.2, 'DK': 1.3, 'NO': 1.4, 'SE': 1.6, 'IT': 3.1, 'ES': 2.7, 'PT': 1.1, 'GB': 3.8, 'IE': 1.5, 'SI': 0.6, 'SK': 0.8, 'HU': 1.0, 'FI': 1.1, 'HR': 0.6, 'RS': 0.6, 'BA': 0.4, 'MK': 0.3, 'AL': 0.3, 'XK': 0.2, 'BG': 0.7, 'RO': 1.2, 'GR': 1.0, 'EE': 0.4, 'LV': 0.4, 'LT': 0.6}, 'trade_m': {'DE': 4.5, 'FR': 3.6, 'NL': 2.3, 'BE': 1.7, 'LU': 0.6, 'CH': 1.9, 'AT': 1.4, 'PL': 1.9, 'CZ': 1.2, 'DK': 1.3, 'NO': 1.4, 'SE': 1.6, 'IT': 3.1, 'ES': 2.7, 'PT': 1.1, 'GB': 3.8, 'IE': 1.5, 'SI': 0.6, 'SK': 0.8, 'HU': 1.0, 'FI': 1.1, 'HR': 0.6, 'RS': 0.6, 'BA': 0.4, 'MK': 0.3, 'AL': 0.3, 'XK': 0.2, 'BG': 0.7, 'RO': 1.2, 'GR': 1.0, 'EE': 0.4, 'LV': 0.4, 'LT': 0.6}}
REG_EVENTS = []
ELEC = {"sys": "Заготовка", "turn": 0.65, "note": "", "head": "monarch"}
RAD_CUR = "Заготовка"
MONARCHY = False
