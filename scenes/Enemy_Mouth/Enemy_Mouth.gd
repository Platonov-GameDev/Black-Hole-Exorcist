extends CharacterBody2D
class_name Enemy_Mouth


@onready var health_component = $HealthComponent
@onready var animated_sprite_2d = $AnimatedSprite2D

var MOVE_SPEED := 800.0
var ROTATION_SPEED := PI / 2


func _process(delta):
	if not GameManager.is_round_active: return
	
	var time_coefficient = GameManager.calculate_time_coefficient(position)
	var vector_to_player = GameManager.player_body.position - position
	var angle_to_player = transform.x.angle_to(vector_to_player)
	var rotation_angle = clampf(
		angle_to_player * ROTATION_SPEED * delta * time_coefficient, -2 * PI, 2 * PI)
	rotate(rotation_angle)
	move_and_collide(
		transform.x * clampf(MOVE_SPEED * delta * time_coefficient, 0, 2000)
	)
	
	animated_sprite_2d.speed_scale = time_coefficient
