extends Node2D



func _on_StartButton_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

const SAVE_PATH = "user://save.cfg"
func _on_ResetButton_pressed() -> void:
	var cfg = ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("score","high_score",0)
	cfg.save(SAVE_PATH)
	$CanvasLayer/VBoxContainer/ResetButton.text = "Highscore Reset!"
