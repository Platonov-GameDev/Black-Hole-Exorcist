extends CharacterBody2D
class_name Enemy_Mouth


@onready var health_component = $HealthComponent
@onready var animated_sprite_2d = $AnimatedSprite2D

var MOVE_SPEED := 60.0
var ROTATION_SPEED := PI


func _process(delta):
	if not GameManager.is_round_active: return
	
	var time_coefficient = GameManager.calculate_time_coefficient(position)
	var vector_to_player = GameManager.player_body.position - position
	var angle_to_player = transform.x.angle_to(vector_to_player)
	var rotation_angle = clampf(
		angle_to_player * ROTATION_SPEED * time_coefficient, -2 * PI, 2 * PI) * delta
	rotate(rotation_angle)
	move_and_collide(
		(transform.x * MOVE_SPEED * time_coefficient).limit_length(GameManager.MAX_SPEED) * delta
	)
	
	animated_sprite_2d.speed_scale = time_coefficient
