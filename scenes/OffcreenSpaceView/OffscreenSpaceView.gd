extends Control


@onready var screen_shader = $ScreenShader
@onready var sub_viewport = $SubViewport
@onready var main = $SubViewport/main
@onready var score_label = $UI/ScoreLabel


func _ready():
	screen_shader.material.set_shader_parameter("viewport_texture", sub_viewport.get_texture())
	
	GameManager.score_changed.connect(_on_game_manager_score_changed)
	
	GameManager.update_score(0.0)


func _on_game_manager_score_changed(new_score):
	score_label.text = "Insight: " + "%.2f" % [new_score]
