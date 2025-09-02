extends Node3D

@onready var cam = $Camera3D

const CAM_MOV_INCR := 0.01
const CAM_ROT_INCR := 0.01

func incr_rotation(b : Basis, axis : Vector3, incr : float):
	var q = b.get_rotation_quaternion()
	var q_incr = Quaternion(axis, incr)
	return Basis(q * q_incr)

func _process(delta: float) -> void:
	if Input.is_action_pressed("quit"):
		get_tree().quit()
	var b : Basis = cam.basis
	if Input.is_action_pressed("cam_mov_fwd"):
		cam.position -= b.z * CAM_MOV_INCR
	if Input.is_action_pressed("cam_mov_left"):
		cam.position -= b.x * CAM_MOV_INCR
	if Input.is_action_pressed("cam_mov_back"):
		cam.position += b.z * CAM_MOV_INCR
	if Input.is_action_pressed("cam_mov_right"):
		cam.position += b.x * CAM_MOV_INCR
	if Input.is_action_pressed("cam_mov_down"):
		cam.position -= b.y * CAM_MOV_INCR
	if Input.is_action_pressed("cam_mov_up"):
		cam.position += b.y * CAM_MOV_INCR
		
	if Input.is_action_pressed("cam_rot_left"):
		cam.basis = incr_rotation(cam.basis, Vector3(0.0, 1.0, 0.0), CAM_ROT_INCR)
	if Input.is_action_pressed("cam_rot_right"):
		cam.basis = incr_rotation(cam.basis, Vector3(0.0, 1.0, 0.0), -CAM_ROT_INCR)
	if Input.is_action_pressed("cam_rot_down"):
		cam.basis = incr_rotation(cam.basis, Vector3(1.0, 0.0, 0.0), -CAM_ROT_INCR)
	if Input.is_action_pressed("cam_rot_up"):
		cam.basis = incr_rotation(cam.basis, Vector3(1.0, 0.0, 0.0), CAM_ROT_INCR)
