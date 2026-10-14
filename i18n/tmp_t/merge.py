import json,sys,glob,importlib
sys.path.insert(0,'/home/claude/sym/repo/i18n/tmp_t')
n=sys.argv[1]
d=json.load(open(f'/home/claude/sym/repo/i18n/todo/chunk_{n}.json'))
out={}
for m in sys.argv[2:]:
    out.update(importlib.import_module(m).T)
miss=[k for k in d if k not in out]; extra=[k for k in out if k not in d]
print('missing',len(miss),'extra',extra)
import re
res={k:re.sub(r'(?<=\d)% (?=[a-z])','%\u00a0',out.get(k,'')) for k in d}
if not miss:
    json.dump(res,open(f'/home/claude/sym/repo/i18n/en/chunk_{n}.json','w'),ensure_ascii=False,indent=1)
