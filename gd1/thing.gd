extends Node3D

@onready var sphere : CSGSphere3D = $Sphere
@onready var box_l : CSGBox3D = $BoxL
@onready var box_r : CSGBox3D = $BoxR
@onready var base_radius = sphere.radius

func _ready() -> void:
	update_dependent()

func _process(delta: float) -> void:
	sphere.radius = base_radius + abs(cos(Main.time))
	update_dependent()

func update_dependent():
	box_l.position.x = -(sphere.radius + box_l.size.x / 2.0)
	box_r.position.x = sphere.radius + box_r.size.x / 2.0
