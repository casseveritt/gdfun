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
	var sharpness: float = 1.0
	var is_boundary: bool = false

class Face:
	var verts = []
	var edges = []
	var id: int

func lerp(a: Vector3, b: Vector3, t: float) -> Vector3:
	return a * (1.0 - t) + b * t

func generate_cube_topology() -> Dictionary:
	var verts = []
	var edges = []
	var faces = []
	var vert_map = {}
	var edge_map = {}

	var cube_vertices = [
		Vector3(-1, -1, -1), # 0
		Vector3( 1, -1, -1), # 1
		Vector3( 1,  1, -1), # 2
		Vector3(-1,  1, -1), # 3
		Vector3(-1, -1,  1), # 4
		Vector3( 1, -1,  1), # 5
		Vector3( 1,  1,  1), # 6
		Vector3(-1,  1,  1), # 7
	]
	# CCW winding
	var cube_faces = [
		[0, 1, 2, 3], # -Z (front)
		[5, 4, 7, 6], # +Z (back)
		[0, 4, 5, 1], # -Y (bottom)
		[3, 2, 6, 7], # +Y (top)
		[0, 3, 7, 4], # -X (left)
		[1, 5, 6, 2], # +X (right)
	]

	for i in cube_vertices.size():
		var v = Vertex.new()
		v.pos = cube_vertices[i]
		v.id = i
		verts.append(v)
		vert_map[i] = v

	for fi in cube_faces.size():
		var face_indices = cube_faces[fi]
		var f = Face.new()
		f.id = fi
		for i in range(4):
			var vi = face_indices[i]
			f.verts.append(vert_map[vi])
			vert_map[vi].faces.append(f)
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

	for edge in edges:
		edge.is_boundary = edge.faces.size() == 1
		edge.sharpness = 1.0 # SHARP CUBE

	return {
		"vertices": verts,
		"edges": edges,
		"faces": faces
	}

func catmull_clark_subdivide_multi(mesh_topo: Dictionary, iterations: int) -> Dictionary:
	var topo = mesh_topo
	for i in range(iterations):
		topo = catmull_clark_subdivide(topo)
	return topo

func catmull_clark_subdivide(mesh_topo: Dictionary) -> Dictionary:
	var old_verts = mesh_topo["vertices"]
	var old_edges = mesh_topo["edges"]
	var old_faces = mesh_topo["faces"]

	# Face points
	var face_points = []
	for f in old_faces:
		var avg = Vector3.ZERO
		for v in f.verts:
			avg += v.pos
		avg /= f.verts.size()
		face_points.append(avg)

	# Edge points
	var edge_points = {}
	for e in old_edges:
		if e.is_boundary or e.sharpness >= 1.0:
			edge_points[e] = (e.v1.pos + e.v2.pos) * 0.5
		else:
			var fp_sum = Vector3.ZERO
			for f in e.faces:
				fp_sum += face_points[old_faces.find(f)]
			fp_sum /= e.faces.size()
			var smooth_ep = (e.v1.pos + e.v2.pos + fp_sum) / 3.0
			var crease_ep = (e.v1.pos + e.v2.pos) * 0.5
			edge_points[e] = lerp(smooth_ep, crease_ep, e.sharpness)

	# Vertex points
	var vertex_points = []
	for v in old_verts:
		var crease_edges = []
		var boundary_edges = []
		for e in v.edges:
			if e.is_boundary or e.sharpness >= 1.0:
				crease_edges.append(e)
			if e.is_boundary:
				boundary_edges.append(e)
		if crease_edges.size() >= 3:
			# Corner vertex: stays put!
			vertex_points.append(v.pos)
		elif crease_edges.size() == 2:
			# Crease vertex: average of self and crease midpoints
			var mid1 = (crease_edges[0].v1.pos + crease_edges[0].v2.pos) * 0.5
			var mid2 = (crease_edges[1].v1.pos + crease_edges[1].v2.pos) * 0.5
			var new_v = (v.pos + mid1 + mid2) / 3.0
			vertex_points.append(new_v)
		elif boundary_edges.size() > 0:
			# Boundary vertex: average of self and boundary midpoints
			var boundary_mid = Vector3.ZERO
			var count = 0
			for e in boundary_edges:
				boundary_mid += (e.v1.pos + e.v2.pos) * 0.5
				count += 1
			boundary_mid /= count
			var new_v = (boundary_mid + v.pos) * 0.5
			vertex_points.append(new_v)
		else:
			# Smooth vertex: standard Catmull-Clark
			var F = Vector3.ZERO
			for f in v.faces:
				F += face_points[old_faces.find(f)]
			F /= v.faces.size()
			var R = Vector3.ZERO
			for e in v.edges:
				R += edge_points[e]
			R /= v.edges.size()
			var n = v.faces.size()
			var new_v = (F + 2*R + (n-3)*v.pos) / n
			vertex_points.append(new_v)

	# Build new topology
	var new_vertices = []
	var vertex_map = {}
	var get_vertex = func(pos: Vector3) -> int:
		var key = str(pos)
		if vertex_map.has(key):
			return vertex_map[key]
		var idx = new_vertices.size()
		new_vertices.append(pos)
		vertex_map[key] = idx
		return idx

	var new_quads = []

	for fi in old_faces.size():
		var f = old_faces[fi]
		var fp = face_points[fi]
		for i in range(f.verts.size()):
			var v0 = f.verts[i]
			var v1 = f.verts[(i+1)%f.verts.size()]
			var e0 = f.edges[i]
			var e1 = f.edges[(i-1+f.edges.size())%f.edges.size()]
			var idx_v0 = get_vertex.call(vertex_points[old_verts.find(v0)])
			var idx_ep0 = get_vertex.call(edge_points[e0])
			var idx_fp = get_vertex.call(fp)
			var idx_ep1 = get_vertex.call(edge_points[e1])
			new_quads.append([idx_v0, idx_ep0, idx_fp, idx_ep1])

	var verts_objs = []
	for i in new_vertices.size():
		var vert = Vertex.new()
		vert.pos = new_vertices[i]
		vert.id = i
		verts_objs.append(vert)

	var faces_objs = []
	var edges_map = {}
	var edges_objs = []
	for fi in new_quads.size():
		var quad = new_quads[fi]
		var f = Face.new()
		f.id = fi
		for i in range(4):
			var vi = quad[i]
			f.verts.append(verts_objs[vi])
			verts_objs[vi].faces.append(f)
		for i in range(4):
			var vi1 = quad[i]
			var vi2 = quad[(i+1)%4]
			var edge_key = [min(vi1,vi2), max(vi1,vi2)]
			var edge_key_str = str(edge_key)
			var edge
			if edges_map.has(edge_key_str):
				edge = edges_map[edge_key_str]
			else:
				edge = Edge.new()
				edge.v1 = verts_objs[edge_key[0]]
				edge.v2 = verts_objs[edge_key[1]]
				edges_map[edge_key_str] = edge
				edges_objs.append(edge)
				edge.v1.edges.append(edge)
				edge.v2.edges.append(edge)
			edge.faces.append(f)
			f.edges.append(edge)
		faces_objs.append(f)

	# Mark boundary and decay sharpness
	for edge in edges_objs:
		edge.is_boundary = edge.faces.size() == 1
		# Decay sharpness by 1.0 per subdiv
		edge.sharpness = max(0.0, edge.sharpness - 1.0)

	return {
		"vertices": verts_objs,
		"edges": edges_objs,
		"faces": faces_objs
	}

func build_mesh_from_quads(vertices: Array, quads: Array) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var normals = []
	for i in range(vertices.size()):
		normals.append(Vector3.ZERO)
	for quad in quads:
		var v_indices = quad
		var v0 = vertices[v_indices[0]].pos
		var v1 = vertices[v_indices[1]].pos
		var v2 = vertices[v_indices[2]].pos
		var v3 = vertices[v_indices[3]].pos
		var n1 = Plane(v0, v1, v2).normal
		var n2 = Plane(v0, v2, v3).normal
		normals[v_indices[0]] += n1 + n2
		normals[v_indices[1]] += n1
		normals[v_indices[2]] += n1 + n2
		normals[v_indices[3]] += n2
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()
	for quad in quads:
		var v_indices = quad
		var v0 = vertices[v_indices[0]].pos
		var v1 = vertices[v_indices[1]].pos
		var v2 = vertices[v_indices[2]].pos
		var v3 = vertices[v_indices[3]].pos
		var n0 = normals[v_indices[0]]
		var n1 = normals[v_indices[1]]
		var n2 = normals[v_indices[2]]
		var n3 = normals[v_indices[3]]
		st.set_normal(n0)
		st.add_vertex(v0)
		st.set_normal(n1)
		st.add_vertex(v1)
		st.set_normal(n2)
		st.add_vertex(v2)
		st.set_normal(n0)
		st.add_vertex(v0)
		st.set_normal(n2)
		st.add_vertex(v2)
		st.set_normal(n3)
		st.add_vertex(v3)
	return st.commit()

func _run():
	var iterations = 2 # Change for more/less subdivision levels
	var topo = generate_cube_topology()
	var subdiv_topo = catmull_clark_subdivide_multi(topo, iterations)
	var quads = []
	for f in subdiv_topo["faces"]:
		var quad = []
		for v in f.verts:
			quad.append(v.id)
		quads.append(quad)
	var mesh = build_mesh_from_quads(subdiv_topo["vertices"], quads)
	ResourceSaver.save(mesh, "res://mesh.tres")
	print("Mesh saved to res://mesh.tres")
