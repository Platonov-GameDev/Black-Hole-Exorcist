extends CharacterBody2D
class_name PlayerBody


@export var camera: Camera2D
@export var bullet_scene: PackedScene

@onready var pupil_base = $Eyehole/PupilBase
@onready var pupil_sprite_2d = $Eyehole/PupilBase/PupilSprite2D
@onready var blink_timer = $Eyehole/BlinkTimer
@onready var eyehole_animated_sprite_2d = $Eyehole/EyeholeAnimatedSprite2D
@onready var thruster_emitters = $ThrusterEmitters
@onready var right_thruster_gpu_particles_2d = $ThrusterEmitters/RightThrusterGPUParticles2D
@onready var left_thruster_gpu_particles_2d = $ThrusterEmitters/LeftThrusterGPUParticles2D
@onready var up_thruster_gpu_particles_2d = $ThrusterEmitters/UpThrusterGPUParticles2D
@onready var down_thruster_gpu_particles_2d = $ThrusterEmitters/DownThrusterGPUParticles2D
@onready var shoot_timer = $ShootTimer

var MOVE_SPEED := 500
var MAX_PUPIL_OFFSET := 8.0
var FLUNG_THRESHOLD_VELOCITY := 1000
var DEFAULT_SHOOT_COOLDOWN := 0.15

var is_dead := false
var thruster_emitters_array: Array[GPUParticles2D] = []
var movement_input := Vector2.ZERO
var current_power_level := 0
var is_shoot_button_held := false

signal acted


func _ready():
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	eyehole_animated_sprite_2d.animation_finished.connect(_on_eyehole_animated_sprite_2d_animation_finished)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	GameManager.power_changed.connect(_on_game_manager_power_changed)
	
	for emitter in thruster_emitters.get_children():
		thruster_emitters_array.append(emitter as GPUParticles2D)
	
	GameManager.player_body = self


func _process(_delta):
	# Move pupil
	var mouse_vector = GameManager.mouse_position - position
	
	pupil_sprite_2d.global_position = (pupil_base.global_position +
		(mouse_vector / 15.0).limit_length(MAX_PUPIL_OFFSET))


func _physics_process(delta):
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
	move_and_collide(movement_input * delta * MOVE_SPEED)
	
	# Shooting
	if Input.is_action_just_pressed("Shoot"):
		if shoot_timer.is_stopped():
			shoot()
			shoot_timer.start()
		is_shoot_button_held = true
	if Input.is_action_just_released("Shoot"):
		is_shoot_button_held = false


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


func _on_shoot_timer_timeout():
	if is_shoot_button_held:
		shoot()
		shoot_timer.start()


func shoot():
	var bullet = bullet_scene.instantiate() as CharacterBody2D
	bullet.position = position
	bullet.look_at(GameManager.mouse_position)
	add_sibling(bullet)
	
	if current_power_level == 0:
		AudioPlayer.shot_1_audio.play()
	elif current_power_level == 1:
		AudioPlayer.shot_2_audio.play()
	elif current_power_level == 2:
		AudioPlayer.shot_3_audio.play()
	elif current_power_level == 3:
		AudioPlayer.shot_4_audio.play()


func _on_game_manager_power_changed(new_power):
	if new_power >= 10 and current_power_level < 1:
		shoot_timer.wait_time = 0.2
		current_power_level = 1
		AudioPlayer.power_up_audio.play()
	if new_power >= 30 and current_power_level < 2:
		shoot_timer.wait_time = 0.10
		current_power_level = 2
		AudioPlayer.power_up_audio.play()
	if new_power >= 70 and current_power_level < 3:
		shoot_timer.wait_time = 0.05
		current_power_level = 3
		AudioPlayer.power_up_audio.play()
