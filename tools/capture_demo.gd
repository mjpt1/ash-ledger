extends Node

## One-shot demo capture: menu → hub → story → run, save PNGs, quit.

const OUT_DIR := "res://export/demo"
const WAIT := 0.9

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	# Seed a bit of progress so hub/story look alive
	GameState.ash = 40
	GameState.highest_chapter = "02"
	GameState.pending_story_chapter = "01"
	GameState.run_won = false
	await _capture_scene("res://scenes/ui/main_menu.tscn", "01_main_menu.png")
	await _capture_scene("res://scenes/ui/hub.tscn", "02_hub.png")
	await _capture_scene("res://scenes/ui/story_reader.tscn", "03_story.png")
	GameState.pending_story_chapter = "01"
	await _capture_scene("res://scenes/run/run.tscn", "04_run.png")
	print("DEMO_CAPTURE_DONE")
	get_tree().quit()

func _capture_scene(path: String, filename: String) -> void:
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	# Let tweens / spawns settle
	await get_tree().create_timer(WAIT).timeout
	# On run, advance a moment so enemies exist
	if path.ends_with("run.tscn"):
		await get_tree().create_timer(1.2).timeout
	var img: Image = get_viewport().get_texture().get_image()
	var out_path := "%s/%s" % [OUT_DIR, filename]
	var abs_path := ProjectSettings.globalize_path(out_path)
	img.save_png(abs_path)
	print("SAVED ", abs_path)
