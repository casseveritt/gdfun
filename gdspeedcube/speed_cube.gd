@tool
extends Node3D

@onready var piece : ArrayMesh = load("res://piece.tres")
@onready var mat : ShaderMaterial = load("res://rubik_mat.tres")
var rc : Array

func _ready() -> void:
	
	for i in 3:
		for j in 3:
			for k in 3:
				var mi := MeshInstance3D.new()
				mi.mesh = piece.duplicate()
				mi.material_override = mat
				mi.position += (Vector3(i, j, k) - Vector3(1, 1, 1))
				rc.append(mi)
				self.add_child(mi)
