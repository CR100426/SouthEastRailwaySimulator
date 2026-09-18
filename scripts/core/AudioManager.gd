extends Node
## AudioManager - Placeholder for traction, brake, horn, rail, ambient sounds
## Status: PLACEHOLDER - no assets yet. Do not rip commercial game audio.

func _ready() -> void:
	print("[AudioManager] Placeholder ready - add licensed or original sounds later")

func play(_sound_id: String) -> void:
	pass

func set_traction_level(_level: float) -> void:
	pass

func set_brake_level(_level: float) -> void:
	pass
