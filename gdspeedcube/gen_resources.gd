@tool
extends EditorScript


@export_file("*.res") var save_path: String = "res://textures/rubik.tres"

func _run():
	print("CASS: - running the script")
	make_rubik_cubemap()

func make_rubik_cubemap():
	var w := 64
	var cubemap := Cubemap.new()

	var face_color: Array[Color] = [Color.RED, Color.ORANGE, Color.YELLOW, Color.WHITE, Color.DARK_GREEN, Color.BLUE]
	var images = []
	DirAccess.make_dir_absolute("res://textures/")
	for face in 6:
		var img = Image.create_empty(w, w, true, Image.FORMAT_RGBA8)
		var c : Color = face_color[face]
		c.a = 1.0
		img.fill(Color.BLACK)
		img.fill_rect(Rect2i(4, 4, 56, 56), c)
		
		img.save_png("res://textures/rubik" + str(face) + ".png")
		img.generate_mipmaps()
		images.push_back(img)
	#var err = cubemap.create_from_images(images)
	var err
	err = ResourceSaver.save(cubemap, save_path)
