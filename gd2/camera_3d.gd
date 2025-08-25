extends Camera3D

@export var mouse_sensitivity: float = 0.002
@export var move_speed: float = 5.0

var rotation_x: float = 0.0
var rotation_y: float = 0.0

func _ready():
		rotation.x = rotation_x
		rotation.y = rotation_y

func _input(event):
	var cam_rot = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.is_key_pressed(KEY_SHIFT)
	if cam_rot:
		if event is InputEventMouseMotion:
			rotation_y -= event.relative.x * mouse_sensitivity
			rotation_x -= event.relative.y * mouse_sensitivity
			rotation_x = clamp(rotation_x, deg_to_rad(-90), deg_to_rad(90)) # Clamp vertical rotation
			rotation.y = rotation_y
			rotation.x = rotation_x

func _process(delta):
		var direction = Vector3.ZERO
		var b = global_transform.basis
		if Input.is_key_pressed(KEY_W):
			direction += b.y
		if Input.is_key_pressed(KEY_A):
			direction -= b.x
		if Input.is_key_pressed(KEY_S):
			direction -= b.y
		if Input.is_key_pressed(KEY_D):
			direction += b.x

		# Normalize direction to prevent faster diagonal movement
		if direction.length() > 1.0:
				direction = direction.normalized()

		global_translate(direction * move_speed * delta)
