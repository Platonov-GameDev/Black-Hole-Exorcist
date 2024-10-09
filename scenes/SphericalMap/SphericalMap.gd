extends Node2D


@export var mouth_scene: PackedScene
@export var triangle_scene: PackedScene

@onready var player_body = $PlayerBody
@onready var camera_2d = $Camera2D
@onready var black_hole_shader_sprite_2d = $BlackHoleShaderSprite2D
@onready var spawn_waves = $SpawnWaves

var SPAWN_DISTANCE_FROM_CENTER = 3300

var spawn_time_counter := 0.0
var black_hole_shader_time := 0.0
var spawn_wave_count := 0


func _ready():
	GameManager.is_round_active = true
	
	GameManager.black_hole_position = black_hole_shader_sprite_2d.position


func _process(delta):
	var black_hole_visuals_coefficient = GameManager.time_since_start / 12.0
	black_hole_shader_sprite_2d.material.set_shader_parameter("size", black_hole_visuals_coefficient)
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
	
	# Spawn enemies
	if GameManager.is_round_active:
		spawn_time_counter += delta * GameManager.calculate_time_coefficient(Vector2(0, 0))
		
		if spawn_time_counter >= 1:
			spawn_wave_count = clampi(spawn_wave_count, 0, spawn_waves.get_child_count() - 1)
			spawn_enemies(spawn_waves.get_child(spawn_wave_count))
			spawn_time_counter = 0
			spawn_wave_count += 1
	
	# Set camera zoom
	var cam_zoom = clampf(1.38 - 0.68 * (GameManager.time_since_start / 300.0), 0.7, 1.38)
	camera_2d.zoom = Vector2(cam_zoom, cam_zoom)


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
