extends Control


@onready var screen_shader = $ScreenShader
@onready var sub_viewport = $SubViewport
@onready var score_label = $UI/VBoxContainer/ScoreLabel
@onready var countdown_label = $UI/VBoxContainer/CountdownLabel
@onready var power_label = $UI/VBoxContainer/PowerLabel


func _ready():
	GameManager.score_changed.connect(_on_game_manager_score_changed)
	GameManager.power_changed.connect(_on_game_manager_power_changed)
	
	screen_shader.material.set_shader_parameter("viewport_texture", sub_viewport.get_texture())
	
	GameManager.update_score(0.0)
	GameManager.arena_side_size = sub_viewport.size.x


func _on_game_manager_score_changed(new_score):
	score_label.text = "Score: " + "%.0f" % [new_score]


func _on_game_manager_power_changed(new_power):
	power_label.text = str(new_power)


func _process(_delta):
	# Calculate mouse position
	var mouse_position = (
		screen_shader.get_local_mouse_position()
		/ screen_shader.size.x
		* GameManager.arena_side_size
	)
	mouse_position -= Vector2(GameManager.arena_side_size / 2.0, GameManager.arena_side_size / 2.0)
	mouse_position /= GameManager.arena_side_size
	
	if mouse_position.length() <= 0.1:
		mouse_position /= 4.0
	elif mouse_position.length() <= 0.5:
		var divider = 1.0 + 3.0 * pow((0.5 - mouse_position.length()) / 0.4, 0.5)
		mouse_position /= divider
	
	mouse_position *= GameManager.arena_side_size
	GameManager.mouse_position = mouse_position
	
	# Set space warp edge
	screen_shader.material.set_shader_parameter(
		"edge_distance", clampf(GameManager.player_distance_from_black_hole / 1080.0, 0.01, 1.0)
	)
	
	countdown_label.text = "%.2f" % [clampf(300.0 - GameManager.time_since_start, 0, 300)]
