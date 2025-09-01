@tool
extends EditorScript


@export_file("*.res") var save_path: String = "res://textures/rubik.tres"

func _run():
	print("CASS: - running the script")
	make_rubik_cubemap()

func make_rubik_cubemap():
	var w := 64
	var border := 4
	var round := 8
	var cubemap := Cubemap.new()

	var face_color: Array[Color] = [Color.RED, Color.ORANGE, Color.YELLOW, Color.WHITE, Color.DARK_GREEN, Color.BLUE]
	var images = []
	DirAccess.make_dir_absolute("res://textures/")
	for face in 6:
		var img = Image.create_empty(w, w, true, Image.FORMAT_RGBA8)
		var c : Color = face_color[face]
		c.a = 1.0
		img.fill(Color.BLACK)
		img.fill_rect(Rect2i(border, border, w - 2 * border, w - 2 * border), c)

		for i in round * 2:
			for j in round * 2:
				var fi = i + 0.5 - round
				var fj = j + 0.5 - round
				var r = sqrt(fi * fi + fj * fj)
				var pi = i + border
				var pj = j + border
				if i >= round:
					pi += (w - 2 * (border + round))
				if j >= round:
					pj += (w - 2 * (border + round))
				
				var col = Color.BLACK
				if r > float(round):
					img.set_pixel(pi, pj, col)
		
		img.save_png("res://textures/rubik" + str(face) + ".png")
		img.generate_mipmaps()
		images.push_back(img)
	var err = cubemap.create_from_images(images)
	print("cass: ", err)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://piece.gdshader")
	sm.set_shader_parameter("texcube", cubemap)
	ResourceSaver.save(sm, "res://rubik_mat.tres")
