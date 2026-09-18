extends CanvasLayer
## DriverHUD - Polished train simulator HUD
## Status: WORKING (logic + layout) / PLACEHOLDER (final art/style)

@onready var speed_label: Label = $Panel/SpeedValue
@onready var limit_label: Label = $Panel/LimitValue
@onready var upcoming_label: Label = $Panel/UpcomingValue
@onready var station_label: Label = $Panel/StationValue
@onready var power_label: Label = $Panel/PowerValue
@onready var brake_label: Label = $Panel/BrakeValue
@onready var doors_label: Label = $Panel/DoorsValue
@onready var signal_label: Label = $Panel/SignalValue
@onready var gradient_label: Label = $Panel/GradientValue
@onready var score_label: Label = $Panel/ScoreValue
@onready var destination_label: Label = $Panel/DestinationValue

var train: TrainController = null

func _ready() -> void:
	print("[DriverHUD] Ready")
	GameManager.score_updated.connect(_on_score_updated)

func bind_train(t: TrainController) -> void:
	train = t

func _process(_delta: float) -> void:
	if train == null or not GameManager.is_driving():
		return
	var data = train.get_hud_data()
	if speed_label:
		speed_label.text = "%.0f" % data.speed_mph
	if limit_label:
		limit_label.text = "%d" % int(data.speed_limit_mph)
	if upcoming_label:
		if data.upcoming_distance_m > 0:
			upcoming_label.text = "%d mph in %.0f m" % [int(data.upcoming_limit_mph), data.upcoming_distance_m]
		else:
			upcoming_label.text = "—"
	if station_label:
		station_label.text = data.next_station
	if power_label:
		power_label.text = "P%d" % data.power_notch
	if brake_label:
		brake_label.text = "B%d" % data.brake_notch
	if doors_label:
		doors_label.text = "OPEN" if data.doors_open else "CLOSED"
		doors_label.modulate = Color.ORANGE_RED if data.doors_open else Color.GREEN
	if signal_label:
		signal_label.text = data.signal_aspect
		match data.signal_aspect:
			"RED": signal_label.modulate = Color.RED
			"YELLOW": signal_label.modulate = Color.YELLOW
			"DOUBLE YELLOW": signal_label.modulate = Color.YELLOW
			"GREEN": signal_label.modulate = Color.GREEN
			_: signal_label.modulate = Color.WHITE
	if gradient_label:
		var g = data.gradient_1_in
		if g == 0:
			gradient_label.text = "Level"
		else:
			gradient_label.text = "1 in %d" % int(g)
	if destination_label:
		var svc = GameManager.get_current_service()
		destination_label.text = svc.get("name", "")

func _on_score_updated(score: Dictionary) -> void:
	if score_label:
		score_label.text = str(score.points)
