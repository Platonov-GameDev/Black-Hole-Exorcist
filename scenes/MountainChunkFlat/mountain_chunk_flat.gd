extends StaticBody2D


var chunk_scene := load("res://scenes/MountainChunkFlat/MountainChunkFlat.tscn")
@onready var chunk_spawn_trigger_area_2d = $ChunkSpawnTriggerArea2D
var did_spawn_next_chunk := false


func _ready():
	chunk_spawn_trigger_area_2d.body_entered.connect(_on_chunk_spawn_trigger_area_2d_body_entered)


func _on_chunk_spawn_trigger_area_2d_body_entered(_body):
	if did_spawn_next_chunk:
		return
	
	var new_chunk = chunk_scene.instantiate()
	new_chunk.position = position
	new_chunk.position.x += 2000
	call_deferred("add_sibling", new_chunk)
	did_spawn_next_chunk = true
