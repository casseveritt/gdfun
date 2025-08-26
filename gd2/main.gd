class_name Main
extends Node3D

static var time := 0.0
@onready var camera : Camera3D = $Camera3D
var mouse_pos
var hit = null

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			get_tree().quit()

	if event is InputEventMouseMotion:
		mouse_pos = event.position

func _process(delta: float) -> void:
	time += delta

func _physics_process(_delta: float) -> void:
	if mouse_pos:
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * 1000
		var space_state = get_world_3d().direct_space_state
		var rp := PhysicsRayQueryParameters3D.new()
		rp.from = from
		rp.to = to
		var result = space_state.intersect_ray(rp)
		var obj = null
		if result:
			obj = result.collider
		if obj != hit:
			if hit:
				hit.get_parent().exit_child(hit)
			if obj:
				print(result)
				obj.get_parent().enter_child(obj)
			hit = obj
