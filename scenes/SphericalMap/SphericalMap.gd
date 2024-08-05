extends Node2D


@export var obstacle_scene: PackedScene

@onready var player_body = $PlayerBody
@onready var camera_2d = $Camera2D
@onready var killbox_area_2d = $KillboxArea2D
@onready var spawn_path_follow_2d = $SpawnPath2D/SpawnPathFollow2D
@onready var spawn_timer = $SpawnTimer
@onready var black_hole_shader_sprite_2d = $KillboxArea2D/BlackHoleShaderSprite2D

var PULL_FORCE := 5


func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	killbox_area_2d.body_entered.connect(_on_killbox_area_2d_body_entered)
	
	player_body.apply_central_impulse(Vector2.DOWN * 1000)
	
	GameManager.pulled_bodies.append(player_body)
	
	GameManager.is_round_active = true


func _physics_process(_delta):
	for body in GameManager.pulled_bodies:
		if is_instance_valid(body):
			body.apply_central_force((killbox_area_2d.position - body.position) * PULL_FORCE)
	
	if not is_instance_valid(player_body):
		if Input.is_action_just_pressed("Reload"):
			GameManager.reset()
			get_tree().call_deferred("reload_current_scene")


func _process(_delta):
	var black_hole_visuals_coefficient = fmod(GameManager.score / 12.0, 25)
	black_hole_shader_sprite_2d.material.set_shader_parameter("size", black_hole_visuals_coefficient)
	black_hole_shader_sprite_2d.material.set_shader_parameter(
		"opacity", (25.0 - black_hole_visuals_coefficient) / 2.0
	)


func _on_spawn_timer_timeout():
	spawn_path_follow_2d.progress_ratio = randf_range(0, 1)
	var spawn_position = spawn_path_follow_2d.position
	
	var obstacle = obstacle_scene.instantiate()
	obstacle.position = spawn_position
	add_child(obstacle)
	
	GameManager.pulled_bodies.append(obstacle)


func _on_killbox_area_2d_body_entered(body):
	if body == player_body:
		GameManager.is_round_active = false
		spawn_timer.stop()
		body.die()
	elif body.is_in_group("obstacle"):
		body.expire(true)
	else:
		body.expire()
