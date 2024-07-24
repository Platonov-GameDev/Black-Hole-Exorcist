extends StaticBody2D


var chunk_scene := load("res://scenes/GroundChunkCrooked/GroundChunkCrooked.tscn")
@export var noise: FastNoiseLite

@onready var chunk_spawn_trigger_area_2d = $ChunkSpawnTriggerArea2D
@onready var polygon_2d = $Polygon2D
@onready var collision_polygon_2d = $CollisionPolygon2D

var WIDTH := 6000
var HEIGHT := 400
var RESOLUTION := 100.0
var CAVITY_DEPTH = 150.0

var did_spawn_next_chunk := false


func _ready():
	chunk_spawn_trigger_area_2d.body_entered.connect(_on_chunk_spawn_trigger_area_2d_body_entered)
	
	var new_point_array := PackedVector2Array()
	var uv_array := PackedVector2Array()
	new_point_array.append(Vector2(WIDTH / 2.0, HEIGHT / 2.0))
	new_point_array.append(Vector2(-WIDTH / 2.0, HEIGHT / 2.0))
	uv_array.append(Vector2(1, 1))
	uv_array.append(Vector2(0, 1))
	for i in range(RESOLUTION + 1):
		var point_x = WIDTH / RESOLUTION * i - WIDTH / 2.0
		var point_height = int(noise.get_noise_1d(point_x + position.x) * CAVITY_DEPTH)
		var point_y = -HEIGHT / 2.0 + point_height
		new_point_array.append(Vector2(point_x, point_y))
		uv_array.append(Vector2(i / RESOLUTION, 0))
	polygon_2d.polygon = new_point_array
	polygon_2d.uv = uv_array
	
	collision_polygon_2d.polygon = new_point_array


func _on_chunk_spawn_trigger_area_2d_body_entered(_body):
	if did_spawn_next_chunk:
		return
	
	var new_chunk = chunk_scene.instantiate()
	new_chunk.position = position
	new_chunk.position.x += WIDTH
	call_deferred("add_sibling", new_chunk)
	did_spawn_next_chunk = true
