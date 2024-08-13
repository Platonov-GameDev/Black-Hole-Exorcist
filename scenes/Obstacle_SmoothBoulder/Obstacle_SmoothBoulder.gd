extends CharacterBody2D
class_name Obstacle_SmoothBoulder


@export var power_crystal_scene: PackedScene

@onready var health_component = $HealthComponent
@onready var sprite_2d = $Sprite2D
@onready var kill_area_2d = $KillArea2D

var MOVE_SPEED := 500.0
var ROTATION_SPEED := 5.0

var did_init := false
var movement_direction := Vector2.ZERO


func _ready():
	health_component.destroyed.connect(_on_health_component_destroyed)
	health_component.damage_taken.connect(_on_health_component_damage_taken)
	kill_area_2d.body_entered.connect(_on_kill_area_2d_body_entered)


func _process(delta):
	var time_coefficient = GameManager.calculate_time_coefficient(position)
	rotate(ROTATION_SPEED * delta * time_coefficient)
	var collision = move_and_collide(
		movement_direction * clampf(MOVE_SPEED * delta * time_coefficient, 0, 2000)
	)
	_process_collision(collision)
	
	# Game end
	if GameManager.time_since_start >= 300:
		expire()


func _process_collision(collision: KinematicCollision2D):
	if not collision: return
	
	var collider = collision.get_collider()
	if not collider: return
	
	
	var collision_normal = collision.get_normal()
	if collision_normal.is_normalized():
		var bounce_direction = movement_direction.bounce(collision_normal)
		
		var new_movement_direction = get_restricted_movement_vector(bounce_direction)
		if new_movement_direction == movement_direction:
			movement_direction = get_restricted_movement_vector(collision_normal)
		else:
			movement_direction = new_movement_direction


func expire():
	call_deferred("queue_free")
	
	var power_crystal = power_crystal_scene.instantiate()
	power_crystal.position = position
	call_deferred("add_sibling", power_crystal)
	AudioPlayer.obstacle_destroyed_audio.play()
	GameManager.update_score(GameManager.score + 30)


func _on_health_component_destroyed():
	expire()


func _on_health_component_damage_taken():
	AudioPlayer.obstacle_hit_audio.play()


func get_restricted_movement_vector(movement_vector: Vector2):
	var direction_angle := movement_vector.angle_to(Vector2.UP + Vector2.RIGHT)
	var direction_angle_snapped = snapped(direction_angle, PI / 2)
	return (Vector2.UP + Vector2.RIGHT).rotated(-direction_angle_snapped).normalized()


func _on_collision_area_2d_body_entered(body):
	var collision_normal = position - body.position
	if collision_normal.is_normalized():
		var bounce_direction = movement_direction.bounce(collision_normal)
		
		movement_direction = get_restricted_movement_vector(bounce_direction)


func _on_kill_area_2d_body_entered(body):
	if not is_instance_valid(body): return
	var player = body as PlayerBody
	player.die()
