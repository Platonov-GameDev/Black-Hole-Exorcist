extends Node2D


@onready var grapple_rigid_body_2d = $GrappleRigidBody2D
@onready var pin_joint_2d = $PinJoint2D
@onready var rope_handle = $RopeHandle
@onready var rope = $Rope
@onready var rope_renderer_line_2d = $Rope/RopeRendererLine2D

var CHAIN_STIFFNESS = 1
var GRAPPLE_FORCE = 3

var player_body: RigidBody2D
var obstacle: RigidBody2D
var collision_point: Vector2
var max_length: float
var chain_pull_coefficient := .1


func _ready():
	grapple_rigid_body_2d.global_position = collision_point
	grapple_rigid_body_2d.look_at(collision_point + collision_point - player_body.global_position)
	
	pin_joint_2d.position = collision_point
	pin_joint_2d.node_a = pin_joint_2d.get_path_to(obstacle, true)
	pin_joint_2d.node_b = pin_joint_2d.get_path_to(grapple_rigid_body_2d)
	
	max_length = player_body.position.distance_to(grapple_rigid_body_2d.position)
	
	var chain_vector = grapple_rigid_body_2d.position - player_body.position
	var grapple_pull_force = chain_vector * GRAPPLE_FORCE
	player_body.apply_central_impulse(grapple_pull_force)
	grapple_rigid_body_2d.apply_central_impulse(-grapple_pull_force)
	
	# Initialize rope
	rope.global_position = grapple_rigid_body_2d.global_position
	rope_handle.global_position = player_body.global_position
	
	rope.rope_length = chain_vector.length() * 0.5
	rope.num_segments = int(rope.rope_length / 5.0);
	rope.update_segments()
	
	var num_points = rope.get_num_points()
	var point_offset = chain_vector / num_points
	for i in range(num_points):
		rope.set_point(i, rope.global_position - point_offset * i)

func _physics_process(_delta):
	# Chain visuals
	rope.global_position = grapple_rigid_body_2d.global_position
	rope_handle.global_position = player_body.global_position
	
	# Chain physics
	# Chain pull on max length reached
	var chain_vector = grapple_rigid_body_2d.position - player_body.position
	var chain_length = chain_vector.length()
	if chain_length > max_length:
		var chain_stretch_length = chain_length - max_length
		var player_to_grapple_vector = chain_vector.normalized()
		var chain_pull_force = player_to_grapple_vector * chain_stretch_length * CHAIN_STIFFNESS
		grapple_rigid_body_2d.apply_central_impulse(-chain_pull_force)
		player_body.apply_central_impulse(chain_pull_force)
