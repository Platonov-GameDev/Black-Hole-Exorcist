extends Node2D


@export var enemy_scene: PackedScene

@onready var player_body = $PlayerBody
@onready var camera_2d = $Camera2D
@onready var black_hole_shader_sprite_2d = $BlackHoleShaderSprite2D

var SPAWN_DISTANCE_FROM_CENTER = 3300

var spawn_time_counter := 0.0
var spawn_entities_counter := 0
var black_hole_shader_time := 0.0


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
	
	# Spawn obstacles
	if GameManager.is_round_active:
		spawn_time_counter += delta * GameManager.calculate_time_coefficient(Vector2(1500, 1500))
		
		var entities_that_had_to_spawn = floori(spawn_time_counter / 20)
		while spawn_entities_counter < entities_that_had_to_spawn:
			var repeat_spawn_counter = floori(spawn_entities_counter / 20)
			
			spawn_enemies(1 + repeat_spawn_counter)
			
			spawn_entities_counter += 1


func spawn_enemies(count: int):
	var spawn_angle_offset = 2 * PI / (count + 1)
	var center_to_player_vector = (player_body.position - black_hole_shader_sprite_2d.position).normalized()
	if center_to_player_vector.length() == 0:
		center_to_player_vector = Vector2.UP.rotated(randf_range(0, 2 * PI))
	
	for i in range(count):
		var spawn_position = (
			center_to_player_vector.rotated((i + 1) * spawn_angle_offset)
			* SPAWN_DISTANCE_FROM_CENTER
		)
		
		var enemy = enemy_scene.instantiate() as Enemy_Mouth
		enemy.position = spawn_position
		enemy.movement_direction = enemy.get_restricted_movement_vector(
			(black_hole_shader_sprite_2d.position - enemy.position).normalized()
		)
		add_child(enemy)
