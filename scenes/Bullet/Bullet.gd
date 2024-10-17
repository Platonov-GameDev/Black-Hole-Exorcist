extends CharacterBody2D


@onready var visible_on_screen_notifier_2d = $VisibleOnScreenNotifier2D
@onready var collision_polygon_2d = $CollisionPolygon2D

var MOVE_SPEED = 600.0
var DAMAGE = 35
var IMPALE_DEPTH = 10

var did_hit := false


func _ready():
	visible_on_screen_notifier_2d.screen_exited.connect(
		_on_visible_on_screen_notifier_2d_screen_exited
	)


func _physics_process(delta):
	if did_hit: return
	var time_coefficient = GameManager.calculate_time_coefficient(position)
	var collision = move_and_collide(
		Vector2.RIGHT.rotated(rotation) * MOVE_SPEED * delta * time_coefficient
	)
	if collision:
		var collider = collision.get_collider() as Node
		collider.health_component.take_damage(DAMAGE)
		collision_polygon_2d.disabled = true
		position = collision.get_position() + Vector2.RIGHT.rotated(rotation) * IMPALE_DEPTH
		reparent(collider)
		did_hit = true


func _on_visible_on_screen_notifier_2d_screen_exited():
	call_deferred("queue_free")
