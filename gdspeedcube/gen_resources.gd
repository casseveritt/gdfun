@tool
extends EditorScript


@export_file("*.res") var save_path: String = "res://textures/rubik.tres"

func _run():
	print("running resource synthesis script")
	make_rubik_cubemap()

func make_rubik_cubemap():
	var w := 256
	var border := int(w >> 4)
	var rnd := 2 * border
	var cubemap := Cubemap.new()

	var face_color: Array[Color] = [Color.ORANGE_RED, Color.RED, Color.WHITE, Color.YELLOW, Color.BLUE, Color.DARK_GREEN]
	var images = []
	DirAccess.make_dir_absolute("res://textures/")
	for face in 6:
		var img = Image.create_empty(w, w, true, Image.FORMAT_RGBA8)
		var c : Color = face_color[face]
		c.a = 1.0
		img.fill(Color.BLACK)
		img.fill_rect(Rect2i(border, border, w - 2 * border, w - 2 * border), c)

		for i in rnd * 2:
			for j in rnd * 2:
				var fi = i + 0.5 - rnd
				var fj = j + 0.5 - rnd
				var r = sqrt(fi * fi + fj * fj)
				var pi = i + border
				var pj = j + border
				if i >= rnd:
					pi += (w - 2 * (border + rnd))
				if j >= rnd:
					pj += (w - 2 * (border + rnd))
				
				var col = Color.BLACK
				if r > float(rnd):
					img.set_pixel(pi, pj, col)
		
		#img.save_png("res://textures/rubik" + str(face) + ".png")
		img.generate_mipmaps()
		images.push_back(img)
	cubemap.create_from_images(images)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://piece.gdshader")
	sm.set_shader_parameter("texcube", cubemap)
	ResourceSaver.save(sm, "res://rubik_mat.tres")
