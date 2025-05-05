extends Area2D

signal landing_window_opened
signal landing_window_closed

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is CharacterBody2D:
		emit_signal("landing_window_opened")

func _on_body_exited(body):
	if body is CharacterBody2D:
		emit_signal("landing_window_closed")
