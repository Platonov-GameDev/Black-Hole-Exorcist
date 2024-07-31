extends Node2D


@export var obstacles_count := 1
var obstacle_chunk_scene = load("res://scenes/ObstacleChunk/ObstacleChunk.tscn")
@export var obstacle_boulder_scene: PackedScene

@onready var visible_on_screen_notifier_2d = $VisibleOnScreenNotifier2D

var WIDTH := 400
var HEIGHT := 400


func _ready():
	visible_on_screen_notifier_2d.screen_entered.connect(_on_visible_on_screen_notifier_2d_screen_entered)
	
	for i in range(obstacles_count):
		var obstacle_boulder = obstacle_boulder_scene.instantiate()
		seed(Time.get_unix_time_from_system() + i + position.x)
		obstacle_boulder.position.y += randf_range(-HEIGHT / 2.0, HEIGHT / 2.0)
		seed(Time.get_unix_time_from_system() + i + position.x + 1)
		obstacle_boulder.position.x += randf_range(-WIDTH / 2.0, WIDTH / 2.0)
		call_deferred("add_child", obstacle_boulder)


func _on_visible_on_screen_notifier_2d_screen_entered():
	var next_chunk = obstacle_chunk_scene.instantiate()
	next_chunk.position = position
	next_chunk.position.x += WIDTH
	call_deferred("add_sibling", next_chunk)
