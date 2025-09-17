@tool
class_name SpeedCube
extends Node3D

class Piece:
	extends Node3D

	var quat : Quaternion
	var piece_scale : float
	var mi : MeshInstance3D
	var gap : float
	var idx : Vector3i

	func to_cube_from_index() -> Vector3:
		return Vector3(idx) * piece_scale

	func update_position() -> void:
		transform = Transform3D(Basis(quat))

	func _init(piece_scale_ : float, gap_ : float, mat : ShaderMaterial, idx_ : Vector3i) -> void:
		quat = Quaternion.IDENTITY
		piece_scale = piece_scale_
		gap = gap_
		idx = idx_
		const base_piece : ArrayMesh = preload("res://piece.tres")
		mi = MeshInstance3D.new()
		mi.scale = Vector3(1, 1, 1) * piece_scale * (1.0 - gap)
		mi.mesh = base_piece.duplicate()
		mi.material_override = mat
		mi.position = to_cube_from_index()
		mi.set_instance_shader_parameter("piece_bias", mi.position)
		add_child(mi)

var rc : Array[Piece]
var cube : Array[int]

func idx1_from_idx3(idx3: Vector3i) -> int:
	var zidx = idx3 + Vector3i(1, 1, 1)
	return zidx.x + 3 * zidx.y + 9 * zidx.z

func idx3_from_idx1(idx1: int) -> Vector3i:
	@warning_ignore("integer_division")
	return Vector3i(idx1 % 3, (idx1 / 3) % 3, idx1 / 9) - Vector3i(1, 1, 1)

enum Axis {
	X = 0,
	Y = 1,
	Z = 2
}

func move(axis: Axis, slice: int, turns: int):
	if slice < -1 or 1 < slice:
		return
	if abs(turns) != 1:
		return
	var cube2 = cube.duplicate()
	if axis == Axis.X:
		var q_fwd := Quaternion(Vector3(1, 0, 0), turns * PI * 0.5)
		var q_back := q_fwd.inverse()
		var b: Basis = q_back
		for j in range(-1, 2):
			for k in range(-1, 2):
				var target = Vector3i(slice, j, k)
				# The * 1.1 because 0.999 gets truncated to 0
				# and floating point math is a little wobbly.
				var source = Vector3i(b * (Vector3(target) * 1.1))
				var piece_idx = cube2[idx1_from_idx3(source)]
				cube[idx1_from_idx3(target)] = piece_idx
				var piece = rc[piece_idx]
				piece.quat =  q_fwd * piece.quat
				piece.update_position()
	elif axis == Axis.Y:
		var q_fwd := Quaternion(Vector3(0, 1, 0), turns * PI * 0.5)
		var q_back := q_fwd.inverse()
		var b: Basis = q_back
		for i in range(-1, 2):
			for k in range(-1, 2):
				var target = Vector3i(i, slice, k)
				# The * 1.1 because 0.999 gets truncated to 0
				# and floating point math is a little wobbly.
				var source = Vector3i(b * (Vector3(target) * 1.1))
				var piece_idx = cube2[idx1_from_idx3(source)]
				cube[idx1_from_idx3(target)] = piece_idx
				var piece = rc[piece_idx]
				piece.quat = q_fwd * piece.quat
				piece.update_position()
	elif axis == Axis.Z:
		var q_fwd := Quaternion(Vector3(0, 0, 1), turns * PI * 0.5)
		var q_back := q_fwd.inverse()
		var b: Basis = q_back
		for i in range(-1, 2):
			for j in range(-1, 2):
				var target = Vector3i(i, j, slice)
				# The * 1.1 because 0.999 gets truncated to 0
				# and floating point math is a little wobbly.
				var source = Vector3i(b * (Vector3(target) * 1.1))
				var piece_idx = cube2[idx1_from_idx3(source)]
				cube[idx1_from_idx3(target)] = piece_idx
				var piece = rc[piece_idx]
				piece.quat = q_fwd * piece.quat
				piece.update_position()

func _ready() -> void:

	cube = []

	self.scale = Vector3(1, 1, 1) * 0.15
	var piece_scale = 0.333;
	var mat : ShaderMaterial = load("res://rubik_mat.tres")
	mat.set_shader_parameter("piece_scale", piece_scale)
	var count := 0
	for k in 3:
		for j in 3:
			for i in 3:
				var idx3 = Vector3i(i, j, k) - Vector3i(1, 1, 1)
				var piece := Piece.new(piece_scale, 0.2, mat, idx3)
				rc.append(piece)
				var idx1 = idx1_from_idx3(idx3)
				cube.append(idx1)
				assert(idx1 == count)
				count += 1
				self.add_child(piece)
	move(Axis.X, -1, 1)
	move(Axis.Y, 1, 1)
	move(Axis.Z, 1, 1)
