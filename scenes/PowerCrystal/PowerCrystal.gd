extends CharacterBody2D


var ACCELERATION = 2000


func _physics_process(delta):
	if not is_instance_valid(GameManager.player_body): return
	
	var previous_speed = velocity.length()
	velocity = (
		(GameManager.player_body.position - position).normalized()
		* (previous_speed + ACCELERATION * delta)
	)
	var collision = move_and_collide(velocity * delta)
	if collision:
		call_deferred("queue_free")
		GameManager.add_power(1)
