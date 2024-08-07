extends Node2D


@export var obstacle_scene: PackedScene

@onready var player_body = $PlayerBody
@onready var camera_2d = $Camera2D
@onready var spawn_path_follow_2d = $SpawnPath2D/SpawnPathFollow2D
@onready var spawn_timer = $SpawnTimer
@onready var black_hole_shader_sprite_2d = $BlackHoleShaderSprite2D

var PULL_FORCE := 5


func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	GameManager.score_changed.connect(_on_game_manager_score_changed)
	
	GameManager.is_round_active = true


func _physics_process(_delta):	
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
	
	var obstacle = obstacle_scene.instantiate() as Obstacle_SmoothBoulder
	obstacle.position = spawn_position
	obstacle.movement_direction = (
		(black_hole_shader_sprite_2d.position - obstacle.position).normalized()
	)
	add_child(obstacle)


func _on_game_manager_score_changed(new_score):
	spawn_timer.wait_time = clampf(2 - clampf(new_score, 0, 300) / 80.0, 0.25, 2)
