extends CharacterBody2D
class_name Obstacle_SmoothBoulder


@export var power_crystal_scene: PackedScene

@onready var health_component = $HealthComponent

var SPEED := 500.0

var did_init := false
var movement_direction := Vector2.ZERO


func _ready():
	health_component.destroyed.connect(_on_health_component_destroyed)
	health_component.damage_taken.connect(_on_health_component_damage_taken)


func _process(delta):
	var collision = move_and_collide(movement_direction * SPEED * delta)
	_process_collision(collision)


func _process_collision(collision: KinematicCollision2D):
	if not collision: return
	
	var collider = collision.get_collider()
	if not collider: return
	
	if collider.is_in_group("player"):
		collider.die()
	else:
		movement_direction = movement_direction.reflect(collision.get_normal().rotated(PI / 2))


func expire(with_reward := false):
	call_deferred("queue_free")
	
	if with_reward:
		var power_crystal = power_crystal_scene.instantiate()
		power_crystal.position = position
		call_deferred("add_sibling", power_crystal)
		AudioPlayer.obstacle_eaten_audio.play()
	else:
		AudioPlayer.obstacle_destroyed_audio.play()


func _on_health_component_destroyed():
	expire(true)


func _on_health_component_damage_taken():
	AudioPlayer.obstacle_hit_audio.play()
