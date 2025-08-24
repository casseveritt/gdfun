extends Node3D

@onready var sphere : CSGSphere3D = $Sphere
@onready var box_neg_x : CSGBox3D = $BoxNegX
@onready var box_pos_x : CSGBox3D = $BoxPosX

func _ready():
	update_dependent()

func _process(delta: float) -> void:
	sphere.radius = 0.5 * (0.5 * cos(Main.time * PI) + 0.5)
	update_dependent()

func update_dependent():
	box_neg_x.position.x = -(sphere.radius + box_neg_x.size.x / 2.0)
	box_pos_x.position.x = sphere.radius + box_pos_x.size.x / 2.0
