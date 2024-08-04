extends RigidBody2D


@onready var health_component = $HealthComponent

var TORQUE := 3000000.0
var SPEED := 1000.0

var did_init := false


func _ready():
	health_component.destroyed.connect(_on_health_component_destroyed)


func _physics_process(_delta):
	if not did_init:
		apply_torque_impulse(TORQUE * sign(randf_range(-1, 1)))
		apply_central_impulse(SPEED * Vector2(randf_range(-1, 1), randf_range(-1, 1)))
		
		did_init = true


func expire():
	GameManager.pulled_bodies.erase(self)
	call_deferred("queue_free")


func _on_health_component_destroyed():
	expire()
