extends CharacterBody2D


var ACCELERATION = 2000

var speed := 0.0
var previous_speed := 0.0


func _physics_process(delta):
	if not is_instance_valid(GameManager.player_body): return
	
	var time_coefficient = GameManager.calculate_time_coefficient(position)
	speed = (previous_speed + ACCELERATION * delta * time_coefficient)
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
