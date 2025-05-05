extends Area2D

signal wind_started
signal wind_ended

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is CharacterBody2D:
		emit_signal("wind_started")

func _on_body_exited(body):
	if body is CharacterBody2D:
		emit_signal("wind_ended")
