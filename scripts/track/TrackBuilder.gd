extends Node3D
## TrackBuilder - Builds visible 3D track + simple terrain from route data
## Status: WORKING (basic geometry) – expandable later

const RAIL_WIDTH := 0.15
const RAIL_HEIGHT := 0.12
const GAUGE := 1.435          # standard gauge centre-to-centre approx for visual
const SLEEPER_SPACING := 0.7
const TRACK_HALF_WIDTH := 1.2

var route_length: float = 7050.0
var mesh_instance: MeshInstance3D
var ground: MeshInstance3D

func _ready() -> void:
	pass

func build_from_route(route: Dictionary) -> void:
	# Clear previous
	for c in get_children():
		c.queue_free()

	var sections = route.get("track_sections", [])
	if sections.is_empty():
		push_error("No track sections in route")
		return
	route_length = sections[0].get("length_m", 7050.0)
	var segments = sections[0].get("segments", [])

	_build_track_mesh(segments)
	_build_simple_terrain()
	_build_stations(route.get("stations", []))
	_build_signal_markers(route.get("signals", []))
	print("[TrackBuilder] Built track length %.0f m with %d segments" % [route_length, segments.size()])

func _build_track_mesh(segments: Array) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var step := 2.0
	var points: Array = []

	var pos := 0.0
	var height := 85.0
	while pos <= route_length + 1.0:
		var g = _gradient_at(segments, pos)
		if g > 0.0:
			height -= step / g
		points.append(Vector3(0.0, height, -pos))
		pos += step

	for i in range(points.size() - 1):
		var p0: Vector3 = points[i]
		var p1: Vector3 = points[i + 1]
		var dir = (p1 - p0).normalized()
		var right = Vector3.UP.cross(dir).normalized()
		if right.length_squared() < 0.01:
			right = Vector3.RIGHT
		_add_rail_quad(st, p0, p1, right, -GAUGE * 0.5)
		_add_rail_quad(st, p0, p1, right, GAUGE * 0.5)
		_add_bed_quad(st, p0, p1, right)

	var mesh = st.commit()
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.name = "TrackMesh"
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.25, 0.28)
	mat.roughness = 0.85
	mesh_instance.material_override = mat
	add_child(mesh_instance)

func _add_rail_quad(st: SurfaceTool, p0: Vector3, p1: Vector3, right: Vector3, offset: float) -> void:
	var h = Vector3(0, RAIL_HEIGHT, 0)
	var o = right * offset
	var w = right * (RAIL_WIDTH * 0.5)
	var a = p0 + o - w
	var b = p0 + o + w
	var c = p1 + o + w
	var d = p1 + o - w
	st.add_vertex(a + h)
	st.add_vertex(b + h)
	st.add_vertex(c + h)
	st.add_vertex(a + h)
	st.add_vertex(c + h)
	st.add_vertex(d + h)

func _add_bed_quad(st: SurfaceTool, p0: Vector3, p1: Vector3, right: Vector3) -> void:
	var w = right * TRACK_HALF_WIDTH
	var a = p0 - w
	var b = p0 + w
	var c = p1 + w
	var d = p1 - w
	var drop = Vector3(0, -0.05, 0)
	st.add_vertex(a + drop)
	st.add_vertex(b + drop)
	st.add_vertex(c + drop)
	st.add_vertex(a + drop)
	st.add_vertex(c + drop)
	st.add_vertex(d + drop)

func _gradient_at(segments: Array, pos_m: float) -> float:
	for seg in segments:
		if pos_m >= seg.start_m and pos_m < seg.end_m:
			return float(seg.get("gradient_1_in", 0))
	return 0.0

func _build_simple_terrain() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var size := 120.0
	var step := 20.0
	var z = 20.0
	while z > -route_length - 50.0:
		var h0 = 70.0 + (z / route_length) * 73.0
		var h1 = 70.0 + ((z - step) / route_length) * 73.0
		var p00 = Vector3(-size, h0 - 2.0, z)
		var p10 = Vector3( size, h0 - 2.0, z)
		var p01 = Vector3(-size, h1 - 2.0, z - step)
		var p11 = Vector3( size, h1 - 2.0, z - step)
		st.add_vertex(p00)
		st.add_vertex(p10)
		st.add_vertex(p11)
		st.add_vertex(p00)
		st.add_vertex(p11)
		st.add_vertex(p01)
		z -= step
	var mesh = st.commit()
	ground = MeshInstance3D.new()
	ground.mesh = mesh
	ground.name = "Terrain"
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.48, 0.28)
	mat.roughness = 0.95
	ground.material_override = mat
	add_child(ground)

func _build_stations(stations: Array) -> void:
	for st_data in stations:
		var pos_m: float = st_data.get("position_m", 0.0)
		var elev: float = st_data.get("elevation_m", 50.0)
		var platform = _make_platform_box(st_data.get("name", "?"))
		platform.position = Vector3(3.5, elev + 0.6, -pos_m)
		add_child(platform)
		var label = Label3D.new()
		label.text = st_data.get("name", "")
		label.font_size = 64
		label.position = Vector3(6.0, elev + 4.0, -pos_m)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)

func _make_platform_box(name: String) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(3.0, 1.0, 40.0)
	mi.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.55, 0.5)
	mi.material_override = mat
	mi.name = "Platform_" + name
	return mi

func _build_signal_markers(signals: Array) -> void:
	for s in signals:
		var pos_m: float = s.get("position_m", 0.0)
		var elev = 85.0 - (pos_m / route_length) * 73.0
		var post = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.08
		cyl.height = 4.0
		post.mesh = cyl
		post.position = Vector3(-3.0, elev + 2.0, -pos_m)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.85, 0.2)
		post.material_override = mat
		add_child(post)

func distance_to_world(pos_m: float) -> Vector3:
	var elev = 85.0 - (pos_m / route_length) * 73.0
	return Vector3(0.0, elev + 1.2, -pos_m)
