# ============================================================
#  НАСЕЛЕНИЕ: АГЕНТЫ (1 агент = k человек)
# ============================================================
# Каждый агент — «срез» из k человек одной группы одного региона: у него возраст, доход, отрасль, занятость,
# четыре идеологические оси, веса интересов (налоги, соцрасходы, работа, безопасность, природа, цены),
# личная оценка власти и симпатии к партиям. Группы интересов — это агрегаты агентов:
# средняя оценка группы совпадает с её рейтингом, а разброс внутри группы даёт агенты.
extends RefCounted

const G := 8
const AX := 4
const NK := 6
const BETA := 0.8
const SD_IDE := 0.5
const UNEMP_PEN := 6.0
const DIST_K := 4.0
const PROT_AT := 38.0
const AXIS_NAMES := ["Экономика: левые ↔ рынок", "Общество: свобода ↔ порядок", "Природа: рост ↔ экология", "Нация: открытость ↔ суверенитет"]
const AXIS_SHORT := ["Экономика", "Общество", "Природа", "Нация"]
# что означают концы осей: [отрицательный, положительный]
const AXIS_ENDS := [["Левые: соцгарантии", "Рынок: низкие налоги"], ["Свобода", "Порядок и безопасность"], ["Рост и индустрия", "Экология"], ["Открытость к миру", "Суверенитет"]]
const KEY_NAMES := ["налоги", "соцрасходы", "работа и рост", "безопасность", "природа", "цены"]
const SEC_NAMES := ["промышленность", "сельское хозяйство", "услуги", "добыча", "госсектор", "пенсия"]
# центры идеологических осей групп
const MU := [
	[-0.5, 0.3, -0.1, 0.3], [0.9, -0.1, -0.3, 0.0], [0.1, 0.6, 0.0, 0.4], [-0.2, -0.7, 0.5, -0.4],
	[-0.3, -0.1, 0.2, 0.0], [0.2, 0.5, -0.3, 0.5], [0.3, 0.8, -0.3, 0.6], [-0.3, -0.5, 1.0, -0.3]]
const G_AGE := [[25.0, 64.0], [28.0, 66.0], [65.0, 92.0], [18.0, 29.0], [25.0, 64.0], [20.0, 70.0], [22.0, 58.0], [18.0, 60.0]]
const G_INC := [0.85, 2.2, 0.75, 0.6, 0.95, 0.75, 1.0, 1.1]
const G_UNEMP := [1.2, 0.4, 0.0, 2.0, 0.3, 1.0, 0.2, 0.9]
# веса интересов: налоги, соцрасходы, работа, безопасность, природа, цены
const CW := [
	[1.8, 2.0, 2.0, 0.6, 0.4, 1.8], [2.5, 0.4, 2.0, 0.8, 0.3, 1.2], [1.0, 2.2, 0.5, 1.2, 0.5, 2.5],
	[1.2, 1.2, 2.2, 0.6, 1.5, 1.0], [1.0, 2.2, 1.0, 0.8, 0.6, 1.6], [1.2, 1.2, 1.2, 0.8, 0.3, 1.8],
	[1.0, 0.8, 1.0, 2.5, 0.3, 1.2], [0.8, 1.0, 0.6, 0.4, 2.5, 0.8]]
const SEC_W := [
	[1.0, 0.2, 0.8, 1.0], [0.8, 0.2, 1.2, 0.5], [0.0, 0.0, 0.0, 0.0], [0.4, 0.1, 1.0, 0.2],
	[0.0, 0.0, 0.0, 0.0], [0.1, 3.0, 0.2, 0.3], [0.0, 0.0, 0.0, 0.0], [0.3, 0.2, 1.0, 0.1]]

var n := 0
var R := 0
var P := 0
var k := 500
var rng := RandomNumberGenerator.new()
var cell_start := PackedInt32Array()
var reg := PackedByteArray()
var grp := PackedByteArray()
var sec := PackedByteArray()
var emp := PackedByteArray()
var prot := PackedByteArray()
var faith := PackedByteArray()   # вероисповедание агента (0..6, 6 — нерелигиозный)
var devout := PackedByteArray()  # 1 — практикующий верующий
var frng := RandomNumberGenerator.new()
const REL_GM := [1.0, 1.05, 0.55, 1.35, 0.95, 0.8, 0.9, 1.4]   # во сколько раз у группы чаще «нерелигиозный»
# v47_1: личная история и поведение
var edu := PackedByteArray()      # образование: 0 — базовое, 1 — среднее/профессиональное, 2 — высшее
var unm := PackedByteArray()      # сколько месяцев подряд без работы (до 120)
var pb := PackedFloat32Array()    # «кошелёк»: как менялся личный реальный доход (п.п., скользящее)
var trust := PackedFloat32Array() # доверие к институтам 0..1
var trust0 := PackedFloat32Array() # личная «норма» доверия (к ней доверие возвращается в спокойные времена)
var tp := PackedFloat32Array()    # склонность прийти на выборы 0..1
var act := PackedByteArray()      # 1 — активист (протест заразителен и вдвое весомее)
var peers := PackedInt32Array()   # окружение: 3 знакомых на агента (2 — та же группа и регион, 1 — тот же регион)
var emul := PackedFloat32Array()  # личный риск потерять работу (образование, отрасль)
var emul_g := PackedFloat32Array()
var sw_cnt := 0                   # переходов работа/безработица за последний шаг (для статистики)
const NPEER := 3
const EDU_NAMES := ["базовое", "среднее", "высшее"]
const G_EDU := [[0.35, 0.55, 0.10], [0.05, 0.30, 0.65], [0.40, 0.45, 0.15], [0.10, 0.50, 0.40], [0.05, 0.35, 0.60], [0.40, 0.50, 0.10], [0.10, 0.60, 0.30], [0.08, 0.37, 0.55]]
var age := PackedFloat32Array()
var inc := PackedFloat32Array()
var ide := PackedFloat32Array()
var ide0 := PackedFloat32Array()
var cw := PackedFloat32Array()
var eps := PackedFloat32Array()
var off := PackedFloat32Array()
var dist := PackedFloat32Array()
var aff := PackedFloat32Array()
var cellnorm := PackedFloat32Array()
var pos := PackedFloat32Array()
var gpos := PackedFloat32Array()
var gcount := PackedInt32Array()
var rcount := PackedInt32Array()
var rprot := PackedInt32Array()
var sum_off := PackedFloat64Array()
var wbar := PackedFloat32Array()
var dbar := PackedFloat32Array()
var tmp := PackedFloat32Array()
var steps := 0
# корзина товаров: у каждого агента свои доли расходов (возраст, доход и группа задают, на что он тратит)
var NG := 0
var gkg := PackedFloat32Array()
var gprof := PackedFloat32Array()
var gae := PackedFloat32Array()
var gic := PackedFloat32Array()
var gw := PackedFloat32Array()
var gwbar := PackedFloat32Array()

func setup(spec: Dictionary) -> void:
	R = int(spec["R"])
	P = int(spec["P"])
	k = int(spec["k"])
	rng.seed = int(spec["seed"])
	var counts: Array = spec["counts"]
	var secw: Array = spec["secw"]
	var pos_in: Array = spec["pos"]
	var ur: float = float(spec["ur"])
	var sup: Array = spec["sup"]
	NG = int(spec.get("ng", 0))
	gkg.resize(NG)
	gae.resize(NG)
	gic.resize(NG)
	gprof.resize(G * NG)
	for j in NG:
		gkg[j] = float(spec["gkg"][j])
		gae[j] = float(spec["gae"][j])
		gic[j] = float(spec["gic"][j])
		for g in G:
			gprof[g * NG + j] = float(spec["gprof"][g][j])
	pos.resize(P * AX)
	for p in P:
		for a in AX:
			pos[p * AX + a] = float(pos_in[p][a])
	gpos.resize(AX)
	for a in AX:
		gpos[a] = float(spec["gpos"][a])
	cell_start.resize(R * G + 1)
	var tot := 0
	for r in R:
		for g in G:
			cell_start[r * G + g] = tot
			tot += int(counts[r][g])
	cell_start[R * G] = tot
	n = tot
	reg.resize(n)
	grp.resize(n)
	sec.resize(n)
	emp.resize(n)
	prot.resize(n)
	faith.resize(n)
	devout.resize(n)
	frng.seed = int(spec["seed"]) + 7
	var relsh: Array = spec.get("rel", [])
	age.resize(n)
	edu.resize(n)
	unm.resize(n)
	pb.resize(n)
	trust.resize(n)
	trust0.resize(n)
	tp.resize(n)
	act.resize(n)
	emul.resize(n)
	inc.resize(n)
	ide.resize(n * AX)
	ide0.resize(n * AX)
	cw.resize(n * NK)
	gw.resize(n * NG)
	eps.resize(n)
	off.resize(n)
	dist.resize(n)
	aff.resize(n * P)
	cellnorm.resize(R * G * P)
	tmp.resize(P)
	var sums := PackedFloat64Array()
	sums.resize(P)
	for r in R:
		for g in G:
			var c := r * G + g
			var s: int = cell_start[c]
			var e: int = cell_start[c + 1]
			for p in P:
				sums[p] = 0.0
			for i in range(s, e):
				gen_agent(i, r, g, secw[r], ur)
				gen_faith(i, r, g, relsh)
				for p in P:
					sums[p] += aff[i * P + p]
			var cnt: int = e - s
			for p in P:
				var m: float = sums[p] / float(maxi(1, cnt)) if cnt > 0 else 1.0
				cellnorm[c * P + p] = m
				if cnt > 0 and m > 0.0:
					for i in range(s, e):
						aff[i * P + p] /= m
	build_peers()
	norm_emul()
	recompute_stats()
	init_off(sup, ur)
	faith_base()

var f0: Array = []   # стартовые доли вер по регионам (по агентам)

func faith_shares() -> Array:
	var R: int = 0
	for i in n:
		R = maxi(R, reg[i] + 1)
	var cnt: Array = []
	for r in R:
		cnt.append([0, 0, 0, 0, 0, 0, 0])
	for i in n:
		cnt[reg[i]][faith[i]] += 1
	var out: Array = []
	for r in R:
		var tot := 0
		for f in 7:
			tot += int(cnt[r][f])
		var row: Array = []
		for f in 7:
			row.append(float(cnt[r][f]) / float(maxi(1, tot)))
		out.append(row)
	return out

func faith_base() -> void:
	f0 = faith_shares()

# подтянуть веру агентов к модели: цель = стартовая доля агентов + (доля модели − стартовая доля модели)
func sync_faith(rel: Array, rel0: Array) -> void:
	if f0.is_empty():
		return
	var cur: Array = faith_shares()
	var R: int = mini(cur.size(), rel.size())
	var leave: Array = []
	var need: Array = []
	for r in R:
		var t: Array = []
		var tot := 0.0
		for f in 7:
			var x: float = maxf(0.0, float(f0[r][f]) + float(rel[r][f]) - float(rel0[r][f]))
			t.append(x)
			tot += x
		var lv: Array = []
		var nd: Array = []
		var nsum := 0.0
		for f in 7:
			var tf: float = float(t[f]) / maxf(0.0001, tot)
			var cf: float = float(cur[r][f])
			lv.append(clampf((cf - tf) / maxf(0.0001, cf), 0.0, 1.0) if cf > tf else 0.0)
			var nn: float = maxf(0.0, tf - cf)
			nd.append(nn)
			nsum += nn
		leave.append(lv)
		need.append([nd, nsum])
	for i in n:
		var r2: int = reg[i]
		if r2 >= R:
			continue
		var f2: int = faith[i]
		var pl: float = float(leave[r2][f2])
		if pl > 0.0 and frng.randf() < pl:
			var nd2: Array = need[r2][0]
			var ns: float = float(need[r2][1])
			if ns <= 0.0:
				continue
			var t2: float = frng.randf() * ns
			for g in 7:
				t2 -= float(nd2[g])
				if t2 <= 0.0:
					faith[i] = g
					if g == 6:
						devout[i] = 0
					break

func gen_faith(i: int, r: int, g: int, relsh: Array) -> void:
	# вера агента: доли региона, поправка на группу и возраст; отдельный генератор, чтобы не сдвигать остальные случайные числа
	if relsh.is_empty() or r >= relsh.size():
		faith[i] = 6
		devout[i] = 0
		return
	var sh: Array = relsh[r]
	var m: float = float(REL_GM[g]) * (0.8 if age[i] > 60.0 else (1.15 if age[i] < 30.0 else 1.0))
	var tot := 0.0
	var w: Array = []
	for f in 7:
		var x: float = float(sh[f]) * (m if f == 6 else 1.0)
		w.append(x)
		tot += x
	var t: float = frng.randf() * tot
	var pick := 6
	for f in 7:
		t -= float(w[f])
		if t <= 0.0:
			pick = f
			break
	faith[i] = pick
	var dev_p: float = 0.0 if pick == 6 else clampf(0.25 + (age[i] - 40.0) * 0.006 + (0.15 if g == 2 else 0.0), 0.05, 0.9)
	devout[i] = 1 if frng.randf() < dev_p else 0


func faith_counts(region: int = -1) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(7)
	for i in n:
		if region < 0 or reg[i] == region:
			out[faith[i]] += 1
	return out


func gen_agent(i: int, r: int, g: int, secw: Array, ur: float) -> void:
	reg[i] = r
	grp[i] = g
	var ag: Array = G_AGE[g]
	age[i] = lerpf(float(ag[0]), float(ag[1]), (rng.randf() + rng.randf()) * 0.5)
	var ep: Array = G_EDU[g]
	var ru: float = rng.randf()
	edu[i] = 0 if ru < float(ep[0]) else (1 if ru < float(ep[0]) + float(ep[1]) else 2)
	if age[i] > 60.0 and edu[i] == 2 and rng.randf() < 0.3:
		edu[i] = 1
	inc[i] = float(G_INC[g]) * exp(rng.randfn(0.0, 0.35)) * [0.8, 1.0, 1.3][edu[i]]
	sec[i] = sector_pick(g, secw)
	emul[i] = [1.5, 1.0, 0.55][edu[i]] * (1.3 if sec[i] == 0 or sec[i] == 3 else (0.6 if sec[i] == 4 else 1.0)) * exp(rng.randfn(0.0, 0.25))
	emp[i] = 0 if rng.randf() < clampf(ur * float(G_UNEMP[g]) * emul[i], 0.0, 0.6) else 1
	unm[i] = 0 if emp[i] == 1 else rng.randi_range(1, 14)
	pb[i] = 0.0
	trust0[i] = clampf(0.55 + rng.randfn(0.0, 0.18) + 0.06 * float(edu[i]), 0.05, 0.95)
	trust[i] = clampf(trust0[i] - (0.1 if emp[i] == 0 else 0.0), 0.02, 0.98)
	act[i] = 0
	tp[i] = 0.5
	var mu: Array = MU[g]
	for a in AX:
		var v: float = float(mu[a]) + rng.randfn(0.0, SD_IDE)
		ide[i * AX + a] = v
		ide0[i * AX + a] = v
	var cwg: Array = CW[g]
	for kk in NK:
		cw[i * NK + kk] = maxf(0.0, float(cwg[kk]) * (1.0 + rng.randfn(0.0, 0.35)))
	# образование сдвигает взгляды: высшее — к свободе и открытости, базовое — к порядку и суверенитету
	ide[i * AX + 1] += (1.0 - float(edu[i])) * 0.18
	ide[i * AX + 3] += (1.0 - float(edu[i])) * 0.15
	ide0[i * AX + 1] = ide[i * AX + 1]
	ide0[i * AX + 3] = ide[i * AX + 3]
	eps[i] = rng.randfn(0.0, 4.0)
	tp[i] = turnout_of(i, 50.0)
	calc_aff_raw(i, g)
	if NG > 0:
		var tot := 0.0
		var b := i * NG
		for j in NG:
			var w: float = gkg[j] * gprof[g * NG + j] * exp(gae[j] * (age[i] - 45.0) / 30.0) * pow(inc[i], gic[j]) * exp(rng.randfn(0.0, 0.25))
			gw[b + j] = w
			tot += w
		for j in NG:
			gw[b + j] /= maxf(tot, 0.000001)

func sector_pick(g: int, secw: Array) -> int:
	if g == 2:
		return 5
	if g == 4 or g == 6:
		return 4
	var w: Array = SEC_W[g]
	var keys := ["ind", "agr", "srv", "res"]
	var tot := 0.0
	var ws: Array[float] = []
	for j in 4:
		var x: float = float(w[j]) * float((secw as Array)[j]) if secw is Array else 0.0
		ws.append(x)
		tot += x
	var t: float = rng.randf() * tot
	for j in 4:
		t -= ws[j]
		if t <= 0.0:
			return j
	return 2

# v47_1: окружение — 2 знакомых из той же группы и региона, 1 — из того же региона
func build_peers() -> void:
	peers.resize(n * NPEER)
	for r in R:
		var r0: int = cell_start[r * G]
		var r1: int = cell_start[r * G + G]
		for g in G:
			var c := r * G + g
			var s0: int = cell_start[c]
			var e0: int = cell_start[c + 1]
			for i in range(s0, e0):
				for kq in NPEER:
					var j := i
					if kq < 2 and e0 - s0 > 1:
						j = rng.randi_range(s0, e0 - 1)
					elif r1 - r0 > 1:
						j = rng.randi_range(r0, r1 - 1)
					peers[i * NPEER + kq] = j


# средний риск безработицы в группе = 1, чтобы доля безработных группы совпадала с макромоделью
func norm_emul() -> void:
	emul_g.resize(G)
	var sm := PackedFloat64Array()
	sm.resize(G)
	var cn := PackedInt32Array()
	cn.resize(G)
	for i in n:
		sm[grp[i]] += emul[i]
		cn[grp[i]] += 1
	for g in G:
		emul_g[g] = float(sm[g] / float(maxi(1, cn[g]))) if cn[g] > 0 else 1.0
	for i in n:
		emul[i] /= maxf(0.05, emul_g[grp[i]])


func turnout_of(i: int, a: float) -> float:
	# склонность голосовать: возраст, образование, доверие, сила чувств (очень довольные и очень злые ходят чаще), безработица
	var t: float = 0.42 + 0.0045 * (age[i] - 18.0) + 0.07 * float(edu[i]) + 0.18 * (trust[i] - 0.5) + 0.12 * absf(a - 50.0) / 50.0 - (0.12 if emp[i] == 0 and grp[i] != 2 else 0.0)
	return clampf(t, 0.08, 0.97)


func calc_aff_raw(i: int, g: int) -> void:
	var mu: Array = MU[g]
	var d0: float = ide[i * AX] - float(mu[0])
	var d1: float = ide[i * AX + 1] - float(mu[1])
	var d2: float = ide[i * AX + 2] - float(mu[2])
	var d3: float = ide[i * AX + 3] - float(mu[3])
	for p in P:
		var q := p * AX
		aff[i * P + p] = exp(BETA * (d0 * pos[q] + d1 * pos[q + 1] + d2 * pos[q + 2] + d3 * pos[q + 3]))
	var g0: float = ide[i * AX] - gpos[0]
	var g1: float = ide[i * AX + 1] - gpos[1]
	var g2: float = ide[i * AX + 2] - gpos[2]
	var g3: float = ide[i * AX + 3] - gpos[3]
	dist[i] = sqrt(g0 * g0 + g1 * g1 + g2 * g2 + g3 * g3)

func calc_aff(i: int) -> void:
	var g: int = grp[i]
	calc_aff_raw(i, g)
	var c: int = int(reg[i]) * G + g
	for p in P:
		var m: float = cellnorm[c * P + p]
		if m > 0.0:
			aff[i * P + p] /= m

func recompute_stats() -> void:
	gcount.resize(G)
	rcount.resize(R)
	wbar.resize(G * NK)
	gwbar.resize(G * NG)
	dbar.resize(G)
	var ws := PackedFloat64Array()
	ws.resize(G * NK)
	var ds := PackedFloat64Array()
	ds.resize(G)
	var gs := PackedFloat64Array()
	gs.resize(G * NG)
	for g in G:
		gcount[g] = 0
		dbar[g] = 0.0
	for r in R:
		rcount[r] = 0
	for i in n:
		var g: int = grp[i]
		gcount[g] += 1
		rcount[reg[i]] += 1
		ds[g] += dist[i]
		for kk in NK:
			ws[g * NK + kk] += cw[i * NK + kk]
		for j in NG:
			gs[g * NG + j] += gw[i * NG + j]
	for g in G:
		var c: float = float(maxi(1, gcount[g]))
		dbar[g] = ds[g] / c
		for kk in NK:
			wbar[g * NK + kk] = ws[g * NK + kk] / c
		for j in NG:
			gwbar[g * NG + j] = gs[g * NG + j] / c

func ugp(ur: float, g: int) -> float:
	return clampf(ur * float(G_UNEMP[g]), 0.0, 0.6)

func init_off(sup: Array, ur: float) -> void:
	sum_off.resize(G)
	for g in G:
		sum_off[g] = 0.0
	rprot.resize(R)
	for r in R:
		rprot[r] = 0
	for i in n:
		var g: int = grp[i]
		var t: float = eps[i] - UNEMP_PEN * (float(1 - emp[i]) - ugp(ur, g)) - DIST_K * (dist[i] - dbar[g])
		off[i] = t
		sum_off[g] += t
	var ob := group_offbar()
	for i in n:
		var g: int = grp[i]
		var a: float = float(sup[g]) + off[i] - ob[g]
		var pr: int = 1 if a < PROT_AT else 0
		prot[i] = pr
		rprot[reg[i]] += pr

func group_offbar() -> PackedFloat32Array:
	var ob := PackedFloat32Array()
	ob.resize(G)
	for g in G:
		ob[g] = float(sum_off[g] / float(maxi(1, gcount[g])))
	return ob

func approval_of(i: int, sup: Array, ob: PackedFloat32Array) -> float:
	var g: int = grp[i]
	return clampf(float(sup[g]) + off[i] - ob[g], 0.0, 100.0)

# один шаг: обновляется каждый stride-й агент (со сдвигом phase)
# v47_1: у агента есть личная история — работа с памятью (месяцы без работы), «кошелёк», доверие, явка;
# взгляды меняются от опыта (безработица, цены, безопасность, природа, миграция, коррупция) и от окружения.
func step(ctx: Dictionary, phase: int, stride: int) -> void:
	var z: PackedFloat32Array = ctx["z"]
	var sup: Array = ctx["sup"]
	var ur: float = float(ctx["ur"])
	var zg: PackedFloat32Array = ctx.get("zg", PackedFloat32Array())
	var gp: Array = ctx["gpos"]
	var infl: float = float(ctx.get("infl", 2.0))
	var grw: float = float(ctx.get("growth", 1.0))
	var secl: float = float(ctx.get("sec", 50.0))
	var envl: float = float(ctx.get("env", 50.0))
	var migr: float = float(ctx.get("mig", 0.0))
	var corl: float = float(ctx.get("cor", 50.0))
	var rloy: PackedFloat32Array = ctx.get("rloy", PackedFloat32Array())
	var months: float = float(stride)
	for a0 in AX:
		gpos[a0] = float(gp[a0])
	var ob := group_offbar()
	var up := PackedFloat32Array()
	up.resize(G)
	for g in G:
		up[g] = ugp(ur, g)
	sw_cnt = 0
	var lam: float = clampf(0.45 * months / 4.0, 0.05, 0.9)
	var i := phase
	while i < n:
		var g: int = grp[i]
		var j := i * AX
		# --- работа: потеря и поиск с памятью ---
		if g != 2 and up[g] > 0.0:
			var ut: float = clampf(up[g] * emul[i], 0.0, 0.9)
			if emp[i] == 1:
				if rng.randf() < lam * ut:
					emp[i] = 0
					unm[i] = 0
					sw_cnt += 1
			else:
				# чем дольше без работы, тем труднее найти (эффект «рубца»)
				var fnd: float = lam * (1.0 - ut) * (1.0 - minf(0.5, float(unm[i]) / 60.0))
				if rng.randf() < fnd:
					emp[i] = 1
					sw_cnt += 1
				else:
					unm[i] = mini(120, int(unm[i]) + int(months))
		# --- кошелёк: личный реальный доход ---
		# зарплаты растут вместе с экономикой плюс обычная индексация (~2%), инфляция бьёт сильнее по бедным и пенсионерам
		var shock_i: float = grw + 2.0 - infl * (1.25 if g == 2 or edu[i] == 0 else 0.95) + rng.randfn(0.0, 1.5)
		if emp[i] == 0 and g != 2:
			shock_i -= 12.0
		pb[i] = pb[i] * 0.75 + shock_i * 0.25
		# --- доверие: коррупция, безработица, личный опыт; возвращается к личной норме, поэтому без кризисов не скатывается ---
		var tr: float = trust[i] + 0.004 * (50.0 - corl) / 10.0 + 0.002 * clampf(pb[i], -5.0, 3.0) - (0.01 if unm[i] >= 12 else 0.0)
		trust[i] = clampf(tr + (trust0[i] - trust[i]) * 0.04, 0.02, 0.98)
		# --- оценка власти ---
		var d0: float = ide[j] - gpos[0]
		var d1: float = ide[j + 1] - gpos[1]
		var d2: float = ide[j + 2] - gpos[2]
		var d3: float = ide[j + 3] - gpos[3]
		dist[i] = sqrt(d0 * d0 + d1 * d1 + d2 * d2 + d3 * d3)
		var t: float = eps[i] - UNEMP_PEN * (float(1 - emp[i]) - up[g] * emul[i]) - DIST_K * (dist[i] - dbar[g])
		t += clampf(pb[i], -15.0, 10.0) * 0.22 + (trust[i] - 0.55) * 8.0
		if rloy.size() == R:
			t += rloy[reg[i]]
		var b := i * NK
		var wb := g * NK
		for kk in NK:
			t += (cw[b + kk] - wbar[wb + kk]) * z[kk]
		if NG > 0 and zg.size() == NG:
			var bg := i * NG
			var wg := g * NG
			for jg in NG:
				t -= (gw[bg + jg] - gwbar[wg + jg]) * zg[jg]
		var nv: float = off[i] + (t - off[i]) * 0.5
		sum_off[g] += nv - off[i]
		off[i] = nv
		var a: float = clampf(float(sup[g]) + nv - ob[g], 0.0, 100.0)
		# --- окружение: протест заразителен ---
		var pp := 0
		var pa := 0
		var mi := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
		for kq in NPEER:
			var q: int = peers[i * NPEER + kq]
			pp += prot[q]
			pa += act[q]
			for ax in AX:
				mi[ax] += ide[q * AX + ax]
		var thr: float = PROT_AT + (3.0 if pp >= 2 else 0.0) + (2.0 if pa >= 1 else 0.0)
		var pr: int = 1 if a < thr else 0
		var na: int = 1 if (pr == 1 and a < 25.0 and (edu[i] == 2 or age[i] < 32.0 or pa >= 1)) else 0
		var wpr: int = pr * (2 if na == 1 else 1)
		var wold: int = prot[i] * (2 if act[i] == 1 else 1)
		if wpr != wold:
			rprot[reg[i]] += wpr - wold
		prot[i] = pr
		act[i] = na
		tp[i] = turnout_of(i, a)
		# --- взгляды: опыт и окружение (небольшие шаги, якорь — собственные взгляды) ---
		var dx := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
		if emp[i] == 0 and unm[i] >= 6:
			dx[0] -= 0.025                                  # долгая безработица — за соцгарантии
			dx[3] += 0.02 if edu[i] == 0 else 0.0
		if infl > 5.0:
			dx[0] -= 0.012 if (g == 0 or g == 2) else 0.0
			dx[1] += 0.008
		if secl < 45.0:
			dx[1] += 0.02 * (45.0 - secl) / 15.0              # небезопасно — за порядок
		if envl < 45.0 and (age[i] < 40.0 or edu[i] == 2):
			dx[2] += 0.02 * (45.0 - envl) / 15.0              # плохая экология — молодые и образованные зеленеют
		if migr > 0.0:
			dx[3] += migr * (0.02 if edu[i] == 0 else (-0.01 if edu[i] == 2 else 0.005))  # миграция поляризует по образованию
		if trust[i] < 0.3:
			dx[3] += 0.01                                   # недоверие — к антисистемным «суверенистам»
		if a < 35.0:
			dx[1] += 0.006
			dx[3] += 0.008
		if pb[i] > 2.0 and g == 1:
			dx[0] += 0.01                                   # успешный бизнес — за рынок
		for ax2 in AX:
			var peer_m: float = mi[ax2] / float(NPEER)
			dx[ax2] += (peer_m - ide[j + ax2]) * 0.03 + (ide0[j + ax2] - ide[j + ax2]) * (0.03 if a >= 35.0 else 0.018)
			ide[j + ax2] = clampf(ide[j + ax2] + dx[ax2] * months / 4.0, -2.5, 2.5)
		calc_aff(i)
		i += stride
	steps += 1

# подсчёт голосов региона r: out (G*P) копит доли агентов, cnt (G) — число агентов
func tally(r: int, bw: PackedFloat32Array, sup: Array, loyoff: float, e0: float, p0: int, p9: int, stride: int, out: PackedFloat64Array, cnt: PackedInt32Array) -> void:
	var ob := group_offbar()
	for g in G:
		var c := r * G + g
		var s: int = cell_start[c]
		var e: int = cell_start[c + 1]
		if e <= s:
			continue
		var base := g * P
		var tb := 0.0
		for p in P:
			tb += bw[base + p]
		if tb <= 0.0:
			continue
		var eff_c: float = clampf(float(sup[g]) + loyoff, 5.0, 100.0)
		var o0: float = float(sup[g]) - ob[g] + loyoff
		var den9: float = maxf(100.0 - eff_c, 1.0)
		# средние множители ячейки: личный разброс оценок не должен сдвигать итог группы
		var m0 := 0.0
		var m9 := 0.0
		var mc := 0
		var i := s
		while i < e:
			var ei0: float = clampf(o0 + off[i], 5.0, 100.0)
			var q0: float = ei0 / eff_c
			var h0: float = q0 * q0 * q0
			if e0 > 3.5:
				h0 *= q0
			var h9: float = clampf((100.0 - ei0) / den9, 0.2, 3.0)
			m0 += h0
			m9 += h9 * h9
			mc += 1
			i += stride
		m0 = m0 / float(maxi(1, mc))
		m9 = m9 / float(maxi(1, mc))
		# v47_1: явка — голос агента весит пропорционально его склонности голосовать (среднее по ячейке = 1)
		var tps := 0.0
		var tpn := 0
		i = s
		while i < e:
			tps += tp[i]
			tpn += 1
			i += stride
		var tpm: float = maxf(0.05, tps / float(maxi(1, tpn)))
		i = s
		while i < e:
			var ei: float = clampf(o0 + off[i], 5.0, 100.0)
			var q: float = ei / eff_c
			var f0: float = q * q * q
			if e0 > 3.5:
				f0 *= q
			f0 /= m0
			var q9: float = clampf((100.0 - ei) / den9, 0.2, 3.0)
			var ai := i * P
			var tot := 0.0
			for p in P:
				var v: float = bw[base + p] * aff[ai + p]
				tmp[p] = v
				tot += v
			if p0 < P:
				tot += tmp[p0] * (f0 - 1.0)
				tmp[p0] *= f0
			if p9 < P:
				var f9 := q9 * q9 / m9
				tot += tmp[p9] * (f9 - 1.0)
				tmp[p9] *= f9
			if tot > 0.0:
				var inv := tp[i] / tpm / tot
				for p in P:
					out[base + p] += tmp[p] * inv
			cnt[g] += 1
			i += stride

# подгонка симпатий ячейки: aff *= ratio (старт игры совпадает с прежней моделью)
func calib_cell(r: int, g: int, ratio: PackedFloat32Array) -> void:
	var c := r * G + g
	for p in P:
		cellnorm[c * P + p] /= ratio[p]
	for i in range(cell_start[c], cell_start[c + 1]):
		for p in P:
			aff[i * P + p] *= ratio[p]

# статистика по группам
func group_stats(sup: Array) -> Array:
	var ob := group_offbar()
	var res: Array = []
	var acc := PackedFloat64Array()
	acc.resize(G * 8)
	for i in n:
		var g: int = grp[i]
		var a: float = clampf(float(sup[g]) + off[i] - ob[g], 0.0, 100.0)
		var b := g * 8
		acc[b] += a
		acc[b + 1] += float(prot[i])
		acc[b + 2] += float(1 - emp[i])
		acc[b + 3] += age[i]
		acc[b + 4] += inc[i]
		acc[b + 5] += ide[i * AX]
		acc[b + 6] += ide[i * AX + 1]
		acc[b + 7] += a * a
	for g in G:
		var c: float = float(maxi(1, gcount[g]))
		var b := g * 8
		var m: float = acc[b] / c
		res.append({"n": gcount[g], "appr": m, "sd": sqrt(maxf(0.0, acc[b + 7] / c - m * m)), "prot": acc[b + 1] / c, "unemp": acc[b + 2] / c,
			"age": acc[b + 3] / c, "inc": acc[b + 4] / c, "ex": acc[b + 5] / c, "es": acc[b + 6] / c})
	return res

func hist(sup: Array, g: int, bins: int) -> PackedInt32Array:
	var h := PackedInt32Array()
	h.resize(bins)
	var ob := group_offbar()
	for i in n:
		if g >= 0 and grp[i] != g:
			continue
		var a: float = clampf(float(sup[grp[i]]) + off[i] - ob[grp[i]], 0.0, 99.999)
		h[int(a / 100.0 * float(bins))] += 1
	return h

func region_prot(r: int) -> float:
	return float(rprot[r]) / float(maxi(1, rcount[r]))

func favourite(i: int, lean_g: Array, pmul: Array) -> int:
	var best := 0
	var bv := -1.0
	for p in P:
		var v: float = float(lean_g[p]) * aff[i * P + p] * float(pmul[p])
		if v > bv:
			bv = v
			best = p
	return best


# ============================================================
#  НАСЕЛЕНИЕ: подключение агентов к игре
# ============================================================
