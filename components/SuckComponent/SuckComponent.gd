extends Node


var SUCK_FORCE = 40000
var parent_body: RigidBody2D


func _ready():
	parent_body = get_parent()


func _physics_process(delta):
	if GameManager.is_round_active:
		parent_body.apply_central_force(Vector2.LEFT * SUCK_FORCE * delta)
