# ЗАГОТОВКА GR — заменить настоящими данными (docs/NEWC_SPEC.md)
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
D = datio.loadn(os.path.join(HERE, "ph", "gr_D.dat"))
E = json.load(open(os.path.join(HERE, "ph", "gr_E.json")))
WORLD = {'name': 'Греция', 'cap': 'Афины', 'latlon': (37.98, 23.73), 'pop': 10.4, 'gdp': 240.0, 'debt': 144.0, 'growth': 1.5, 'infl': 2.5, 'unemp': 5.5, 'def': 3.0, 'stab': 60, 'appr': 35, 'gov': 'заготовка', 'gov_party': 'заготовка', 'pot': 1.5, 'ecb_w': 0.01, 'stance': {'eu': 0.5, 'aus': 0.2, 'trd': 0.6, 'brd': 0.0, 'nuk': 0.0}, 'desc': 'Заготовка', 'leader': 'Премьер-министр', 'pn': ['П1', 'П2', 'П3', 'П4', 'П5', 'П6', 'Др.', 'П8', 'П9', 'П10'], 'eu': True, 'euro': True, 'likes': 'заготовка', 'dislikes': 'заготовка', 'open': 0.7, 'stance0': 0.1, 'ccol': (0.4, 0.62, 0.8, 1.0), 'rel': {'DE': 70, 'FR': 70, 'NL': 70, 'BE': 70, 'LU': 70, 'CH': 70, 'AT': 70, 'PL': 70, 'CZ': 70, 'DK': 70, 'NO': 70, 'SE': 70, 'IT': 70, 'ES': 70, 'PT': 70, 'GB': 70, 'IE': 70, 'SI': 70, 'SK': 70, 'HU': 70, 'FI': 70, 'HR': 70, 'RS': 70, 'BA': 70, 'ME': 70, 'MK': 70, 'AL': 70, 'XK': 70, 'BG': 70, 'RO': 70, 'EE': 70, 'LV': 70, 'LT': 70}, 'trade_x': {'DE': 25.2, 'FR': 20.5, 'NL': 13.2, 'BE': 9.5, 'LU': 3.4, 'CH': 10.5, 'AT': 8.1, 'PL': 11.0, 'CZ': 6.5, 'DK': 7.4, 'NO': 7.7, 'SE': 8.8, 'IT': 17.4, 'ES': 15.1, 'PT': 6.3, 'GB': 21.7, 'IE': 8.6, 'SI': 3.1, 'SK': 4.4, 'HU': 5.5, 'FI': 6.2, 'HR': 3.5, 'RS': 3.3, 'BA': 2.0, 'ME': 1.0, 'MK': 1.5, 'AL': 1.9, 'XK': 1.2, 'BG': 3.8, 'RO': 7.1, 'EE': 2.4, 'LV': 2.4, 'LT': 3.3}, 'trade_m': {'DE': 25.2, 'FR': 20.5, 'NL': 13.2, 'BE': 9.5, 'LU': 3.4, 'CH': 10.5, 'AT': 8.1, 'PL': 11.0, 'CZ': 6.5, 'DK': 7.4, 'NO': 7.7, 'SE': 8.8, 'IT': 17.4, 'ES': 15.1, 'PT': 6.3, 'GB': 21.7, 'IE': 8.6, 'SI': 3.1, 'SK': 4.4, 'HU': 5.5, 'FI': 6.2, 'HR': 3.5, 'RS': 3.3, 'BA': 2.0, 'ME': 1.0, 'MK': 1.5, 'AL': 1.9, 'XK': 1.2, 'BG': 3.8, 'RO': 7.1, 'EE': 2.4, 'LV': 2.4, 'LT': 3.3}}
REG_EVENTS = []
ELEC = {"sys": "Заготовка", "turn": 0.65, "note": "", "head": "monarch"}
RAD_CUR = "Заготовка"
MONARCHY = False
