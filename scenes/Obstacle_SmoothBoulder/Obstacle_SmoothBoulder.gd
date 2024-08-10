extends CharacterBody2D
class_name Obstacle_SmoothBoulder


@export var power_crystal_scene: PackedScene

@onready var health_component = $HealthComponent

var MOVE_SPEED := 500.0
var ROTATION_SPEED := 5.0

var did_init := false
var movement_direction := Vector2.ZERO


func _ready():
	health_component.destroyed.connect(_on_health_component_destroyed)
	health_component.damage_taken.connect(_on_health_component_damage_taken)


func _process(delta):
	var time_coefficient = GameManager.calculate_time_coefficient(position)
	var collision = move_and_collide(
		movement_direction * clampf(MOVE_SPEED * delta * time_coefficient, 0, 2000)
	)
	rotate(ROTATION_SPEED * delta * time_coefficient)
	_process_collision(collision)
	
	# Game end
	if GameManager.time_since_start >= 300:
		expire()


func _process_collision(collision: KinematicCollision2D):
	if not collision: return
	
	var collider = collision.get_collider()
	if not collider: return
	
	if collider.is_in_group("player"):
		collider.die()
	else:
		var reflection_line_vector = collision.get_normal().rotated(PI / 2)
		if reflection_line_vector.is_normalized():
			movement_direction = movement_direction.reflect(reflection_line_vector)


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
