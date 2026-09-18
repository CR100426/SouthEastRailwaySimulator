extends Node
## TimetableManager - Service definitions and timekeeping
## Status: WORKING (basic) / PLACEHOLDER (full clock + AI later)

var game_time_seconds: float = 10 * 3600 + 15 * 60  # start at 10:15
var time_scale: float = 1.0

func _ready() -> void:
	print("[TimetableManager] Ready")

func _process(delta: float) -> void:
	if GameManager.is_driving():
		game_time_seconds += delta * time_scale

func get_time_string() -> String:
	var t = int(game_time_seconds) % 86400
	var h = t / 3600
	var m = (t % 3600) / 60
	var s = t % 60
	return "%02d:%02d:%02d" % [h, m, s]

func get_scheduled_arrival(service: Dictionary) -> String:
	return service.get("scheduled_arrival", "00:00:00")

func is_early(service: Dictionary, tolerance_s: int = 30) -> bool:
	# Simplified for V0.1
	return false
