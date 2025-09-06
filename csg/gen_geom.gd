@tool
extends EditorScript

class SurfTool:
	extends SurfaceTool
	var vertex_count := 0
	
	func add_vert(vertex):
		super.add_vertex(vertex)
		vertex_count += 1

# This script generates the inset faces of a cube and adds a spherical octant to the +X, +Y, +Z corner,
# ensuring the octant aligns perfectly with the inset face corners and is oriented correctly.

func _run():
	var size = 1.0  # Full size of the cube
	var radius = 0.075  # Radius of the spherical corner
	
	var mesh = generate_rounded_cube_mesh(size, radius)
	var error = ResourceSaver.save(mesh, "res://mesh.tres")
	if error != OK:
		push_error("Failed to save mesh resource. Error code: " + str(error))
	else:
		print("Mesh saved successfully to res://mesh.tres")

func generate_rounded_cube_mesh(size, radius):
	var st = SurfTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate the inset faces
	generate_inset_faces(st, size, radius)
	
	generate_edge_facets(st)

	generate_corner_facets(st)

	st.generate_normals()
	return st.commit()

func generate_inset_faces(st, size, radius):
	var half_size = size / 2.0
	var core_half_size = half_size - radius  # Inset size
	
	var faces = [
		Vector3(-1, 0, 0), # -X
		Vector3(1, 0, 0),  # +X
		Vector3(0, -1, 0), # -Y
		Vector3(0, 1, 0),  # +Y
		Vector3(0, 0, -1), # -Z
		Vector3(0, 0, 1),  # +Z
	]
	
	for normal in faces:
		var face_center = normal * half_size
		add_inset_face(st, face_center, normal, core_half_size)

func add_inset_face(st : SurfTool, center, normal : Vector3, scale):
	var unit_square = [
		Vector3(-1, -1, 0),
		Vector3(1, -1, 0),
		Vector3(-1, 1, 0),
		Vector3(1, 1, 0),
	]
	
	for i in range(unit_square.size()):
		unit_square[i] *= scale
	
	var rotation = Quaternion(Vector3(0, 0, 1), normal)
	if normal.z == -1.0:
		rotation = Quaternion(Vector3(0, 1, 0), PI)
	var basis = Basis(rotation)
	
	for i in range(unit_square.size()):
		unit_square[i] = basis * unit_square[i] + center

	var vert_count = st.vertex_count
	
	st.add_vert(unit_square[0])
	st.add_vert(unit_square[1])
	st.add_vert(unit_square[2])
	st.add_vert(unit_square[3])

	st.add_index(vert_count + 0)
	st.add_index(vert_count + 2)
	st.add_index(vert_count + 1)

	st.add_index(vert_count + 3)
	st.add_index(vert_count + 1)
	st.add_index(vert_count + 2)

enum Face {
	XN, # -X
	XP, # +X
	YN, # -Y
	YP, # +Y
	ZN, # -Z
	ZP  # +Z
	}

func face_index(face : Face, idx : int):
	return int(face) * 4 + idx

func edge_index(edge : int, idx : int):
	# edge order: -X +X -Y +Y
	# vertex order:  2 3
	#                0 1
	const edge_idx = [ [0, 2], [3, 1], [1, 0], [2, 3]]
	return edge_idx[edge][idx]

func gen_facet(st, f0 : Face, f1 : Face, f0e : int, f1e : int):
	st.add_index(face_index(f0, edge_index(f0e, 0)))
	st.add_index(face_index(f1, edge_index(f1e, 1)))
	st.add_index(face_index(f0, edge_index(f0e, 1)))

	st.add_index(face_index(f1, edge_index(f1e, 0)))
	st.add_index(face_index(f0, edge_index(f0e, 1)))
	st.add_index(face_index(f1, edge_index(f1e, 1)))

func generate_edge_facets(st):
	gen_facet(st, Face.XN, Face.ZP, 1, 0)
	gen_facet(st, Face.ZP, Face.XP, 1, 0)
	gen_facet(st, Face.XP, Face.ZN, 1, 0)
	gen_facet(st, Face.ZN, Face.XN, 1, 0)

	gen_facet(st, Face.ZP, Face.YP, 3, 2)
	gen_facet(st, Face.YP, Face.ZN, 3, 3)
	gen_facet(st, Face.ZN, Face.YN, 2, 2)
	gen_facet(st, Face.YN, Face.ZP, 3, 2)
	
	gen_facet(st, Face.XN, Face.YP, 3, 0)
	gen_facet(st, Face.YP, Face.XP, 1, 3)
	gen_facet(st, Face.XP, Face.YN, 2, 1)
	gen_facet(st, Face.YN, Face.XN, 0, 2)

func generate_corner_facets(st):
	st.add_index(face_index(Face.XN, 0))
	st.add_index(face_index(Face.YN, 0))
	st.add_index(face_index(Face.ZN, 1))

	st.add_index(face_index(Face.XP, 1))
	st.add_index(face_index(Face.ZN, 0))
	st.add_index(face_index(Face.YN, 1))

	st.add_index(face_index(Face.XN, 2))
	st.add_index(face_index(Face.ZN, 3))
	st.add_index(face_index(Face.YP, 2))

	st.add_index(face_index(Face.XP, 3))
	st.add_index(face_index(Face.YP, 3))
	st.add_index(face_index(Face.ZN, 2))

	st.add_index(face_index(Face.XN, 1))
	st.add_index(face_index(Face.ZP, 0))
	st.add_index(face_index(Face.YN, 2))

	st.add_index(face_index(Face.XP, 0))
	st.add_index(face_index(Face.YN, 3))
	st.add_index(face_index(Face.ZP, 1))

	st.add_index(face_index(Face.XN, 3))
	st.add_index(face_index(Face.YP, 0))
	st.add_index(face_index(Face.ZP, 2))

	st.add_index(face_index(Face.XP, 2))
	st.add_index(face_index(Face.ZP, 3))
	st.add_index(face_index(Face.YP, 1))
