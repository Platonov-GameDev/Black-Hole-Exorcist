extends CharacterBody2D


@export var hookgrapple_scene: PackedScene
@onready var chain_line_2d = $ChainLine2D
@onready var sprite_2d = $Sprite2D
var SPEED = 3000
var GRAPPLE_FORCE = 3
var MAX_DISTANCE = 500
var player_body: RigidBody2D
var direction: Vector2


signal expired
signal grappled(hookgrapple)


func _ready():
	velocity = direction * SPEED + player_body.linear_velocity


func _process(delta):
	chain_line_2d.set_point_position(1, player_body.position - position)
	
	var player_to_hook_vector = position - player_body.position
	sprite_2d.look_at(player_body.position + player_to_hook_vector + player_to_hook_vector)
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider.is_in_group("obstacle"):
			var hookgrapple = hookgrapple_scene.instantiate()
			hookgrapple.player_body = player_body
			hookgrapple.obstacle = collider
			hookgrapple.collision_point = collision.get_position()
			
			var player_pull_force = player_to_hook_vector * GRAPPLE_FORCE
			player_body.apply_central_impulse(player_pull_force)
			
			grappled.emit(hookgrapple)
		
		expire()
	
	if player_to_hook_vector.length() > MAX_DISTANCE:
		expire()

func expire():
	expired.emit()
	call_deferred("queue_free")
