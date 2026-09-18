extends Node3D
## TrainVisual - Simple placeholder multi-coach EMU that follows physics position
## Status: WORKING (placeholder geometry)

const COACH_LENGTH := 20.0
const COACH_WIDTH := 2.8
const COACH_HEIGHT := 3.6
const NUM_COACHES := 4
const COUPLER_GAP := 1.0

var coaches: Array[MeshInstance3D] = []
var cab_light: OmniLight3D

func _ready() -> void:
	_build_coaches()

func _build_coaches() -> void:
	for i in range(NUM_COACHES):
		var coach = _make_coach(i == 0)
		coach.position.z = -i * (COACH_LENGTH + COUPLER_GAP)
		add_child(coach)
		coaches.append(coach)

	cab_light = OmniLight3D.new()
	cab_light.light_color = Color(1.0, 0.95, 0.8)
	cab_light.light_energy = 3.0
	cab_light.omni_range = 40.0
	cab_light.position = Vector3(0, 2.0, 2.0)
	add_child(cab_light)

func _make_coach(is_cab: bool) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(COACH_WIDTH, COACH_HEIGHT, COACH_LENGTH)
	mi.mesh = box
	var mat = StandardMaterial3D.new()
	if is_cab:
		mat.albedo_color = Color(0.15, 0.35, 0.25)
	else:
		mat.albedo_color = Color(0.2, 0.4, 0.3)
	mat.roughness = 0.6
	mat.metallic = 0.15
	mi.material_override = mat
	var roof = MeshInstance3D.new()
	var roof_mesh = BoxMesh.new()
	roof_mesh.size = Vector3(COACH_WIDTH + 0.1, 0.25, COACH_LENGTH)
	roof.mesh = roof_mesh
	roof.position.y = COACH_HEIGHT * 0.5 + 0.1
	var roof_mat = StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.12, 0.12, 0.14)
	roof.material_override = roof_mat
	mi.add_child(roof)
	var windows = MeshInstance3D.new()
	var win_mesh = BoxMesh.new()
	win_mesh.size = Vector3(COACH_WIDTH + 0.05, 1.0, COACH_LENGTH - 2.0)
	windows.mesh = win_mesh
	windows.position.y = 0.4
	var win_mat = StandardMaterial3D.new()
	win_mat.albedo_color = Color(0.15, 0.2, 0.3)
	win_mat.roughness = 0.2
	windows.material_override = win_mat
	mi.add_child(windows)
	return mi

func set_headlights(on: bool) -> void:
	if cab_light:
		cab_light.light_energy = 4.0 if on else 0.0
