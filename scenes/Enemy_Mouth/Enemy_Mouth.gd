extends CharacterBody2D
class_name Enemy_Mouth


@onready var health_component = $HealthComponent
@onready var kill_area_2d = $KillArea2D
@onready var animated_sprite_2d = $AnimatedSprite2D

var MOVE_SPEED := 600.0
var ROTATION_SPEED := 5.0


func _ready():
	health_component.destroyed.connect(_on_health_component_destroyed)
	health_component.damage_taken.connect(_on_health_component_damage_taken)
	kill_area_2d.body_entered.connect(_on_kill_area_2d_body_entered)


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
	
	# Game end
	if GameManager.time_since_start >= 300:
		expire()


func expire():
	call_deferred("queue_free")
	
	AudioPlayer.obstacle_destroyed_audio.play()
	GameManager.update_score(GameManager.score + 30)


func _on_health_component_destroyed():
	expire()


func _on_health_component_damage_taken():
	AudioPlayer.obstacle_hit_audio.play()


func _on_kill_area_2d_body_entered(body):
	if not is_instance_valid(body): return
	var player = body as PlayerBody
	player.die()
