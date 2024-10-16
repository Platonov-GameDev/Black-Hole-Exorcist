extends CharacterBody2D


@onready var polygon_2d = $Polygon2D
@onready var collection_area_2d = $CollectionArea2D

var ACCELERATION = 200
var DRIFT_SPEED = 20
var DRIFT_END_DISTANCE = 50

var previous_speed := 30.0
var speed: float
var time_elapsed := 0.0
var did_player_come_by := false


func _ready():
	collection_area_2d.body_entered.connect(_on_collection_area_2d_body_entered)


func _process(delta):
	time_elapsed += GameManager.calculate_time_coefficient(position)
	
	polygon_2d.color.a = 1.0 - fmod(time_elapsed, 100.0) / 100.0


func _physics_process(delta):
	if not is_instance_valid(GameManager.player_body): return
	
	var time_coefficient = GameManager.calculate_time_coefficient(position)
	if not did_player_come_by:
		if position.length() >= DRIFT_END_DISTANCE:
			velocity = -position * delta * time_coefficient * DRIFT_SPEED
		else:
			velocity = (
				(position.normalized() * DRIFT_END_DISTANCE - position)
				* delta
				* time_coefficient
				* DRIFT_SPEED
			)
	else:
		speed = previous_speed + ACCELERATION * delta * time_coefficient
		velocity = (
			(GameManager.player_body.position - position).normalized()
			* speed
			* time_coefficient
		)
		previous_speed = speed
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		call_deferred("queue_free")
		GameManager.add_power(1)
		AudioPlayer.crystal_eaten_audio.play()


func _on_collection_area_2d_body_entered(body):
	if not is_instance_valid(body): return
	
	did_player_come_by = true
