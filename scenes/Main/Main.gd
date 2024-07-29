extends Node2D


@onready var killbox_area_2d = $Camera2D/KillboxArea2D
@onready var camera_2d = $Camera2D
@onready var close_stars_sprite_2d = $Camera2D/Background/CloseStarsSprite2D
@onready var far_stars_sprite_2d = $Camera2D/Background/FarStarsSprite2D
@onready var black_hole_arm = $Camera2D/BlackHoleArm
@onready var player_body: PlayerBody = $PlayerBody

var CAM_X_OFFSET := 100
var KILLBOX_MOVE_SPEED := 200
var OBSTACLE_SPAWN_OFFSET := 50

var did_player_act := false


func _ready():
	killbox_area_2d.body_entered.connect(_on_killbox_area_2d_body_entered)
	player_body.acted.connect(_on_player_body_acted)
	
	player_body.camera = camera_2d
	
	PhysicsServer2D.set_active(false)


func _process(delta):
	if is_instance_valid(player_body):
		# Move camera
		if player_body.position.x + CAM_X_OFFSET > camera_2d.position.x:
			camera_2d.position.x = player_body.position.x + CAM_X_OFFSET
		if did_player_act:
			camera_2d.position.x += KILLBOX_MOVE_SPEED * delta
		
		# Scroll background
		close_stars_sprite_2d.material.set_shader_parameter("player_x", camera_2d.position.x)
		far_stars_sprite_2d.material.set_shader_parameter("player_x", camera_2d.position.x)
		
		# Align black hole with cam height
		black_hole_arm.global_position.y = camera_2d.get_screen_center_position().y

func _physics_process(_delta):
	if not is_instance_valid(player_body):
		if Input.is_action_just_pressed("Reload"):
			get_tree().call_deferred("reload_current_scene")


func _on_killbox_area_2d_body_entered(_body):
	if not is_instance_valid(player_body): return
	
	player_body.die()
	GameManager.is_round_active = false


func _on_player_body_acted():
	if not did_player_act:
		did_player_act = true
		PhysicsServer2D.set_active(true)
		GameManager.is_round_active = true
