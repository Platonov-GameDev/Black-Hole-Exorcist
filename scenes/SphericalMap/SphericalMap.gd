extends Node2D


@export var obstacle_scene: PackedScene

@onready var player_body = $PlayerBody
@onready var camera_2d = $Camera2D
@onready var spawn_path_follow_2d = $SpawnPath2D/SpawnPathFollow2D
@onready var black_hole_shader_sprite_2d = $BlackHoleShaderSprite2D

var spawn_time_counter := 0.0
var spawn_entities_counter := 0
var black_hole_shader_time := 0.0
var time_since_start := 0.0


func _ready():
	GameManager.is_round_active = true
	
	GameManager.black_hole_position = black_hole_shader_sprite_2d.position


func _process(delta):
	time_since_start += delta
	var black_hole_visuals_coefficient = fmod(time_since_start / 12.0, 25)
	black_hole_shader_sprite_2d.material.set_shader_parameter("size", black_hole_visuals_coefficient)
	black_hole_shader_sprite_2d.material.set_shader_parameter(
		"opacity", (25.0 - black_hole_visuals_coefficient) / 2.0
	)
	black_hole_shader_time += delta * GameManager.calculate_time_coefficient(Vector2(0, 0))
	black_hole_shader_sprite_2d.material.set_shader_parameter("time", black_hole_shader_time)
	
	if is_instance_valid(player_body):
		GameManager.player_distance_from_black_hole = (
			(player_body.position - black_hole_shader_sprite_2d.position).length()
		)
	else:
		if Input.is_action_just_pressed("Reload"):
			GameManager.reset()
			get_tree().call_deferred("reload_current_scene")
	
	# Spawn obstacles
	if GameManager.is_round_active:
		spawn_time_counter += delta * GameManager.calculate_time_coefficient(Vector2(1500, 1500))
		
		var entities_that_had_to_spawn = floori(spawn_time_counter / 20)
		while spawn_entities_counter < entities_that_had_to_spawn:
			var repeat_spawn_counter = floori(spawn_entities_counter / 20)
			var i = 0
			while i < repeat_spawn_counter:
				spawn_obstacle()
				i += 1
			
			spawn_obstacle()
			spawn_entities_counter += 1


func spawn_obstacle():
	spawn_path_follow_2d.progress_ratio = randf_range(0, 1)
	var spawn_position = spawn_path_follow_2d.position
	
	var obstacle = obstacle_scene.instantiate() as Obstacle_SmoothBoulder
	obstacle.position = spawn_position
	obstacle.movement_direction = (
		(black_hole_shader_sprite_2d.position - obstacle.position).normalized()
	)
	add_child(obstacle)
