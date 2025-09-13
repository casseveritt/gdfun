@tool
extends Node3D

@onready var piece : ArrayMesh = load("res://piece.tres")
@onready var mat : ShaderMaterial = load("res://rubik_mat.tres")
var rc : Array

func _ready() -> void:
	self.scale *= 1.0
	var piece_scale = 0.333;
	mat.set_shader_parameter("piece_scale", piece_scale)
	for i in 3:
		for j in 3:
			for k in 3:
				var mi := MeshInstance3D.new()
				mi.scale *= piece_scale * 0.8
				mi.mesh = piece.duplicate()
				mi.material_override = mat
				mi.position += (Vector3(i, j, k) - Vector3(1, 1, 1)) * piece_scale
				var idx = i + j * 4 + k * 16
				mi.set_instance_shader_parameter("piece_idx", idx)
				mi.set_instance_shader_parameter("piece_bias", mi.position)
				rc.append(mi)
				self.add_child(mi)
