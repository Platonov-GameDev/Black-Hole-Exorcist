extends Node


var score: float
var is_round_active := false
var mouse_position: Vector2
var arena_side_size: float
var pulled_bodies = []

signal score_changed(new_max_score)


func _process(delta):
	if is_round_active:
		update_score(score + delta)


func update_score(new_score):
	score = new_score
	score_changed.emit(new_score)


func reset():
	score = 0
	pulled_bodies.clear()
