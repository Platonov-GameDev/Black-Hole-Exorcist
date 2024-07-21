extends Node2D


@export var obstacle_scene: PackedScene
@export var hookshot_scene: PackedScene

@onready var killbox_area_2d = $Camera2D/KillboxArea2D
@onready var obstacle_spawner = $Camera2D/ObstacleSpawner
@onready var spawn_timer = $Camera2D/ObstacleSpawner/SpawnTimer
@onready var camera_2d = $Camera2D
@onready var black_hole_sprite_2d = $Camera2D/BlackHoleSprite2D
@onready var close_stars_sprite_2d = $Camera2D/Background/CloseStarsSprite2D
@onready var far_stars_sprite_2d = $Camera2D/Background/FarStarsSprite2D
@onready var black_hole_arm = $Camera2D/BlackHoleArm
@onready var player_body = $PlayerBody
@onready var jump_cooldown_timer = $PlayerBody/JumpCooldownTimer
@onready var eyehole_animated_sprite_2d = $PlayerBody/Eyehole/EyeholeAnimatedSprite2D
@onready var pupil_base = $PlayerBody/Eyehole/PupilBase
@onready var pupil_sprite_2d = $PlayerBody/Eyehole/PupilBase/PupilSprite2D
@onready var blink_timer = $PlayerBody/Eyehole/BlinkTimer
@onready var thruster_emitters = $ThrusterEmitters
@onready var right_thruster_gpu_particles_2d = $ThrusterEmitters/RightThrusterGPUParticles2D
@onready var left_thruster_gpu_particles_2d = $ThrusterEmitters/LeftThrusterGPUParticles2D
@onready var up_thruster_gpu_particles_2d = $ThrusterEmitters/UpThrusterGPUParticles2D
@onready var down_thruster_gpu_particles_2d = $ThrusterEmitters/DownThrusterGPUParticles2D

var MOVE_SPEED := 70000
var TORQUE_SPEED := 1000000
var FALL_SPEED := 80000
var HOVER_SPEED := 80000
var FLOOR_MOVE_MULTIPLIER := 3000
var JUMP_SPEED := 800
var CAM_Y_OFFSET := 0
var CAM_X_OFFSET := 600
var SCORE_COEFFICIENT := 0.1
var KILLBOX_MOVE_SPEED := 100
var OBSTACLE_SPAWN_OFFSET := 50
var MAX_PUPIL_OFFSET := 12.0

var is_player_dead := false
var player_starting_distance: float
var max_distance_reached: float
var is_hookshot_already_fired := false
var hookshot: CharacterBody2D
var hookgrapple: Node2D
var thruster_process_material: ParticleProcessMaterial

signal max_distance_changed(new_max_distance)


func _ready():
	killbox_area_2d.body_entered.connect(_on_killbox_area_2d_body_entered)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	eyehole_animated_sprite_2d.animation_finished.connect(_on_eyehole_animated_sprite_2d_animation_finished)
	
	player_starting_distance = player_body.position.x
	update_max_distance_reached(0.0)
	
	thruster_process_material = right_thruster_gpu_particles_2d.process_material


func _process(delta):
	black_hole_sprite_2d.rotate(delta)
	
	if not is_player_dead:
		# Move camera
		if player_body.position.x + CAM_X_OFFSET > camera_2d.position.x:
			camera_2d.position.x = player_body.position.x + CAM_X_OFFSET
		camera_2d.position.x += KILLBOX_MOVE_SPEED * delta
		camera_2d.position.y = player_body.position.y + CAM_Y_OFFSET
		
		# Update max height if needed
		var current_distance = snapped((player_body.position.x - player_starting_distance) * SCORE_COEFFICIENT, 1)
		if current_distance > max_distance_reached:
			update_max_distance_reached(current_distance)
		
		# Scroll background
		close_stars_sprite_2d.material.set_shader_parameter("player_x", player_body.position.x)
		far_stars_sprite_2d.material.set_shader_parameter("player_x", player_body.position.x)
		
		# Align black hole with cam height
		black_hole_arm.global_position.y = camera_2d.get_screen_center_position().y
		
		# Move pupil
		var mouse_screen_position = Vector2(get_tree().root.get_mouse_position())
		
		var player_screen_position = player_body.get_global_transform_with_canvas().get_origin()
		player_screen_position.x -= 2880
		player_screen_position.y -= 540
		player_screen_position.y /= pow(player_screen_position.x / 1920.0, .2)
		player_screen_position.y += 540
		
		var mouse_vector = mouse_screen_position - player_screen_position
		
		pupil_sprite_2d.global_position = pupil_base.global_position + (mouse_vector / 15.0).limit_length(MAX_PUPIL_OFFSET)


func _physics_process(delta):
	if not is_player_dead:
		# Apply player movement forces
		var movement_input := 0.0
		if Input.is_action_pressed("Left"):
			movement_input -= 1.0
			right_thruster_gpu_particles_2d.emitting = true
		else:
			right_thruster_gpu_particles_2d.emitting = false
		if Input.is_action_pressed("Right"):
			movement_input += 1.0
			left_thruster_gpu_particles_2d.emitting = true
		else:
			left_thruster_gpu_particles_2d.emitting = false
		player_body.apply_force(Vector2.RIGHT * movement_input * MOVE_SPEED * delta)
		player_body.apply_torque(movement_input * TORQUE_SPEED * delta)
		
		if Input.is_action_pressed("Fall"):
			player_body.apply_force(Vector2.DOWN * FALL_SPEED * delta)
			up_thruster_gpu_particles_2d.emitting = true
		else:
			up_thruster_gpu_particles_2d.emitting = false
		
		var is_player_on_floor := false
		for body in player_body.get_colliding_bodies():
			if body.is_in_group("ground"):
				is_player_on_floor = true
				break
		
		if Input.is_action_pressed("Jump"):
			player_body.apply_force(Vector2.UP * HOVER_SPEED * delta)
			if is_player_on_floor and jump_cooldown_timer.is_stopped():
				player_body.apply_central_impulse(Vector2.UP * JUMP_SPEED)
				jump_cooldown_timer.start()
			down_thruster_gpu_particles_2d.emitting = true
		else:
			down_thruster_gpu_particles_2d.emitting = false
		
		# Fire and release hook shot
		if Input.is_action_just_pressed("Shoot") and not is_hookshot_already_fired:
			is_hookshot_already_fired = true
			hookshot = hookshot_scene.instantiate()
			hookshot.position = player_body.position
			hookshot.player_body = player_body
			hookshot.expired.connect(_on_hookshot_expired)
			hookshot.grappled.connect(_on_hookshot_grappled)
			
			var mouse_screen_position = Vector2(get_tree().root.get_mouse_position())
			
			var player_screen_position = player_body.get_global_transform_with_canvas().get_origin()
			player_screen_position.x -= 2880
			player_screen_position.y -= 540
			player_screen_position.y /= pow(player_screen_position.x / 1920.0, .2)
			player_screen_position.y += 540
			
			var hookshot_direction = (mouse_screen_position - player_screen_position).normalized()
			hookshot.direction = hookshot_direction
			add_child(hookshot)
		if Input.is_action_just_released("Shoot"):
			if is_hookshot_already_fired:
				is_hookshot_already_fired = false
				hookshot.queue_free()
				hookshot = null
			elif hookgrapple:
				hookgrapple.queue_free()
				hookgrapple = null
		
		# Thruster visuals
		thruster_emitters.position = player_body.position
		thruster_emitters.change_velocity_min_max(
			player_body.linear_velocity.length() * 0.8 + 400,
			player_body.linear_velocity.length() * 0.8 + 425
		)
		thruster_emitters.change_gravity(-player_body.linear_velocity * 3)
	elif is_player_dead:
		if Input.is_action_just_pressed("Reload"):
			get_tree().call_deferred("reload_current_scene")
		
		right_thruster_gpu_particles_2d.emitting = false
		left_thruster_gpu_particles_2d.emitting = false
		up_thruster_gpu_particles_2d.emitting = false
		down_thruster_gpu_particles_2d.emitting = false


func _on_killbox_area_2d_body_entered(_body):
	if is_player_dead: return
	
	player_body.call_deferred("queue_free")
	if hookshot:
		hookshot.call_deferred("queue_free")
	if hookgrapple:
		hookgrapple.call_deferred("queue_free")
	is_player_dead = true


func update_max_distance_reached(new_max_distance):
	max_distance_reached = new_max_distance
	max_distance_changed.emit(new_max_distance)


func _on_spawn_timer_timeout():
	var new_obstacle := obstacle_scene.instantiate()
	new_obstacle.position = obstacle_spawner.position
	new_obstacle.position.x += randf_range(-OBSTACLE_SPAWN_OFFSET, OBSTACLE_SPAWN_OFFSET)
	new_obstacle.position.y += randf_range(-OBSTACLE_SPAWN_OFFSET, OBSTACLE_SPAWN_OFFSET)
	obstacle_spawner.add_child(new_obstacle, true)


func _on_hookshot_expired():
	is_hookshot_already_fired = false
	hookshot = null


func _on_hookshot_grappled(new_hookgrapple):
	hookgrapple = new_hookgrapple
	add_child(hookgrapple)


func _on_blink_timer_timeout():
	eyehole_animated_sprite_2d.play("blink")
	eyehole_animated_sprite_2d.play
	
	blink_timer.wait_time = randf_range(3.0, 6.0)
	blink_timer.start()


func _on_eyehole_animated_sprite_2d_animation_finished():
	if eyehole_animated_sprite_2d.animation == "blink":
		eyehole_animated_sprite_2d.play("idle")
