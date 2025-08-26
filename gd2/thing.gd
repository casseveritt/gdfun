extends Node3D

@onready var sphere : CSGSphere3D = $Sphere
@onready var box_neg_x : CSGBox3D = $BoxNegX
@onready var box_pos_x : CSGBox3D = $BoxPosX

@onready var sphere_cld : CollisionShape3D = $SphereCld

var entered_material := StandardMaterial3D.new()

func _ready():
	entered_material.albedo_color = Color.YELLOW
	update_dependent()

func _process(_delta: float) -> void:
	sphere.radius = 0.5 * (0.5 * cos(Main.time * PI / 10) + 0.5)
	update_dependent()

func enter_child(child: GeometryInstance3D):
	child.material = entered_material

func exit_child(child: GeometryInstance3D):
	child.material = null

func update_dependent():
	box_neg_x.position.x = -(sphere.radius + box_neg_x.size.x / 2.0)
	box_pos_x.position.x = sphere.radius + box_pos_x.size.x / 2.0
