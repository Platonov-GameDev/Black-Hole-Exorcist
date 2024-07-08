extends Node


@export var obstacle_scene: PackedScene
@export var hookshot_scene: PackedScene
@onready var player_rigid_body_2d: RigidBody2D = $Objects/PlayerRigidBody2D
@onready var camera_2d = $Objects/Camera2D
@onready var killbox_area_2d = $Objects/Camera2D/KillboxArea2D
@onready var max_height_reached_label = $UI/MaxHeightReachedLabel
@onready var spawn_timer = $Objects/Camera2D/ObstacleSpawner/SpawnTimer
@onready var obstacle_spawner = $Objects/Camera2D/ObstacleSpawner
@onready var jump_cooldown_timer = $Objects/PlayerRigidBody2D/JumpCooldownTimer
@onready var ui = $UI
@onready var objects = $Objects
var MOVE_SPEED := 70000
var FLOOR_MOVE_MULTIPLIER := 3000
var JUMP_SPEED := 1050
var CAM_Y_OFFSET := -150
var CAM_X_OFFSET := 200
var SCORE_COEFFICIENT := 0.1
var KILLBOX_MOVE_SPEED := 100
var OBSTACLE_SPAWN_OFFSET := 50
var is_player_dead := false
var player_starting_height: float
var max_height_reached: float
var is_hookshot_already_fired := false
var hookshot: CharacterBody2D
var hookgrapple: Node2D


func _ready():
	killbox_area_2d.body_entered.connect(_on_killbox_area_2d_body_entered)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	player_starting_height = player_rigid_body_2d.position.y
	update_max_height_reached(0.0)


func _process(delta):
	if not is_player_dead:
		# Move camera
		if player_rigid_body_2d.position.x + CAM_X_OFFSET > camera_2d.position.x:
			camera_2d.position.x = player_rigid_body_2d.position.x + CAM_X_OFFSET
		camera_2d.position.x += KILLBOX_MOVE_SPEED * delta
		camera_2d.position.y = player_rigid_body_2d.position.y + CAM_Y_OFFSET
		
		# Update max height if needed
		var current_height = snapped((-player_rigid_body_2d.position.y + player_starting_height) * SCORE_COEFFICIENT, 1)
		if current_height > max_height_reached:
			update_max_height_reached(current_height)
		
		# Fire and release hook shot
		if Input.is_action_just_pressed("Shoot") and not is_hookshot_already_fired:
			is_hookshot_already_fired = true
			hookshot = hookshot_scene.instantiate()
			hookshot.position = player_rigid_body_2d.position
			hookshot.player_body = player_rigid_body_2d
			hookshot.expired.connect(_on_hookshot_expired)
			hookshot.grappled.connect(_on_hookshot_grappled)
			var mouse_position = objects.get_global_mouse_position()
			var hookshot_direction = (mouse_position - player_rigid_body_2d.position).normalized()
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


func _physics_process(delta):
	if not is_player_dead:
		# Apply player movement forces
		var movement_input := 0.0
		if Input.is_action_pressed("Left"):
			movement_input -= 1.0
		if Input.is_action_pressed("Right"):
			movement_input += 1.0
		player_rigid_body_2d.apply_force(Vector2.RIGHT * movement_input * MOVE_SPEED * delta)
		
		var is_player_on_floor := false
		for body in player_rigid_body_2d.get_colliding_bodies():
			if body.is_in_group("ground"):
				is_player_on_floor = true
				break
		
		if Input.is_action_pressed("Jump") and is_player_on_floor and jump_cooldown_timer.is_stopped():
			player_rigid_body_2d.apply_central_impulse(Vector2.UP * JUMP_SPEED)
			jump_cooldown_timer.start()
	elif is_player_dead:
		if Input.is_action_just_pressed("Reload"):
			get_tree().call_deferred("reload_current_scene")


func _on_killbox_area_2d_body_entered(_body):
	if is_player_dead: return
	
	player_rigid_body_2d.call_deferred("queue_free")
	if hookshot:
		hookshot.call_deferred("queue_free")
	if hookgrapple:
		hookgrapple.call_deferred("queue_free")
	is_player_dead = true


func update_max_height_reached(new_max_height):
	max_height_reached = new_max_height
	max_height_reached_label.text = "Current: " + str(max_height_reached)


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
