extends Node2D


@onready var ray_cast_2d = $RayCast2D
@onready var line_2d = $Line2D
@onready var lifetime_timer = $LifetimeTimer

var damage = 35
var line_width = 10


func _ready():
	lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)
	
	ray_cast_2d.force_raycast_update()
	var collider = ray_cast_2d.get_collider()
	
	while collider:
		collider.health_component.take_damage(damage)
		ray_cast_2d.add_exception(collider)
		ray_cast_2d.global_position = ray_cast_2d.get_collision_point()
		
		ray_cast_2d.force_raycast_update()
		collider = ray_cast_2d.get_collider()


func _process(_delta):
	line_2d.width = lifetime_timer.time_left / lifetime_timer.wait_time * line_width


func _on_lifetime_timer_timeout():
	call_deferred("queue_free")
