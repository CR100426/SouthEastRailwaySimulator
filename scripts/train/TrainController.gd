extends Node3D
## TrainController - Player train: physics, cab controls, doors, lights, scoring hooks
## Status: WORKING (logic) / PLACEHOLDER (3D model + cab mesh)

class_name TrainController

@onready var physics: TrainPhysics = $TrainPhysics
@onready var cab_camera: Camera3D = $CabCamera
@onready var external_camera: Camera3D = $ExternalCamera

var train_id: String = "player_377"
var current_station: String = ""
var next_station: String = ""
var service_active: bool = false
var doors_side: String = "right"  # will be set by platform
var headlights_on: bool = false
var last_speed_limit: float = 70.0
var overspeed_timer: float = 0.0

# Scoring / performance
var last_stop_accuracy_m: float = 999.0
var power_change_time: float = 0.0

func _ready() -> void:
	if physics == null:
		physics = TrainPhysics.new()
		add_child(physics)
	physics.speed_changed.connect(_on_speed_changed)
	print("[TrainController] Ready")

func start_service(service: Dictionary, start_pos_m: float, dir: int) -> void:
	service_active = true
	physics.direction = dir
	physics.set_position(start_pos_m)
	physics.set_reverser(1 if dir > 0 else -1)
	physics.set_power(0)
	physics.set_brake(0)
	current_station = service.origin
	next_station = service.destination
	print("[TrainController] Service started at %.1f m, direction %d" % [start_pos_m, dir])

func _process(delta: float) -> void:
	if not service_active or not GameManager.is_driving():
		return

	# Input handling
	_handle_input(delta)

	# Gradient from TrackManager
	var grad_factor: float = TrackManager.get_gradient_force_factor(physics.get_position_m(), physics.direction)
	physics.update(delta, grad_factor)

	# Signal occupancy update
	SignalManager.update_train_position(physics.get_position_m(), physics.direction)

	# Speed limit monitoring
	_check_speed_limit(delta)

	# Station detection
	_check_station()

func _handle_input(_delta: float) -> void:
	if Input.is_action_just_pressed("power_up"):
		physics.set_power(physics.get_power_notch() + 1)
	if Input.is_action_just_pressed("power_down"):
		physics.set_power(physics.get_power_notch() - 1)
	if Input.is_action_just_pressed("brake_up"):
		physics.set_brake(physics.get_brake_notch() + 1)
	if Input.is_action_just_pressed("brake_down"):
		physics.set_brake(physics.get_brake_notch() - 1)
	if Input.is_action_just_pressed("reverser_forward"):
		physics.set_reverser(1)
	if Input.is_action_just_pressed("reverser_reverse"):
		physics.set_reverser(-1)
	if Input.is_action_just_pressed("horn"):
		_sound_horn()
	if Input.is_action_just_pressed("doors_open"):
		_try_open_doors()
	if Input.is_action_just_pressed("doors_close"):
		physics.close_doors()
	if Input.is_action_just_pressed("headlights"):
		headlights_on = not headlights_on
	if Input.is_action_just_pressed("camera_cab") and cab_camera:
		cab_camera.current = true
	if Input.is_action_just_pressed("camera_external") and external_camera:
		external_camera.current = true

func _try_open_doors() -> void:
	if physics.open_doors():
		print("[Train] Doors opening")
	else:
		print("[Train] Cannot open doors while moving")
		GameManager.add_score_event("door_error")

func _sound_horn() -> void:
	print("[Train] Horn")
	# AudioManager.play("horn") later

func _check_speed_limit(delta: float) -> void:
	var limit: float = TrackManager.get_speed_limit_at(physics.get_position_m())
	var speed: float = physics.get_speed_mph()
	if speed > limit + 3.0:  # 3 mph grace
		overspeed_timer += delta
		if overspeed_timer > 2.0:
			GameManager.add_score_event("speeding")
			overspeed_timer = 0.0
			print("[Train] Overspeed: %.1f / %d mph" % [speed, limit])
	else:
		overspeed_timer = 0.0
	last_speed_limit = limit

func _check_station() -> void:
	var st = TrackManager.get_station_at(physics.get_position_m(), 120.0)
	if st.is_empty():
		return
	if st.id != current_station and not physics.is_moving():
		# Arrived
		current_station = st.id
		_evaluate_stop(st)
		if st.id == next_station:
			GameManager.complete_service()

func _evaluate_stop(station: Dictionary) -> void:
	var stop_pos = TrackManager.get_stopping_position(station.id, "")
	var error_m = abs(physics.get_position_m() - (station.position_m + 30.0))  # rough
	last_stop_accuracy_m = error_m
	if error_m < 8.0:
		GameManager.add_score_event("accurate_stop")
		print("[Train] Accurate stop at %s (error %.1f m)" % [station.name, error_m])
	elif error_m < 25.0:
		GameManager.add_score_event("accurate_stop")  # still acceptable
	else:
		GameManager.add_score_event("overshoot")
		print("[Train] Overshoot/undershoot at %s (error %.1f m)" % [station.name, error_m])

func _on_speed_changed(speed_mph: float) -> void:
	pass  # HUD listens via physics

func get_hud_data() -> Dictionary:
	var pos = physics.get_position_m()
	var upcoming = TrackManager.get_upcoming_speed_limit(pos)
	var sig = SignalManager.get_signal_ahead(pos, physics.direction)
	return {
		"speed_mph": physics.get_speed_mph(),
		"speed_limit_mph": TrackManager.get_speed_limit_at(pos),
		"upcoming_limit_mph": upcoming.get("limit_mph", -1),
		"upcoming_distance_m": upcoming.get("distance_m", -1),
		"position_m": pos,
		"power_notch": physics.get_power_notch(),
		"brake_notch": physics.get_brake_notch(),
		"reverser": physics.get_reverser(),
		"doors_open": physics.doors_open,
		"next_station": next_station,
		"signal_aspect": sig.get("aspect_name", ""),
		"signal_distance_m": sig.get("distance_m", -1),
		"in_tunnel": TrackManager.is_in_tunnel(pos),
		"gradient_1_in": TrackManager.get_gradient_at(pos)
	}
