extends RigidBody2D
class_name PlayerBody


@export var hookshot_scene: PackedScene

@onready var pupil_base = $Eyehole/PupilBase
@onready var pupil_sprite_2d = $Eyehole/PupilBase/PupilSprite2D
@onready var blink_timer = $Eyehole/BlinkTimer
@onready var eyehole_animated_sprite_2d = $Eyehole/EyeholeAnimatedSprite2D
@onready var thruster_emitters = $ThrusterEmitters
@onready var right_thruster_gpu_particles_2d = $ThrusterEmitters/RightThrusterGPUParticles2D
@onready var left_thruster_gpu_particles_2d = $ThrusterEmitters/LeftThrusterGPUParticles2D
@onready var up_thruster_gpu_particles_2d = $ThrusterEmitters/UpThrusterGPUParticles2D
@onready var down_thruster_gpu_particles_2d = $ThrusterEmitters/DownThrusterGPUParticles2D
@onready var jump_cooldown_timer = $JumpCooldownTimer

var MOVE_SPEED := 40000
var TORQUE_SPEED := 1000000
var FALL_SPEED := 80000
var HOVER_SPEED := 80000
var JUMP_SPEED := 800
var MAX_PUPIL_OFFSET := 12.0
var FLUNG_THRESHOLD_VELOCITY := 1000

var is_dead := false
var thruster_emitters_array: Array[GPUParticles2D] = []
var is_hookshot_already_fired := false
var hookshot: CharacterBody2D
var hookgrapple: Node2D
var movement_input := 0.0
var is_on_floor := false
var is_flung := false


func _ready():
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	eyehole_animated_sprite_2d.animation_finished.connect(_on_eyehole_animated_sprite_2d_animation_finished)
	
	for emitter in thruster_emitters.get_children():
		thruster_emitters_array.append(emitter as GPUParticles2D)


func _process(_delta):
	# Move pupil
	var mouse_screen_position = Vector2(get_tree().root.get_mouse_position())
	
	var player_screen_position = get_global_transform_with_canvas().get_origin()
	player_screen_position.x -= 2880
	player_screen_position.y -= 540
	player_screen_position.y /= pow(player_screen_position.x / 1920.0, .2)
	player_screen_position.y += 540
	
	var mouse_vector = mouse_screen_position - player_screen_position
	
	pupil_sprite_2d.global_position = (pupil_base.global_position +
		(mouse_vector / 15.0).limit_length(MAX_PUPIL_OFFSET))


func _physics_process(delta):
	# Apply player movement forces
	movement_input = 0.0
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
	apply_force(Vector2.RIGHT * movement_input * MOVE_SPEED * delta)
	apply_torque(movement_input * TORQUE_SPEED * delta)
	
	if Input.is_action_pressed("Fall"):
		apply_force(Vector2.DOWN * FALL_SPEED * delta)
		up_thruster_gpu_particles_2d.emitting = true
	else:
		up_thruster_gpu_particles_2d.emitting = false
	
	is_on_floor = false
	for body in get_colliding_bodies():
		if body.is_in_group("ground"):
			is_on_floor = true
			break
	
	if Input.is_action_pressed("Jump"):
		apply_force(Vector2.UP * HOVER_SPEED * delta)
		if is_on_floor and jump_cooldown_timer.is_stopped():
			apply_central_impulse(Vector2.UP * JUMP_SPEED)
			jump_cooldown_timer.start()
		down_thruster_gpu_particles_2d.emitting = true
	else:
		down_thruster_gpu_particles_2d.emitting = false
	
	# Fire and release hook shot
	if Input.is_action_just_pressed("Shoot") and not is_hookshot_already_fired:
		is_hookshot_already_fired = true
		hookshot = hookshot_scene.instantiate()
		hookshot.position = global_position
		hookshot.player_body = self
		hookshot.expired.connect(_on_hookshot_expired)
		hookshot.grappled.connect(_on_hookshot_grappled)
		
		var mouse_screen_position = Vector2(get_tree().root.get_mouse_position())
		
		var player_screen_position = get_global_transform_with_canvas().get_origin()
		player_screen_position.x -= 2880
		player_screen_position.y -= 540
		player_screen_position.y /= pow(player_screen_position.x / 1920.0, .2)
		player_screen_position.y += 540
		
		var hookshot_direction = (mouse_screen_position - player_screen_position).normalized()
		hookshot.direction = hookshot_direction
		add_sibling(hookshot)
	if Input.is_action_just_released("Shoot"):
		if is_hookshot_already_fired:
			is_hookshot_already_fired = false
			hookshot.queue_free()
			hookshot = null
		elif hookgrapple:
			hookgrapple.queue_free()
			hookgrapple = null
	
	# Thruster visuals
	change_thruster_particles_velocity_min_max(
		linear_velocity.length() * 0.8 + 400,
		linear_velocity.length() * 0.8 + 425
	)
	change_thruster_particles_gravity(-linear_velocity * 3)
	thruster_emitters.rotation = -rotation


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


func _on_hookshot_expired():
	is_hookshot_already_fired = false
	hookshot = null


func _on_hookshot_grappled(new_hookgrapple):
	hookgrapple = new_hookgrapple
	add_sibling(hookgrapple)


func _integrate_forces(state):
	# Flung
	is_flung = abs(linear_velocity.x) > FLUNG_THRESHOLD_VELOCITY
	
	# Arcadify movement
	if not is_flung:
		if movement_input != 0.0:
			state.linear_velocity.x = movement_input * FLUNG_THRESHOLD_VELOCITY * 0.9
			state.angular_velocity = 10 * movement_input
		else:
			state.linear_velocity.x = state.linear_velocity.x * 0.95
			state.angular_velocity = state.angular_velocity * 0.95


func die():
	is_dead = true
	if hookshot != null:
		hookshot.queue_free()
	if hookgrapple != null:
		hookgrapple.queue_free()
	call_deferred("queue_free")
