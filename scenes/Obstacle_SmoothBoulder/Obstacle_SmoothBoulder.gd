extends RigidBody2D


var TORQUE := 3000000.0

var did_init := false


func _physics_process(_delta):
	if not did_init:
		apply_torque(TORQUE * sign(randf_range(-1, 1)))
		did_init = true
