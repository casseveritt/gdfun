@tool
extends Node3D

var rc : Array

class Piece:
	extends MeshInstance3D

	var piece_scale : float
	var gap : float
	var idx : Vector3i

	func _init(piece_scale_ : float, gap_ : float, mat : ShaderMaterial, idx_ : Vector3i) -> void:
		piece_scale = piece_scale_
		gap = gap_
		idx = idx_
		scale = Vector3(1, 1, 1) * piece_scale * (1.0 - gap)
		const piece : ArrayMesh = preload("res://piece.tres")
		mesh = piece.duplicate()
		material_override = mat
		position = (Vector3(idx) - Vector3(1, 1, 1)) * piece_scale
		set_instance_shader_parameter("piece_bias", position)


func _ready() -> void:
	self.scale *= 1.0
	var piece_scale = 0.333;
	var mat : ShaderMaterial = load("res://rubik_mat.tres")
	mat.set_shader_parameter("piece_scale", piece_scale)
	for i in 3:
		for j in 3:
			for k in 3:
				var piece := Piece.new(piece_scale, 0.2, mat, Vector3i(i, j, k))
				rc.append(piece)
				self.add_child(piece)
