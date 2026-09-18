extends Node
## GameManager - Global state, service selection, scoring and session control
## Status: WORKING (core logic) / PLACEHOLDER (UI integration)

signal service_started(service_data: Dictionary)
signal service_completed(score: Dictionary)
signal score_updated(score: Dictionary)

enum GameState { MENU, LOADING, DRIVING, PAUSED, SERVICE_COMPLETE }

var current_state: GameState = GameState.MENU
var current_service: Dictionary = {}
var player_train: Node = null
var score: Dictionary = {
	"points": 1000,
	"station_stops": 0,
	"accurate_stops": 0,
	"speeding_events": 0,
	"spads": 0,
	"door_errors": 0,
	"early_departures": 0,
	"smooth_driving_bonus": 0,
	"on_time_arrivals": 0
}

# Available services for V0.1
var available_services: Array[Dictionary] = [
	{
		"id": "svc_fmr_lws",
		"name": "Falmer → Lewes",
		"origin": "FMR",
		"destination": "LWS",
		"direction": "down",
		"calling_points": ["FMR", "LWS"],
		"scheduled_departure": "10:15:00",
		"scheduled_arrival": "10:22:00",
		"platform_origin": "FMR_2",
		"platform_dest": "LWS_3",
		"train_type": "class_377_placeholder"
	},
	{
		"id": "svc_lws_fmr",
		"name": "Lewes → Falmer",
		"origin": "LWS",
		"destination": "FMR",
		"direction": "up",
		"calling_points": ["LWS", "FMR"],
		"scheduled_departure": "10:30:00",
		"scheduled_arrival": "10:37:00",
		"platform_origin": "LWS_4",
		"platform_dest": "FMR_1",
		"train_type": "class_377_placeholder"
	}
]

func _ready() -> void:
	print("[GameManager] South East Railway Simulator V0.1 ready")
	print("[GameManager] Focus: Falmer ↔ Lewes")

func start_service(service_id: String) -> bool:
	for svc in available_services:
		if svc.id == service_id:
			current_service = svc.duplicate(true)
			current_state = GameState.LOADING
			score = {
				"points": 1000,
				"station_stops": 0,
				"accurate_stops": 0,
				"speeding_events": 0,
				"spads": 0,
				"door_errors": 0,
				"early_departures": 0,
				"smooth_driving_bonus": 0,
				"on_time_arrivals": 0
			}
			emit_signal("service_started", current_service)
			current_state = GameState.DRIVING
			print("[GameManager] Started service: ", current_service.name)
			return true
	push_error("Service not found: " + service_id)
	return false

func complete_service() -> void:
	current_state = GameState.SERVICE_COMPLETE
	# Final scoring adjustments
	if score.spads > 0:
		score.points -= 500 * score.spads
	if score.speeding_events > 0:
		score.points -= 50 * score.speeding_events
	emit_signal("service_completed", score)
	print("[GameManager] Service complete. Final score: ", score.points)

func add_score_event(event: String, value: int = 0) -> void:
	match event:
		"accurate_stop":
			score.accurate_stops += 1
			score.points += 100
			score.station_stops += 1
		"overshoot":
			score.points -= 80
			score.station_stops += 1
		"speeding":
			score.speeding_events += 1
			score.points -= 30
		"spad":
			score.spads += 1
			score.points -= 500
		"door_error":
			score.door_errors += 1
			score.points -= 40
		"early_departure":
			score.early_departures += 1
			score.points -= 60
		"smooth":
			score.smooth_driving_bonus += 1
			score.points += 10
		"on_time":
			score.on_time_arrivals += 1
			score.points += 150
	emit_signal("score_updated", score)

func get_current_service() -> Dictionary:
	return current_service

func is_driving() -> bool:
	return current_state == GameState.DRIVING
