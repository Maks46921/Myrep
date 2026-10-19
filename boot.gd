# v39: точка входа. Загружает русскую (res://main.gd) или английскую (res://en/main.gd) версию игры —
# английская собирается tools/i18n.py build. Язык хранится в user://settings.cfg.
extends Control

const CFG := "user://settings.cfg"
const LANGS := [["ru", "Русский"], ["en", "English"]]


static func lang() -> String:
	var c := ConfigFile.new()
	if c.load(CFG) == OK:
		return String(c.get_value("game", "lang", "ru"))
	return "ru" if OS.get_locale_language() == "ru" else "en"


static func set_lang(l: String) -> void:
	var c := ConfigFile.new()
	c.load(CFG)
	c.set_value("game", "lang", l)
	c.save(CFG)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# v55_2: заставка с логотипом «Купол» держится, пока грузится игра (загрузка main.gd занимает несколько секунд)
	var bg := ColorRect.new()
	bg.color = Color(0.067, 0.082, 0.118)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var sp := TextureRect.new()
	sp.texture = load("res://splash.png")
	sp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(sp)
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "res://main.gd"
	if lang() == "en" and ResourceLoader.exists("res://en/main.gd"):
		path = "res://en/main.gd"
	var m: Control = load(path).new()
	m.name = "Game"
	add_child(m)
	bg.queue_free()
	sp.queue_free()
