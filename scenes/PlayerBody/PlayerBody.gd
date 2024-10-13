extends CharacterBody2D
class_name PlayerBody


@export var camera: Camera2D
@export var bullet_scene: PackedScene
@export var sniper_ray_scene: PackedScene

@onready var pupil_base = $Eyehole/PupilBase
@onready var pupil_sprite_2d = $Eyehole/PupilBase/PupilSprite2D
@onready var blink_timer = $Eyehole/BlinkTimer
@onready var eyehole_animated_sprite_2d = $Eyehole/EyeholeAnimatedSprite2D
@onready var thruster_emitters = $ThrusterEmitters
@onready var right_thruster_gpu_particles_2d = $ThrusterEmitters/RightThrusterGPUParticles2D
@onready var left_thruster_gpu_particles_2d = $ThrusterEmitters/LeftThrusterGPUParticles2D
@onready var up_thruster_gpu_particles_2d = $ThrusterEmitters/UpThrusterGPUParticles2D
@onready var down_thruster_gpu_particles_2d = $ThrusterEmitters/DownThrusterGPUParticles2D
@onready var shoot_rapid_cooldown_timer = $ShootRapidCooldownTimer
@onready var shoot_sniper_prepare_timer = $ShootSniperPrepareTimer
@onready var shoot_sniper_cooldown_timer = $ShootSniperCooldownTimer

var MOVE_SPEED := 1200
var PUPIL_OFFSET := 26.0
var DEFAULT_SHOOT_COOLDOWN := 0.15
var MUZZLE_DISTANCE := 300

var is_dead := false
var thruster_emitters_array: Array[GPUParticles2D] = []
var movement_input := Vector2.ZERO
var shooting_input := Vector2.ZERO
var previous_shooting_input := Vector2.ZERO
var current_power_level := 0
var is_shooting_rapid := false
var buffered_sniper_direction_vectors: Array[Vector2] = []

signal acted


func _ready():
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	eyehole_animated_sprite_2d.animation_finished.connect(_on_eyehole_animated_sprite_2d_animation_finished)
	shoot_rapid_cooldown_timer.timeout.connect(_on_shoot_rapid_cooldown_timer_timeout)
	shoot_sniper_prepare_timer.timeout.connect(_on_shoot_sniper_prepare_timer_timeout)
	shoot_sniper_cooldown_timer.timeout.connect(_on_shoot_sniper_cooldown_timer_timeout)
	GameManager.power_changed.connect(_on_game_manager_power_changed)
	
	for emitter in thruster_emitters.get_children():
		thruster_emitters_array.append(emitter as GPUParticles2D)
	
	GameManager.player_body = self


func _process(delta):
	# Apply player movement forces
	movement_input = Vector2.ZERO
	if Input.is_action_pressed("Left"):
		move_in_direction(Vector2.LEFT)
	else:
		move_in_direction(Vector2.LEFT, false)
	if Input.is_action_pressed("Right"):
		move_in_direction(Vector2.RIGHT)
	else:
		move_in_direction(Vector2.RIGHT, false)
	if Input.is_action_pressed("Up"):
		move_in_direction(Vector2.UP)
	else:
		move_in_direction(Vector2.UP, false)
	if Input.is_action_pressed("Down"):
		move_in_direction(Vector2.DOWN)
	else:
		move_in_direction(Vector2.DOWN, false)
	if movement_input.length() != 0 and not AudioPlayer.thruster_active_loop_audio.playing:
		AudioPlayer.thruster_active_loop_audio.play()
	elif movement_input.length() == 0:
		AudioPlayer.thruster_active_loop_audio.stop()
	velocity = movement_input * MOVE_SPEED
	move_and_slide()
	
	# Shooting
	#is_shoot_button_held = false
	previous_shooting_input = shooting_input
	shooting_input = Vector2.ZERO
	if Input.is_action_pressed("Shoot down"):
		update_shooting_input(Vector2.DOWN)
	if Input.is_action_pressed("Shoot up"):
		update_shooting_input(Vector2.UP)
	if Input.is_action_pressed("Shoot left"):
		update_shooting_input(Vector2.LEFT)
	if Input.is_action_pressed("Shoot right"):
		update_shooting_input(Vector2.RIGHT)
	# Start charging sniper
	if (
		shooting_input.length() != 0
		and shoot_sniper_cooldown_timer.is_stopped()
		and shoot_sniper_prepare_timer.is_stopped()
		and shoot_rapid_cooldown_timer.is_stopped()
	):
		shoot_sniper_prepare_timer.start()
		buffered_sniper_direction_vectors.clear()
		buffered_sniper_direction_vectors.append(shooting_input)
	# Release sniper
	elif (
		previous_shooting_input.length() != 0
		and shooting_input.length() == 0
		and not shoot_sniper_prepare_timer.is_stopped()
	):
		shoot_sniper()
		shoot_sniper_prepare_timer.stop()
		shoot_sniper_cooldown_timer.start()
	# Stop shooting rapid
	elif (
		shooting_input.length() == 0
		and previous_shooting_input.length() != 0
		and is_shooting_rapid
	):
		is_shooting_rapid = false
	# rapid fire also starts in shoot_sniper_prepare_timer timeout
	
	# Move pupil
	pupil_sprite_2d.global_position = (pupil_base.global_position +
		shooting_input * PUPIL_OFFSET)
	
	# Game end
	if GameManager.time_since_start >= 300:
		die()


func _on_blink_timer_timeout():
	eyehole_animated_sprite_2d.play("blink")
	
	blink_timer.wait_time = randf_range(3.0, 6.0)
	blink_timer.start()


func _on_eyehole_animated_sprite_2d_animation_finished():
	if eyehole_animated_sprite_2d.animation == "blink":
		eyehole_animated_sprite_2d.play("idle")


func change_thruster_particles_velocity_min_max(min_velocity: float, max_velocity: float):
	for emitter in thruster_emitters_array:
		emitter.process_material.initial_velocity_min = min_velocity
		emitter.process_material.initial_velocity_max = max_velocity


func change_thruster_particles_gravity(new_gravity: Vector2):
	for emitter in thruster_emitters_array:
		emitter.process_material.gravity.x = new_gravity.x
		emitter.process_material.gravity.y = new_gravity.y


func die():
	is_dead = true
	GameManager.is_round_active = false
	call_deferred("queue_free")
	AudioPlayer.thruster_active_loop_audio.stop()


func move_in_direction(direction: Vector2, is_moving := true):
	match direction:
		Vector2.LEFT:
			right_thruster_gpu_particles_2d.emitting = is_moving
		Vector2.RIGHT:
			left_thruster_gpu_particles_2d.emitting = is_moving
		Vector2.UP:
			down_thruster_gpu_particles_2d.emitting = is_moving
		Vector2.DOWN:
			up_thruster_gpu_particles_2d.emitting = is_moving
	if is_moving:
		movement_input = (movement_input + direction)
		acted.emit()


func update_shooting_input(input_direction: Vector2):
	shooting_input = (shooting_input + input_direction).normalized()
	if not shoot_sniper_prepare_timer.is_stopped():
		if not buffered_sniper_direction_vectors.has(input_direction):
			buffered_sniper_direction_vectors.append(input_direction)


func _on_shoot_rapid_cooldown_timer_timeout():
	if is_shooting_rapid:
		shoot_rapid()
		shoot_rapid_cooldown_timer.start()


func shoot_rapid():
	var bullet = bullet_scene.instantiate() as CharacterBody2D
	bullet.position = position + shooting_input * MUZZLE_DISTANCE
	bullet.look_at(bullet.position + shooting_input)
	var max_deviation = current_power_level * PI / 32.0
	bullet.rotation += randf_range(-max_deviation, max_deviation)
	add_sibling(bullet)
	
	if current_power_level == 0:
		AudioPlayer.shot_1_audio.play()
	elif current_power_level == 1:
		AudioPlayer.shot_2_audio.play()
	elif current_power_level == 2:
		AudioPlayer.shot_3_audio.play()
	elif current_power_level == 3:
		AudioPlayer.shot_4_audio.play()


func _on_shoot_sniper_prepare_timer_timeout():
	is_shooting_rapid = true
	shoot_rapid()
	shoot_rapid_cooldown_timer.start()


func _on_shoot_sniper_cooldown_timer_timeout():
	if is_shooting_rapid:
		shoot_rapid()
		shoot_rapid_cooldown_timer.start()


func shoot_sniper():
	var shot_direction = Vector2.ZERO
	for buffered_direction_vector in buffered_sniper_direction_vectors:
		shot_direction += buffered_direction_vector
	shot_direction = shot_direction.normalized()
	if shot_direction.length() == 0: return
	
	if current_power_level == 0:
		spawn_sniper_ray(shot_direction)
	elif current_power_level == 1:
		spawn_sniper_ray(shot_direction, 1)
		spawn_sniper_ray(shot_direction, -1)
	elif current_power_level == 2:
		spawn_sniper_ray(shot_direction, 1)
		spawn_sniper_ray(shot_direction, -1)
		spawn_sniper_ray(shot_direction, 3)
		spawn_sniper_ray(shot_direction, -3)
	elif current_power_level == 3:
		spawn_sniper_ray(shot_direction, 1)
		spawn_sniper_ray(shot_direction, -1)
		spawn_sniper_ray(shot_direction, 3)
		spawn_sniper_ray(shot_direction, -3)
		spawn_sniper_ray(shot_direction, 5)
		spawn_sniper_ray(shot_direction, -5)
		spawn_sniper_ray(shot_direction, 7)
		spawn_sniper_ray(shot_direction, -7)
	
	AudioPlayer.sniper_shot_audio.play()


func spawn_sniper_ray(shot_direction: Vector2, deviation := 0.0):
	var sniper_ray = sniper_ray_scene.instantiate() as Node2D
	sniper_ray.look_at(shot_direction)
	sniper_ray.rotation += deviation * PI / 256.0
	sniper_ray.position = position + shot_direction * MUZZLE_DISTANCE
	add_sibling(sniper_ray)


func _on_game_manager_power_changed(new_power):
	if new_power >= 10 and current_power_level < 1:
		shoot_rapid_cooldown_timer.wait_time = 0.05
		current_power_level = 1
		AudioPlayer.power_up_audio.play()
	if new_power >= 30 and current_power_level < 2:
		shoot_rapid_cooldown_timer.wait_time = 0.025
		current_power_level = 2
		AudioPlayer.power_up_audio.play()
	if new_power >= 70 and current_power_level < 3:
		shoot_rapid_cooldown_timer.wait_time = 0.0125
		current_power_level = 3
		AudioPlayer.power_up_audio.play()
