extends Node

const SAVE_PATH := "user://ash_ledger_save.json"

func _ready() -> void:
	# Defer so GameState autoload exists regardless of order.
	call_deferred("load_game")

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(GameState.to_dict(), "\t"))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		GameState.from_dict(parsed)

func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
