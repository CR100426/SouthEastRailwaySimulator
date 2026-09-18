extends Node3D
## Main - Entry point for V0.1 Falmer ↔ Lewes
## Builds track, terrain, stations and starts the driveable train

@onready var train: TrainController = $Train
@onready var hud: CanvasLayer = $DriverHUD
@onready var track_builder: Node3D = $TrackBuilder

func _ready() -> void:
	print("========================================")
	print("  SOUTH EAST RAILWAY SIMULATOR  V0.1")
	print("  Falmer ↔ Lewes")
	print("========================================")

	var ok = TrackManager.load_route("res://data/routes/falmer_lewes.json")
	if not ok:
		push_error("Failed to load route data")
		return

	SignalManager.load_from_route(TrackManager.current_route)

	if track_builder and track_builder.has_method("build_from_route"):
		track_builder.build_from_route(TrackManager.current_route)
		print("[Main] Track and terrain built")

	if train:
		train.track_builder = track_builder

	if hud and hud.has_method("bind_train"):
		hud.bind_train(train)

	print("[Main] Starting Falmer → Lewes service...")
	_start_selected("svc_fmr_lws")

	print("[Main] Controls:")
	print("  W / S     Power up / down")
	print("  Q / A     Brake up / down")
	print("  F / R     Reverser Forward / Reverse")
	print("  O / C     Doors Open / Close")
	print("  H         Horn")
	print("  L         Headlights")
	print("  1 / 2     Cab / External camera")

func _start_selected(service_id: String) -> void:
	if not GameManager.start_service(service_id):
		return
	var svc = GameManager.get_current_service()
	var start_pos = 40.0
	var dir = 1 if svc.direction == "down" else -1
	if svc.origin == "LWS":
		start_pos = 6980.0
	train.start_service(svc, start_pos, dir)
