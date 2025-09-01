class_name Main
extends Node3D

static var time = 0.0

func _process(delta: float) -> void:
	time += delta

func _input(event):
	if event is InputEventKey:
		var k = (event as InputEventKey)
		if k.keycode == KEY_ESCAPE:
			print("Escape!")
			get_tree().quit()
