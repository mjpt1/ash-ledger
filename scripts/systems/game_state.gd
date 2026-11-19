extends Node

## Global run + meta progress for Ash Ledger.

signal meta_changed
signal chapter_unlocked(chapter_id: String)

const CHAPTER_ORDER: Array[String] = ["01", "02", "03", "04", "05"]

var ash: int = 0
var highest_chapter: String = "01"
var last_choice: String = ""
var pending_story_chapter: String = ""
var run_won: bool = false

## Permanent meta upgrades (0–5 each).
var meta_hp: int = 0
var meta_damage: int = 0
var meta_orbit: int = 0

func reset_run_flags() -> void:
	run_won = false
	pending_story_chapter = ""

func base_max_hp() -> int:
	return 100 + meta_hp * 20

func base_damage() -> float:
	return 10.0 + meta_damage * 3.0

func start_with_orbit() -> bool:
	return meta_orbit > 0

func meta_cost(level: int) -> int:
	return 15 + level * 20

func can_buy_meta(stat: String) -> bool:
	var level := _meta_level(stat)
	if level >= 5:
		return false
	return ash >= meta_cost(level)

func buy_meta(stat: String) -> bool:
	if not can_buy_meta(stat):
		return false
	var level := _meta_level(stat)
	ash -= meta_cost(level)
	match stat:
		"hp":
			meta_hp += 1
		"damage":
			meta_damage += 1
		"orbit":
			meta_orbit += 1
		_:
			return false
	meta_changed.emit()
	SaveSystem.save_game()
	return true

func _meta_level(stat: String) -> int:
	match stat:
		"hp":
			return meta_hp
		"damage":
			return meta_damage
		"orbit":
			return meta_orbit
	return 0

func add_ash(amount: int) -> void:
	ash += maxi(amount, 0)
	meta_changed.emit()
	SaveSystem.save_game()

func is_chapter_unlocked(chapter_id: String) -> bool:
	return CHAPTER_ORDER.find(chapter_id) <= CHAPTER_ORDER.find(highest_chapter)

func unlock_next_after(chapter_id: String) -> void:
	var idx := CHAPTER_ORDER.find(chapter_id)
	if idx < 0:
		return
	if idx + 1 < CHAPTER_ORDER.size():
		var nxt: String = CHAPTER_ORDER[idx + 1]
		if CHAPTER_ORDER.find(nxt) > CHAPTER_ORDER.find(highest_chapter):
			highest_chapter = nxt
			chapter_unlocked.emit(nxt)
			SaveSystem.save_game()

func mark_run_victory(chapter_id: String) -> void:
	run_won = true
	pending_story_chapter = chapter_id
	add_ash(25 + CHAPTER_ORDER.find(chapter_id) * 10)

func mark_run_defeat() -> void:
	run_won = false
	pending_story_chapter = ""
	add_ash(5)

func to_dict() -> Dictionary:
	return {
		"ash": ash,
		"highest_chapter": highest_chapter,
		"last_choice": last_choice,
		"meta_hp": meta_hp,
		"meta_damage": meta_damage,
		"meta_orbit": meta_orbit,
	}

func from_dict(data: Dictionary) -> void:
	ash = int(data.get("ash", 0))
	highest_chapter = str(data.get("highest_chapter", "01"))
	last_choice = str(data.get("last_choice", ""))
	meta_hp = int(data.get("meta_hp", 0))
	meta_damage = int(data.get("meta_damage", 0))
	meta_orbit = int(data.get("meta_orbit", 0))
