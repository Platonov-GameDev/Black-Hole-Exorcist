extends Node2D


@export var mouth_scene: PackedScene
@export var triangle_scene: PackedScene
@export var satellite_scene: PackedScene
@export var experimental_random_spawns := false

@onready var player_body = $PlayerBody
@onready var camera_2d = $Camera2D
@onready var black_hole_shader_sprite_2d = $BlackHoleShaderSprite2D
@onready var spawn_waves = $SpawnWaves
@onready var spawn_timer_circle_sprite_2d = $SpawnTimerCircleSprite2D

var SPAWN_DISTANCE_FROM_CENTER = 600

var spawn_time_counter := 0.0
var black_hole_shader_time := 0.0
var spawn_wave_count := 0
var experimental_enemy_spawn_counter := 1


func _ready():
	GameManager.is_round_active = true
	
	GameManager.black_hole_position = black_hole_shader_sprite_2d.position


func _process(delta):
	var black_hole_visuals_coefficient = GameManager.time_since_start / 12.0
	black_hole_shader_sprite_2d.material.set_shader_parameter("size", black_hole_visuals_coefficient)
	black_hole_shader_time += delta * GameManager.calculate_time_coefficient(Vector2(0, 0))
	black_hole_shader_sprite_2d.material.set_shader_parameter("time", black_hole_shader_time)
	
	if is_instance_valid(player_body):
		GameManager.player_distance_from_black_hole = player_body.position.length()
	else:
		if Input.is_action_just_pressed("Reload"):
			GameManager.reset()
			get_tree().call_deferred("reload_current_scene")
	
	# Spawn enemies
	if GameManager.is_round_active:
		spawn_time_counter += delta * GameManager.calculate_time_coefficient(Vector2(0, 0))
		
		var spawn_timer_circle_scale = (1 - spawn_time_counter) * 0.76
		spawn_timer_circle_sprite_2d.scale = Vector2(spawn_timer_circle_scale, spawn_timer_circle_scale)
		
		if spawn_time_counter >= 1:
			if not experimental_random_spawns:
				spawn_wave_count = clampi(spawn_wave_count, 0, spawn_waves.get_child_count() - 1)
				spawn_enemies(spawn_waves.get_child(spawn_wave_count))
			elif experimental_random_spawns:
				spawn_random_enemies()
			spawn_time_counter = 0
			spawn_wave_count += 1


func spawn_enemies(spawn_wave: SpawnWave):
	var total_enemy_count = spawn_wave.mouth_count + spawn_wave.triangle_count
	
	var spawn_angle_offset = 2 * PI / (total_enemy_count + 1)
	var center_to_player_vector = (player_body.position - black_hole_shader_sprite_2d.position).normalized()
	if center_to_player_vector.length() == 0:
		center_to_player_vector = Vector2.UP.rotated(randf_range(0, 2 * PI))
	
	var mouth_left = spawn_wave.mouth_count
	var triangle_left = spawn_wave.triangle_count
	
	for i in range(total_enemy_count):
		var spawn_position = (
			center_to_player_vector.rotated((i + 1) * spawn_angle_offset)
			* SPAWN_DISTANCE_FROM_CENTER
		)
		
		var enemy_scene
		if mouth_left > 0:
			enemy_scene = mouth_scene
			mouth_left -= 1
		elif triangle_left > 0:
			enemy_scene = triangle_scene
			triangle_left -= 1
		
		var enemy = enemy_scene.instantiate()
		enemy.position = spawn_position
		add_child(enemy)


func spawn_random_enemies():
	var enemies_left_to_spawn = experimental_enemy_spawn_counter
	
	var spawn_angle_offset = 2 * PI / (experimental_enemy_spawn_counter + 1)
	var center_to_player_vector = (player_body.position - black_hole_shader_sprite_2d.position).normalized()
	if center_to_player_vector.length() == 0:
		center_to_player_vector = Vector2.UP.rotated(randf_range(0, 2 * PI))
	
	var triangle = triangle_scene.instantiate()
	triangle.position = (
		center_to_player_vector.rotated(spawn_angle_offset)
		* SPAWN_DISTANCE_FROM_CENTER
	)
	add_child(triangle)
	
	for i in range(experimental_enemy_spawn_counter):
		var spawn_position = (
			center_to_player_vector.rotated((i + 2) * spawn_angle_offset)
			* SPAWN_DISTANCE_FROM_CENTER
		)
		
		var enemy_scenes: Array[PackedScene] = [mouth_scene, satellite_scene]
		var enemy_scene = enemy_scenes.pick_random()
		
		var enemy = enemy_scene.instantiate()
		enemy.position = spawn_position
		add_child(enemy)
	
	experimental_enemy_spawn_counter += 1
