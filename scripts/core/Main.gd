extends Node3D
## Main - Entry point for V0.1 Falmer ↔ Lewes playable section
## Status: WORKING (bootstrap) / PLACEHOLDER (full 3D world)

@onready var train: TrainController = $Train
@onready var hud: CanvasLayer = $DriverHUD
@onready var menu: Control = $ServiceMenu

func _ready() -> void:
	print("========================================")
	print("  SOUTH EAST RAILWAY SIMULATOR  V0.1")
	print("  Falmer ↔ Lewes")
	print("========================================")
	
	# Load the first route
	var ok = TrackManager.load_route("res://data/routes/falmer_lewes.json")
	if not ok:
		push_error("Failed to load route data")
		return
	
	SignalManager.load_from_route(TrackManager.current_route)
	
	# Bind HUD
	if hud and hud.has_method("bind_train"):
		hud.bind_train(train)
	
	# Show service selection (simple for now)
	_show_menu()

func _show_menu() -> void:
	print("[Main] Available services:")
	for svc in GameManager.available_services:
		print("  - ", svc.id, " : ", svc.name)
	print("[Main] Auto-starting Falmer → Lewes for testing...")
	# Auto-start the first service so the project is immediately playable
	_start_selected("svc_fmr_lws")

func _start_selected(service_id: String) -> void:
	if not GameManager.start_service(service_id):
		return
	var svc = GameManager.get_current_service()
	var start_pos = 30.0  # just after Falmer platform stop marker
	var dir = 1 if svc.direction == "down" else -1
	if svc.origin == "LWS":
		start_pos = 7000.0
	train.start_service(svc, start_pos, dir)
	print("[Main] Driving. Controls:")
	print("  W / S     Power up / down")
	print("  Q / A     Brake up / down")
	print("  F / R     Reverser Forward / Reverse")
	print("  O / C     Doors Open / Close")
	print("  H         Horn")
	print("  L         Headlights")
	print("  1 / 2     Cab / External camera")
	print("  Esc       Pause")
