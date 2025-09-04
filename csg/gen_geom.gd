@tool
extends EditorScript

class Vertex:
	var pos: Vector3
	var edges = []
	var faces = []
	var id: int

class Edge:
	var v1: Vertex
	var v2: Vertex
	var faces = []
	var sharpness: float = 0.0 # 0 = smooth, 1 = sharp, between is semi-sharp

class Face:
	var verts = []
	var edges = []
	var id: int

# Utility: Lerp between two vectors
func lerp(a: Vector3, b: Vector3, t: float) -> Vector3:
	return a * (1.0 - t) + b * t

# Build cube topology
func generate_cube_topology() -> Dictionary:
	var verts = []
	var edges = []
	var faces = []
	var vert_map = {}
	var edge_map = {}

	var cube_vertices = [
		Vector3(-1, -1, -1),
		Vector3( 1, -1, -1),
		Vector3( 1,  1, -1),
		Vector3(-1,  1, -1),
		Vector3(-1, -1,  1),
		Vector3( 1, -1,  1),
		Vector3( 1,  1,  1),
		Vector3(-1,  1,  1),
	]
	# Faces as lists of 4 vertex indices (quads)
	var cube_faces = [
		[0, 1, 2, 3], # Bottom (-Z)
		[4, 5, 6, 7], # Top (+Z)
		[0, 1, 5, 4], # Front (-Y)
		[2, 3, 7, 6], # Back (+Y)
		[0, 3, 7, 4], # Left (-X)
		[1, 2, 6, 5], # Right (+X)
	]

	# Create vertex objects
	for i in cube_vertices.size():
		var v = Vertex.new()
		v.pos = cube_vertices[i]
		v.id = i
		verts.append(v)
		vert_map[i] = v

	# Create faces and edges, build connectivity
	for fi in cube_faces.size():
		var face_indices = cube_faces[fi]
		var f = Face.new()
		f.id = fi
		for i in range(4):
			var vi = face_indices[i]
			f.verts.append(vert_map[vi])
			vert_map[vi].faces.append(f)
		# Add edges per face, avoid duplicates
		for i in range(4):
			var vi1 = face_indices[i]
			var vi2 = face_indices[(i+1)%4]
			var edge_key = [min(vi1,vi2), max(vi1,vi2)]
			var edge_key_str = str(edge_key)
			var edge
			if edge_map.has(edge_key_str):
				edge = edge_map[edge_key_str]
			else:
				edge = Edge.new()
				edge.v1 = vert_map[edge_key[0]]
				edge.v2 = vert_map[edge_key[1]]
				edge_map[edge_key_str] = edge
				edges.append(edge)
				edge.v1.edges.append(edge)
				edge.v2.edges.append(edge)
			edge.faces.append(f)
			f.edges.append(edge)
		faces.append(f)

	# Example: Mark all cube edges semi-sharp (0.5)
	# You can customize sharpness per edge here
	for edge in edges:
		edge.sharpness = 0.5

	return {
		"vertices": verts,
		"edges": edges,
		"faces": faces
	}

# One iteration of Catmull-Clark subdivision (returns new mesh topology)
func catmull_clark_subdivide(mesh_topo: Dictionary) -> Dictionary:
	var old_verts = mesh_topo["vertices"]
	var old_edges = mesh_topo["edges"]
	var old_faces = mesh_topo["faces"]

	var face_points = []
	var edge_points = {}
	var vertex_points = []

	# 1. Compute face points
	for f in old_faces:
		var avg = Vector3.ZERO
		for v in f.verts:
			avg += v.pos
		avg /= f.verts.size()
		face_points.append(avg)

	# 2. Compute edge points
	for e in old_edges:
		var fp_sum = Vector3.ZERO
		for f in e.faces:
			fp_sum += face_points[old_faces.find(f)]
		fp_sum /= e.faces.size()
		var ep = (e.v1.pos + e.v2.pos + fp_sum) / (2 + e.faces.size())
		# Semi-sharp: interpolate between Catmull-Clark and sharp (just edge midpoint)
		if e.sharpness > 0.0:
			var sharp_ep = (e.v1.pos + e.v2.pos) * 0.5
			ep = lerp(ep, sharp_ep, e.sharpness)
		edge_points[e] = ep

	# 3. Compute new vertex points
	for v in old_verts:
		# Face points
		var F = Vector3.ZERO
		for f in v.faces:
			F += face_points[old_faces.find(f)]
		F /= v.faces.size()
		# Edge midpoints
		var R = Vector3.ZERO
		for e in v.edges:
			R += edge_points[e]
		R /= v.edges.size()
		# Original position
		var n = v.faces.size()
		var new_v = (F + 2*R + (n-3)*v.pos) / n
		# Semi-sharp: if any adjacent edge is sharp, interpolate to original pos
		var max_sharp = 0.0
		for e in v.edges:
			max_sharp = max(max_sharp, e.sharpness)
		if max_sharp > 0.0:
			new_v = lerp(new_v, v.pos, max_sharp)
		vertex_points.append(new_v)

	# Build new topology
	# For each old face, create 4 new faces (quads)
	# Each quad is made from: old vertex, two edge points, face point

	var new_vertices = []
	var new_faces = []
	var vertex_map = {} # Map for deduplication

	# Helper to get or create vertex
	var get_vertex = func(pos: Vector3) -> int:
		var key = str(pos)
		if vertex_map.has(key):
			return vertex_map[key]
		var idx = new_vertices.size()
		new_vertices.append(pos)
		vertex_map[key] = idx
		return idx

	# Store new quads as indices into new_vertices
	var new_quads = []

	for fi in old_faces.size():
		var f = old_faces[fi]
		var fp = face_points[fi]
		for i in range(f.verts.size()):
			var v0 = f.verts[i]
			var v1 = f.verts[(i+1)%f.verts.size()]
			var e0 = f.edges[i]
			var e1 = f.edges[(i-1+f.edges.size())%f.edges.size()]
			# The quad:
			# - v0 subdivided vertex
			# - edge point between v0 and v1
			# - face point
			# - edge point between v0 and previous vertex
			var idx_v0 = get_vertex.call(vertex_points[old_verts.find(v0)])
			var idx_ep0 = get_vertex.call(edge_points[e0])
			var idx_fp = get_vertex.call(fp)
			var idx_ep1 = get_vertex.call(edge_points[e1])
			new_quads.append([idx_v0, idx_ep0, idx_fp, idx_ep1])

	return {
		"vertices": new_vertices,
		"quads": new_quads
	}

# Build ArrayMesh from quad mesh (with smooth normals)
func build_mesh_from_quads(vertices: Array, quads: Array) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Compute normals per vertex, for smooth shading
	var normals = []
	for i in range(vertices.size()):
		normals.append(Vector3.ZERO)
	for quad in quads:
		var v_indices = quad
		var v0 = vertices[v_indices[0]]
		var v1 = vertices[v_indices[1]]
		var v2 = vertices[v_indices[2]]
		var v3 = vertices[v_indices[3]]
		# Triangles: (v0, v1, v2), (v0, v2, v3)
		var n1 = Plane(v0, v1, v2).normal
		var n2 = Plane(v0, v2, v3).normal
		normals[v_indices[0]] += n1 + n2
		normals[v_indices[1]] += n1
		normals[v_indices[2]] += n1 + n2
		normals[v_indices[3]] += n2
	# Normalize normals
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()
	# Add triangles
	for quad in quads:
		var v_indices = quad
		var v0 = vertices[v_indices[0]]
		var v1 = vertices[v_indices[1]]
		var v2 = vertices[v_indices[2]]
		var v3 = vertices[v_indices[3]]
		var n0 = normals[v_indices[0]]
		var n1 = normals[v_indices[1]]
		var n2 = normals[v_indices[2]]
		var n3 = normals[v_indices[3]]
		# First triangle
		st.set_normal(n0)
		st.add_vertex(v0)
		st.set_normal(n1)
		st.add_vertex(v1)
		st.set_normal(n2)
		st.add_vertex(v2)
		# Second triangle
		st.set_normal(n0)
		st.add_vertex(v0)
		st.set_normal(n2)
		st.add_vertex(v2)
		st.set_normal(n3)
		st.add_vertex(v3)
	return st.commit()

func _run() -> void:
	var topo = generate_cube_topology()
	var subdiv = catmull_clark_subdivide(topo)
	var mesh = build_mesh_from_quads(subdiv["vertices"], subdiv["quads"])
	ResourceSaver.save(mesh, "res://mesh.tres")
