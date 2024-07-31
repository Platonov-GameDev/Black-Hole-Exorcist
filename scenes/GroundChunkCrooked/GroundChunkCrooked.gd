extends StaticBody2D
class_name GroundChunkCrooked


var chunk_scene := load("res://scenes/GroundChunkCrooked/GroundChunkCrooked.tscn")
@export var noise: FastNoiseLite

@onready var chunk_spawn_trigger_area_2d = $ChunkSpawnTriggerArea2D
@onready var polygon_2d = $Polygon2D
@onready var floor_boundary_collision_shape_2d = $FloorBoundaryCollisionShape2D
@onready var ceiling_boundary_collision_shape_2d = $CeilingBoundaryCollisionShape2D
@onready var accretion_pull_area_2d = $AccretionPullArea2D

var WIDTH := 6000
var HEIGHT := 100.0
var RESOLUTION := 100.0
var CAVITY_DEPTH := 90.0
var ACCRETION_PULL_FORCE := 100000.0

var did_spawn_next_chunk := false
var is_ceiling := false
var pulled_bodies: Array[RigidBody2D] = []


func _ready():
	chunk_spawn_trigger_area_2d.body_entered.connect(_on_chunk_spawn_trigger_area_2d_body_entered)
	accretion_pull_area_2d.body_entered.connect(_on_accretion_pull_area_2d_body_entered)
	accretion_pull_area_2d.body_exited.connect(_on_accretion_pull_area_2d_body_exited)
	
	floor_boundary_collision_shape_2d.position.y += HEIGHT / 2.0
	ceiling_boundary_collision_shape_2d.position.y -= HEIGHT / 2.0
	
	if is_ceiling:
		ceiling_boundary_collision_shape_2d.disabled = false
		polygon_2d.material.set_shader_parameter("speed", -2)
	else:
		floor_boundary_collision_shape_2d.disabled = false
		polygon_2d.scale.y = -polygon_2d.scale.y


func _physics_process(delta):
	# Pull bodies
	for body in pulled_bodies:
		var direction = 1
		if is_ceiling:
			direction *= -1
		body.apply_central_force(Vector2.LEFT * delta * ACCRETION_PULL_FORCE * direction)


func _on_chunk_spawn_trigger_area_2d_body_entered(_body):
	if did_spawn_next_chunk:
		return
	
	var new_chunk = chunk_scene.instantiate() as GroundChunkCrooked
	new_chunk.position = position
	new_chunk.position.x += WIDTH
	new_chunk.is_ceiling = is_ceiling
	call_deferred("add_sibling", new_chunk)
	did_spawn_next_chunk = true


func _on_accretion_pull_area_2d_body_entered(body):
	pulled_bodies.append(body)


func _on_accretion_pull_area_2d_body_exited(body):
	pulled_bodies.erase(body)
