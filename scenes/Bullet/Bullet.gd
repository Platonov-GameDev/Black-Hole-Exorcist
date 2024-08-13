extends CharacterBody2D


@onready var visible_on_screen_notifier_2d = $VisibleOnScreenNotifier2D

var MOVE_SPEED = 6000.0
var damage = 35


func _ready():
	visible_on_screen_notifier_2d.screen_exited.connect(
		_on_visible_on_screen_notifier_2d_screen_exited
	)


func _physics_process(delta):
	var time_coefficient = GameManager.calculate_time_coefficient(position)
	var collision = move_and_collide(
		Vector2.RIGHT.rotated(rotation) * MOVE_SPEED * delta * time_coefficient
	)
	if collision:
		var collider = collision.get_collider() as Node
		collider.health_component.take_damage(35)
		expire()


func _on_visible_on_screen_notifier_2d_screen_exited():
	expire()


func expire():
	call_deferred("queue_free")
