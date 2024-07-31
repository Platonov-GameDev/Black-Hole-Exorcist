extends RigidBody2D
class_name PlayerBody


@export var hookshot_scene: PackedScene
@export var hookgrapple_scene: PackedScene

@onready var pupil_base = $Eyehole/PupilBase
@onready var pupil_sprite_2d = $Eyehole/PupilBase/PupilSprite2D
@onready var blink_timer = $Eyehole/BlinkTimer
@onready var eyehole_animated_sprite_2d = $Eyehole/EyeholeAnimatedSprite2D
@onready var thruster_emitters = $ThrusterEmitters
@onready var right_thruster_gpu_particles_2d = $ThrusterEmitters/RightThrusterGPUParticles2D
@onready var left_thruster_gpu_particles_2d = $ThrusterEmitters/LeftThrusterGPUParticles2D
@onready var up_thruster_gpu_particles_2d = $ThrusterEmitters/UpThrusterGPUParticles2D
@onready var down_thruster_gpu_particles_2d = $ThrusterEmitters/DownThrusterGPUParticles2D
@onready var obstacle_passer_area_2d = $ObstaclePasserArea2D

var ACCELERATION := 30000
var TORQUE_SPEED := 1000000
var MAX_PUPIL_OFFSET := 8.0
var FLUNG_THRESHOLD_VELOCITY := 1000

var is_dead := false
var thruster_emitters_array: Array[GPUParticles2D] = []
var is_hookshot_already_fired := false
var hookshot: CharacterBody2D
var hookgrapple: Node2D
var movement_input := Vector2.ZERO
var camera: Camera2D
var grapple_direction: Vector2
var is_velocity_getting_redirected := false
var chain_vector: Vector2
var max_chain_length: float
var passed_obstacles = []
var previous_velocity: Vector2

signal acted


func _ready():
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	eyehole_animated_sprite_2d.animation_finished.connect(_on_eyehole_animated_sprite_2d_animation_finished)
	obstacle_passer_area_2d.body_entered.connect(_on_obstacle_passer_area_2d_body_entered)
	
	for emitter in thruster_emitters.get_children():
		thruster_emitters_array.append(emitter as GPUParticles2D)
	
	apply_torque_impulse(1000)
	
	previous_velocity = linear_velocity


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
	
	# Rotate obstacle passer
	obstacle_passer_area_2d.rotation = -rotation


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
	apply_central_force(movement_input * delta * ACCELERATION)
	
	# Fire and release hook shot
	if Input.is_action_just_pressed("Shoot") and not is_hookshot_already_fired:
		is_hookshot_already_fired = true
		hookshot = hookshot_scene.instantiate()
		hookshot.position = global_position
		hookshot.player_body = self
		hookshot.expired.connect(_on_hookshot_expired)
		hookshot.grappled.connect(_on_hookshot_grappled)
		
		# Calculate mouse position (based on screen shader)
		var mouse_screen_position = Vector2(get_tree().root.get_mouse_position())
		mouse_screen_position.x /= 1920.0
		mouse_screen_position.y /= 1080.0
		
		var uv = mouse_screen_position
		if uv.x < 0.5:
			uv.x /= 4.0;
			uv.x += 0.375;
		else:
			uv.x -= 0.5;
			var x = uv.x * 2.0;
			var x_shrinkage = pow(x, 3);
			uv.x /= 4.0 - 3.0 * x_shrinkage;
			uv.x += 0.5;
		uv.y -= 0.5;
		uv.y /= pow(mouse_screen_position.x, .2);
		uv.y += 0.5;
		mouse_screen_position = uv
		
		mouse_screen_position.x *= 7680.0
		mouse_screen_position.y *= 1080.0
		mouse_screen_position.x += camera.get_screen_center_position().x - 7680.0 / 2.0
		
		var hookshot_direction = (mouse_screen_position - position).normalized()
		hookshot.direction = hookshot_direction
		
		add_sibling(hookshot)
		
		acted.emit()
	if Input.is_action_just_released("Shoot"):
		if is_hookshot_already_fired:
			is_hookshot_already_fired = false
			hookshot.call_deferred("queue_free")
			hookshot = null
		elif hookgrapple:
			hookgrapple.call_deferred("queue_free")
			hookgrapple = null
			is_velocity_getting_redirected = false
	
	# Thruster visuals
	var linear_acceleration = (linear_velocity - previous_velocity) / delta
	change_thruster_particles_velocity_min_max(
		linear_velocity.length() * 0.5 + 1000,
		linear_velocity.length() * 0.5 + 1025
	)
	change_thruster_particles_gravity(-linear_acceleration)
	thruster_emitters.rotation = -rotation
	previous_velocity = linear_velocity


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


func _on_hookshot_grappled(collider, collision_point):
	if Input.is_action_pressed("Shoot"):
		hookgrapple = hookgrapple_scene.instantiate()
		hookgrapple.player_body = self
		hookgrapple.obstacle = collider
		hookgrapple.collision_point = collision_point
		grapple_direction = (collision_point - position).normalized()
		
		add_sibling(hookgrapple)


func die():
	is_dead = true
	if hookshot != null:
		hookshot.queue_free()
	if hookgrapple != null:
		hookgrapple.queue_free()
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


func _integrate_forces(state):
	# Reset velocity if grappled in other direction
	if grapple_direction != Vector2.ZERO:
		if sign(state.linear_velocity.x * grapple_direction.x) == -1:
			state.linear_velocity.x = 0
		if sign(state.linear_velocity.y * grapple_direction.y) == -1:
			state.linear_velocity.y = 0
		grapple_direction = Vector2.ZERO
	
	if is_velocity_getting_redirected:
		redirect_velocity_by_chain_tension(state)


func redirect_velocity_by_chain_tension(state: PhysicsDirectBodyState2D):
	var orbit_vector = chain_vector.rotated(deg_to_rad(90))
	var result_velocity_direction = state.linear_velocity.project(orbit_vector).normalized()
	state.linear_velocity = state.linear_velocity.length() * result_velocity_direction
	
	var correct_position_vector = chain_vector.normalized() * max_chain_length
	position = position + chain_vector - correct_position_vector
	
	is_velocity_getting_redirected = false


func _on_obstacle_passer_area_2d_body_entered(body):
	if not passed_obstacles.has(body):
		GameManager.update_score(GameManager.score + 1)
		passed_obstacles.append(body)
