extends Node2D


@onready var player_rigid_body_2d = $PlayerRigidBody2D
@onready var jump_cooldown_timer = $PlayerRigidBody2D/JumpCooldownTimer
@export var hookshot_scene: PackedScene

var MOVE_SPEED := 70000
var TORQUE_SPEED := 1000000
var FALL_SPEED := 70000
var HOVER_SPEED := 60000
var FLOOR_MOVE_MULTIPLIER := 3000
var JUMP_SPEED := 800

var is_hookshot_already_fired := false
var hookshot: CharacterBody2D
var hookgrapple: Node2D


func _physics_process(delta):
	# Apply player movement forces
	var movement_input := 0.0
	if Input.is_action_pressed("Left"):
		movement_input -= 1.0
	if Input.is_action_pressed("Right"):
		movement_input += 1.0
	player_rigid_body_2d.apply_force(Vector2.RIGHT * movement_input * MOVE_SPEED * delta)
	player_rigid_body_2d.apply_torque(movement_input * TORQUE_SPEED * delta)
	
	if Input.is_action_pressed("Fall"):
		player_rigid_body_2d.apply_force(Vector2.DOWN * FALL_SPEED * delta)
	
	var is_player_on_floor := false
	for body in player_rigid_body_2d.get_colliding_bodies():
		if body.is_in_group("ground"):
			is_player_on_floor = true
			break
	
	if Input.is_action_pressed("Jump"):
		player_rigid_body_2d.apply_force(Vector2.UP * HOVER_SPEED * delta)
		if is_player_on_floor and jump_cooldown_timer.is_stopped():
			player_rigid_body_2d.apply_central_impulse(Vector2.UP * JUMP_SPEED)
			jump_cooldown_timer.start()
	
	# Fire and release hook shot
	if Input.is_action_just_pressed("Shoot") and not is_hookshot_already_fired:
		is_hookshot_already_fired = true
		hookshot = hookshot_scene.instantiate()
		hookshot.position = player_rigid_body_2d.position
		hookshot.player_body = player_rigid_body_2d
		hookshot.expired.connect(_on_hookshot_expired)
		hookshot.grappled.connect(_on_hookshot_grappled)
		
		var mouse_screen_position = Vector2(get_tree().root.get_mouse_position())
		
		var player_screen_position = player_rigid_body_2d.get_global_transform_with_canvas().get_origin()
		
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


func _on_hookshot_expired():
	is_hookshot_already_fired = false
	hookshot = null


func _on_hookshot_grappled(new_hookgrapple):
	hookgrapple = new_hookgrapple
	add_child(hookgrapple)

