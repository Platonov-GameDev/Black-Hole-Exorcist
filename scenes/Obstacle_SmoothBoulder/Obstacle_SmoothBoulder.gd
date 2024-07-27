extends RigidBody2D


var TORQUE_RANGE := 300000

var did_initialize := false


func _physics_process(_delta):
	if not did_initialize:
		apply_torque_impulse(randf_range(-TORQUE_RANGE, TORQUE_RANGE))
		did_initialize = true
