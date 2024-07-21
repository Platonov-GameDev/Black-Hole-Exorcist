extends Control


@onready var screen_shader = $ScreenShader
@onready var sub_viewport = $SubViewport
@onready var main = $SubViewport/main
@onready var score_label = $UI/ScoreLabel


func _ready():
	screen_shader.material.set_shader_parameter("viewport_texture", sub_viewport.get_texture())
	
	main.score_changed.connect(_on_main_score_changed)


func _on_main_score_changed(new_score):
	score_label.text = "Insight: " + str(new_score)
