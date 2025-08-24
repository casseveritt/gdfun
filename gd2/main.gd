class_name Main
extends Node3D

static var time := 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			get_tree().quit()

func _process(delta: float) -> void:
	time += delta
