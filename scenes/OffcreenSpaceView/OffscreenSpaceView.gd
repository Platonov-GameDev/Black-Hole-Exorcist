extends Control


@onready var screen_shader = $ScreenShader
@onready var sub_viewport = $SubViewport
@onready var main = $SubViewport/main
@onready var max_reached_label = $UI/MaxReachedLabel


func _ready():
	screen_shader.material.set_shader_parameter("viewport_texture", sub_viewport.get_texture())
	
	main.max_distance_changed.connect(_on_main_max_distance_changed)


func _on_main_max_distance_changed(new_max_distance):
	max_reached_label.text = "Current: " + str(new_max_distance)
