extends Node
## TrackManager - Loads route data, provides position queries, speed limits, gradients
## Status: WORKING (data loading + queries) / PLACEHOLDER (3D mesh generation)

signal route_loaded(route_id: String)

var current_route: Dictionary = {}
var track_length_m: float = 0.0
var stations: Dictionary = {}          # id -> station data
var speed_limits: Array = []           # sorted by start_m
var signals_data: Array = []
var segments: Array = []

func _ready() -> void:
	print("[TrackManager] Ready")

func load_route(route_path: String) -> bool:
	var file = FileAccess.open(route_path, FileAccess.READ)
	if not file:
		push_error("Cannot open route file: " + route_path)
		return false
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	if err != OK:
		push_error("JSON parse error: " + json.get_error_message())
		return false
	current_route = json.data
	_build_lookups()
	emit_signal("route_loaded", current_route.get("route_id", "unknown"))
	print("[TrackManager] Loaded route: ", current_route.get("name", "?"))
	print("[TrackManager] Length: %.1f m (%.2f miles)" % [track_length_m, track_length_m / 1609.34])
	return true

func _build_lookups() -> void:
	stations.clear()
	for st in current_route.get("stations", []):
		stations[st.id] = st
	speed_limits = current_route.get("speed_restrictions", []).duplicate()
	speed_limits.sort_custom(func(a, b): return a.start_m < b.start_m)
	signals_data = current_route.get("signals", []).duplicate()
	var sections = current_route.get("track_sections", [])
	if sections.size() > 0:
		track_length_m = sections[0].get("length_m", 0.0)
		segments = sections[0].get("segments", []).duplicate()
	else:
		track_length_m = 0.0
		segments = []

func get_speed_limit_at(pos_m: float) -> float:
	var limit: float = 70.0  # default line speed
	for r in speed_limits:
		if pos_m >= r.start_m and pos_m < r.end_m:
			limit = r.limit_mph
			break
	return limit

func get_upcoming_speed_limit(pos_m: float, look_ahead_m: float = 1500.0) -> Dictionary:
	var current = get_speed_limit_at(pos_m)
	for r in speed_limits:
		if r.start_m > pos_m and r.start_m < pos_m + look_ahead_m and r.limit_mph < current:
			return {
				"limit_mph": r.limit_mph,
				"distance_m": r.start_m - pos_m,
				"reason": r.get("reason", "")
			}
	return {"limit_mph": current, "distance_m": -1.0, "reason": ""}

func get_gradient_at(pos_m: float) -> float:
	# Returns gradient as 1-in-X (positive = uphill for the down direction)
	for seg in segments:
		if pos_m >= seg.start_m and pos_m < seg.end_m:
			return float(seg.get("gradient_1_in", 0))
	return 0.0

func get_gradient_force_factor(pos_m: float, direction: int) -> float:
	# Returns a multiplier for gravity component. Positive = assisting, negative = opposing.
	# direction: +1 = down (Falmer->Lewes), -1 = up
	var g = get_gradient_at(pos_m)
	if g == 0.0:
		return 0.0
	# Approximate: force component ≈ mass * g * (1/g_ratio)
	# We return signed 1/g so physics can use it.
	var inv = 1.0 / g
	return inv * float(direction) * -1.0  # descent assists down direction

func get_station_at(pos_m: float, tolerance_m: float = 150.0) -> Dictionary:
	for id in stations:
		var st = stations[id]
		if abs(st.position_m - pos_m) < tolerance_m:
			return st
	return {}

func get_stopping_position(station_id: String, platform_id: String) -> float:
	if not stations.has(station_id):
		return -1.0
	var st = stations[station_id]
	for p in st.get("platforms", []):
		if p.id == platform_id:
			return st.position_m + p.get("stopping_position_m", 0.0)
	return st.position_m

func is_in_tunnel(pos_m: float) -> bool:
	for seg in segments:
		if seg.get("type", "") == "tunnel" and pos_m >= seg.start_m and pos_m < seg.end_m:
			return true
	return false

func get_route_name() -> String:
	return current_route.get("name", "Unknown Route")
