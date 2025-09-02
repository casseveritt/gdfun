@tool
extends Node3D

@onready var piece = $Piece

var rc : Array

func _ready() -> void:
	for i in 3:
		for j in 3:
			for k in 3:
				var p : CSGBox3D = piece.duplicate()
				p.position += p.size * (Vector3(i, j, k) - Vector3(1, 1, 1))
				rc.append(p)
				self.add_child(p)
	self.remove_child(piece)
