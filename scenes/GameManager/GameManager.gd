extends Node


var score: float
var is_round_active := false
var mouse_position: Vector2
var arena_side_size: float
var player_body: PlayerBody
var power: int
var player_distance_from_black_hole = 10.0
var black_hole_position := Vector2.ZERO
var time_since_start := 0.0

signal score_changed(new_max_score)
signal power_changed(new_power)


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _process(delta):
	if is_round_active:
		time_since_start += delta


func update_score(new_score):
	if is_round_active:
		score = new_score
		score_changed.emit(new_score)


func reset():
	score = 0
	power = 0
	time_since_start = 0.0


func add_power(amount):
	power += amount
	power_changed.emit(power)


func calculate_time_coefficient(object_position):
	var object_distance_from_blackhole = (black_hole_position - object_position).length()
	var raw_coefficient = (5000 + object_distance_from_blackhole - player_distance_from_black_hole) / 5000
	return pow(raw_coefficient, 8)
