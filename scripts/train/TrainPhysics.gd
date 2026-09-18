extends Node
## TrainPhysics - Believable EMU physics (mass, traction, braking, gradient, resistance)
## Inspired by Class 377 characteristics but original implementation.
## Status: WORKING (core simulation) - not professional engineering accuracy but feel is intentional

class_name TrainPhysics

signal speed_changed(speed_mph: float)
signal power_changed(notch: int)
signal brake_changed(notch: int)

# Physical constants (approximate for a 4-car Class 377-ish EMU)
const MASS_KG: float = 160000.0          # ~160 tonnes
const MAX_TRACTION_FORCE_N: float = 180000.0  # rough starting tractive effort
const MAX_BRAKE_FORCE_N: float = 220000.0
const MAX_SPEED_MPH: float = 100.0
const WHEEL_DIAMETER_M: float = 0.84
const G: float = 9.81

# Rolling resistance coefficients (simplified Davis formula style)
const A_RESIST: float = 1200.0   # constant N
const B_RESIST: float = 15.0     # per m/s
const C_RESIST: float = 0.4      # per (m/s)^2

# Controller notches
var power_notch: int = 0         # 0..5 (0 = coast/off)
var brake_notch: int = 0         # 0..5 (0 = release, 5 = emergency)
var reverser: int = 0            # -1 reverse, 0 neutral, +1 forward

# State
var speed_ms: float = 0.0
var position_m: float = 0.0
var direction: int = 1           # +1 down (Falmer->Lewes), -1 up
var doors_open: bool = false
var emergency_brake: bool = false
var traction_cut: bool = false   # doors open, SPAD, etc.

# Internal
var _acceleration_ms2: float = 0.0
var _last_speed_mph: float = 0.0

func _ready() -> void:
	print("[TrainPhysics] Initialised - mass %.0f t" % (MASS_KG / 1000.0))

func set_power(notch: int) -> void:
	power_notch = clampi(notch, 0, 5)
	if power_notch > 0 and brake_notch > 0:
		brake_notch = 0  # power takes priority in this simple model
	emit_signal("power_changed", power_notch)

func set_brake(notch: int) -> void:
	brake_notch = clampi(notch, 0, 5)
	if brake_notch > 0:
		power_notch = 0
	emit_signal("brake_changed", brake_notch)

func set_reverser(dir: int) -> void:
	if abs(speed_ms) < 0.1:  # only change when nearly stopped
		reverser = clampi(dir, -1, 1)

func open_doors() -> bool:
	if abs(speed_ms) > 0.3:
		return false
	doors_open = true
	traction_cut = true
	return true

func close_doors() -> void:
	doors_open = false
	traction_cut = false

func apply_emergency() -> void:
	emergency_brake = true
	brake_notch = 5
	power_notch = 0

func release_emergency() -> void:
	emergency_brake = false

func update(delta: float, gradient_factor: float) -> void:
	# gradient_factor from TrackManager: signed contribution to acceleration
	var force_n: float = 0.0

	# Traction
	if not traction_cut and not emergency_brake and power_notch > 0 and reverser != 0:
		var notch_frac: float = power_notch / 5.0
		# Simple traction curve: high at low speed, falls off
		var speed_factor: float = 1.0 / (1.0 + abs(speed_ms) / 25.0)
		force_n += MAX_TRACTION_FORCE_N * notch_frac * speed_factor * reverser

	# Braking
	if brake_notch > 0 or emergency_brake:
		var brake_frac: float = 1.0 if emergency_brake else (brake_notch / 5.0)
		var brake_dir: float = -sign(speed_ms) if abs(speed_ms) > 0.05 else 0.0
		force_n += MAX_BRAKE_FORCE_N * brake_frac * brake_dir

	# Rolling + aerodynamic resistance (always opposes motion)
	var v: float = abs(speed_ms)
	var resist: float = A_RESIST + B_RESIST * v + C_RESIST * v * v
	if abs(speed_ms) > 0.05:
		force_n -= resist * sign(speed_ms)

	# Gradient (mg * sin(theta) ≈ mg / gradient_ratio)
	# gradient_factor already signed and scaled as 1/g
	force_n += MASS_KG * G * gradient_factor

	# Acceleration
	_acceleration_ms2 = force_n / MASS_KG
	speed_ms += _acceleration_ms2 * delta

	# Stop dead at very low speed under brake
	if abs(speed_ms) < 0.08 and (brake_notch > 0 or emergency_brake):
		speed_ms = 0.0
		_acceleration_ms2 = 0.0

	# Clamp max speed
	var max_ms: float = MAX_SPEED_MPH * 0.44704
	speed_ms = clampf(speed_ms, -max_ms, max_ms)

	# Integrate position (direction is absolute along the route)
	position_m += speed_ms * delta * direction

	var speed_mph: float = abs(speed_ms) * 2.23694
	if abs(speed_mph - _last_speed_mph) > 0.1:
		_last_speed_mph = speed_mph
		emit_signal("speed_changed", speed_mph)

func get_speed_mph() -> float:
	return abs(speed_ms) * 2.23694

func get_speed_ms() -> float:
	return speed_ms

func get_position_m() -> float:
	return position_m

func set_position(pos: float) -> void:
	position_m = pos

func is_moving() -> bool:
	return abs(speed_ms) > 0.15

func get_power_notch() -> int:
	return power_notch

func get_brake_notch() -> int:
	return brake_notch

func get_reverser() -> int:
	return reverser
