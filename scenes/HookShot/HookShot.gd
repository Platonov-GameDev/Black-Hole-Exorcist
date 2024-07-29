extends CharacterBody2D


@onready var chain_line_2d = $ChainLine2D
@onready var rotatable = $Rotatable

var SPEED = 3000
var MAX_DISTANCE = 500

var player_body: RigidBody2D
var direction: Vector2


signal expired
signal grappled(collider, collision_point)


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
			grappled.emit(collider, collision.get_position())
		expire()
	
	if player_to_hook_vector.length() > MAX_DISTANCE:
		expire()

func expire():
	expired.emit()
	call_deferred("queue_free")
