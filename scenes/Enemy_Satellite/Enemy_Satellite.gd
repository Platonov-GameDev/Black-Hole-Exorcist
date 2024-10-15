extends CharacterBody2D


@onready var health_component = $HealthComponent

var ORBIT_SPEED := 100
var ALTITUDE_CHANGE_SPEED := 20

var is_orbiting_clockwise := true


func _process(delta):
	if not GameManager.is_round_active: return
	
	var time_coefficient = GameManager.calculate_time_coefficient(position)
	
	var vector_to_center = GameManager.black_hole_position - position
	var player_distance_to_center = (
		(GameManager.black_hole_position - GameManager.player_body.position).length())
	
	var is_descending := true if vector_to_center.length() >= player_distance_to_center else false
	
	var altitude_change_velocity = vector_to_center.normalized() * ALTITUDE_CHANGE_SPEED
	if not is_descending:
		altitude_change_velocity *= -1
	var orbit_velocity = vector_to_center.rotated(-PI / 2).normalized() * ORBIT_SPEED
	if not is_orbiting_clockwise:
		orbit_velocity *= -1
	
	velocity = (
		(altitude_change_velocity + orbit_velocity) * time_coefficient
	).limit_length(GameManager.MAX_SPEED) * delta
	var collision = move_and_collide(velocity)
	
	if collision:
		is_orbiting_clockwise = not is_orbiting_clockwise
	
	look_at(orbit_velocity + position)
