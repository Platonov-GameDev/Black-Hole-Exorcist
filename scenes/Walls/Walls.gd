extends Node2D


@export var ground_scene: PackedScene

var GROUND_OFFSET := 500


func _ready():
	var ground = ground_scene.instantiate() as GroundChunkCrooked
	ground.position.y += GROUND_OFFSET
	add_child(ground)
	
	var ceiling = ground_scene.instantiate() as GroundChunkCrooked
	ceiling.position.y -= GROUND_OFFSET
	ceiling.is_ceiling = true
	add_child(ceiling)
