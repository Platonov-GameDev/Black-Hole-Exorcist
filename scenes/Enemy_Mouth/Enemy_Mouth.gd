extends CharacterBody2D
class_name Enemy_Mouth


@onready var health_component = $HealthComponent
@onready var animated_sprite_2d = $AnimatedSprite2D

var MOVE_SPEED := 600.0
var ROTATION_SPEED := 5.0


func _process(delta):
	var movement_direction = Vector2.ZERO
	if GameManager.is_round_active:
		movement_direction = (GameManager.player_body.position - position).normalized()
	
	var time_coefficient = GameManager.calculate_time_coefficient(position)
	rotate(ROTATION_SPEED * delta * time_coefficient)
	move_and_collide(
		movement_direction * clampf(MOVE_SPEED * delta * time_coefficient, 0, 2000)
	)
	
	animated_sprite_2d.speed_scale = time_coefficient
