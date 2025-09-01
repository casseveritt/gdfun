@tool
extends Node3D

@onready var piece = $Piece0

func _ready() -> void:
	var cube = Cubemap.new()
	var imgs : Array[Image]
	for i in 6:
		var img = Image.load_from_file("res://textures/rubik" + str(i) + ".png")
		img.generate_mipmaps()
		imgs.push_back(img)
	
	cube.create_from_images(imgs)
	var m : ShaderMaterial = piece.material
	m.set_shader_parameter("texcube", cube)
