extends CharacterBody2D


@onready var visible_on_screen_notifier_2d = $VisibleOnScreenNotifier2D

var SPEED = 2500.0
var damage = 35


func _ready():
	visible_on_screen_notifier_2d.screen_exited.connect(
		_on_visible_on_screen_notifier_2d_screen_exited
	)


func _physics_process(delta):
	var collision = move_and_collide(Vector2.RIGHT.rotated(rotation) * SPEED * delta)
	if collision:
		var collider = collision.get_collider() as Node
		collider.health_component.take_damage(35)
		call_deferred("queue_free")


func _on_visible_on_screen_notifier_2d_screen_exited():
	call_deferred("queue_free")
