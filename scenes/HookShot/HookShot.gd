extends CharacterBody2D


@export var hookgrapple_scene: PackedScene
@onready var chain_line_2d = $ChainLine2D
@onready var rotatable = $Rotatable

var SPEED = 3000
var MAX_DISTANCE = 500

var player_body: RigidBody2D
var direction: Vector2


signal expired
signal grappled(hookgrapple, grapple_direction)


func _ready():
	velocity = direction * SPEED + player_body.linear_velocity


func _physics_process(delta):
	chain_line_2d.set_point_position(1, player_body.position - position)
	
	var player_to_hook_vector = position - player_body.position
	rotatable.look_at(player_body.position + player_to_hook_vector + player_to_hook_vector)
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider.is_in_group("obstacle"):
			var hookgrapple = hookgrapple_scene.instantiate()
			hookgrapple.player_body = player_body
			hookgrapple.obstacle = collider
			hookgrapple.collision_point = collision.get_position()
			var grapple_direction = (collision.get_position() - player_body.position).normalized()
			
			grappled.emit(hookgrapple, grapple_direction)
		
		expire()
	
	if player_to_hook_vector.length() > MAX_DISTANCE:
		expire()

func expire():
	expired.emit()
	call_deferred("queue_free")
