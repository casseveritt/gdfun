extends Node3D

@onready var cam = $Camera3D

const CAM_MOV_INCR := 0.01

func _process(delta: float) -> void:
	if Input.is_action_pressed("quit"):
		get_tree().quit()
	if Input.is_action_pressed("cam_mov_fwd"):
		cam.position.z -= CAM_MOV_INCR
	if Input.is_action_pressed("cam_mov_left"):
		cam.position.x -= CAM_MOV_INCR
	if Input.is_action_pressed("cam_mov_back"):
		cam.position.z += CAM_MOV_INCR
	if Input.is_action_pressed("cam_mov_right"):
		cam.position.x += CAM_MOV_INCR
	if Input.is_action_pressed("cam_mov_down"):
		cam.position.y -= CAM_MOV_INCR
	if Input.is_action_pressed("cam_mov_up"):
		cam.position.y += CAM_MOV_INCR
