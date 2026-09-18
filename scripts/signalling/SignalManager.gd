extends Node
## SignalManager - British 4-aspect colour light signalling
## GREEN / DOUBLE YELLOW / YELLOW / RED
## Status: WORKING (basic block occupancy + aspect calculation) / PARTIALLY WORKING (junctions later)

enum Aspect { RED, YELLOW, DOUBLE_YELLOW, GREEN }

signal aspect_changed(signal_id: String, aspect: Aspect)

var signals: Dictionary = {}          # id -> SignalState
var occupied_blocks: Dictionary = {}  # block_id -> train_id (or true)
var route_direction: int = 1

class SignalState:
	var id: String
	var position_m: float
	var direction: String
	var aspect: Aspect = Aspect.GREEN
	var protects: String = ""
	var previous_signal: String = ""
	var next_signal: String = ""

func _ready() -> void:
	print("[SignalManager] Ready")

func load_from_route(route: Dictionary) -> void:
	signals.clear()
	occupied_blocks.clear()
	var sig_list = route.get("signals", [])
	# Sort by position for linking
	sig_list.sort_custom(func(a, b): return a.position_m < b.position_m)
	for i in range(sig_list.size()):
		var s = sig_list[i]
		var st = SignalState.new()
		st.id = s.id
		st.position_m = s.position_m
		st.direction = s.get("direction", "down")
		st.protects = s.get("protects", "")
		st.aspect = Aspect.GREEN
		if i > 0:
			st.previous_signal = sig_list[i-1].id
		if i < sig_list.size() - 1:
			st.next_signal = sig_list[i+1].id
		signals[st.id] = st
	print("[SignalManager] Loaded %d signals" % signals.size())

func set_block_occupied(block_id: String, occupied: bool, train_id: String = "player") -> void:
	if occupied:
		occupied_blocks[block_id] = train_id
	else:
		occupied_blocks.erase(block_id)
	_recalculate_aspects()

func update_train_position(train_pos_m: float, train_direction: int) -> void:
	# Simple occupancy: mark the section the train is currently in
	# For V0.1 we use coarse blocks derived from signal positions
	var current_block := _get_block_for_position(train_pos_m)
	# Clear all then set current (single train for now)
	occupied_blocks.clear()
	if current_block != "":
		occupied_blocks[current_block] = "player"
	_recalculate_aspects()

func _get_block_for_position(pos_m: float) -> String:
	# Find the signal section the train is in
	var sorted_sigs: Array = signals.values()
	sorted_sigs.sort_custom(func(a, b): return a.position_m < b.position_m)
	for i in range(sorted_sigs.size()):
		var s = sorted_sigs[i]
		var next_pos = 99999.0
		if i + 1 < sorted_sigs.size():
			next_pos = sorted_sigs[i+1].position_m
		if pos_m >= s.position_m and pos_m < next_pos:
			return s.protects if s.protects != "" else s.id
	return ""

func _recalculate_aspects() -> void:
	# Classic 4-aspect cascade: RED if next block occupied, then YELLOW, DY, GREEN
	var sorted: Array = signals.values()
	sorted.sort_custom(func(a, b): return a.position_m < b.position_m)

	for i in range(sorted.size() - 1, -1, -1):
		var sig: SignalState = sorted[i]
		var old_aspect = sig.aspect
		var next_occupied := false
		# Check if the section this signal protects is occupied
		if occupied_blocks.has(sig.protects) or occupied_blocks.has(sig.id):
			next_occupied = true

		if next_occupied:
			sig.aspect = Aspect.RED
		else:
			# Look at next signal aspect
			if sig.next_signal != "" and signals.has(sig.next_signal):
				var next_asp = signals[sig.next_signal].aspect
				match next_asp:
					Aspect.RED:
						sig.aspect = Aspect.YELLOW
					Aspect.YELLOW:
						sig.aspect = Aspect.DOUBLE_YELLOW
					Aspect.DOUBLE_YELLOW, Aspect.GREEN:
						sig.aspect = Aspect.GREEN
			else:
				sig.aspect = Aspect.GREEN  # end of route / clear

		if sig.aspect != old_aspect:
			emit_signal("aspect_changed", sig.id, sig.aspect)

func get_aspect(signal_id: String) -> Aspect:
	if signals.has(signal_id):
		return signals[signal_id].aspect
	return Aspect.GREEN

func get_aspect_name(aspect: Aspect) -> String:
	match aspect:
		Aspect.RED: return "RED"
		Aspect.YELLOW: return "YELLOW"
		Aspect.DOUBLE_YELLOW: return "DOUBLE YELLOW"
		Aspect.GREEN: return "GREEN"
	return "?"

func get_signal_ahead(pos_m: float, direction: int, max_dist_m: float = 2000.0) -> Dictionary:
	var best_id := ""
	var best_dist := max_dist_m + 1.0
	for id in signals:
		var s: SignalState = signals[id]
		var dist = (s.position_m - pos_m) * direction
		if dist > 5.0 and dist < best_dist:
			best_dist = dist
			best_id = id
	if best_id != "":
		var s = signals[best_id]
		return {
			"id": best_id,
			"aspect": s.aspect,
			"aspect_name": get_aspect_name(s.aspect),
			"distance_m": best_dist,
			"position_m": s.position_m
		}
	return {}
