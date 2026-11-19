extends Node

const STORY_DIR := "res://content/story/"

func list_chapters() -> Array[String]:
	var ids: Array[String] = []
	for id in GameState.CHAPTER_ORDER:
		ids.append(id)
	return ids

func load_chapter(chapter_id: String) -> Dictionary:
	var path := "%schapter_%s.json" % [STORY_DIR, chapter_id]
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		push_error("Missing story chapter: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open story chapter: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON in %s" % path)
		return {}
	return parsed

func chapter_title(chapter_id: String) -> String:
	var data := load_chapter(chapter_id)
	return str(data.get("title", "Chapter %s" % chapter_id))
