extends Node2D


var thruster_emitters_array = []


func _ready():
	thruster_emitters_array = get_children()


func change_velocity_min_max(min_velocity: float, max_velocity: float):
	for emitter in thruster_emitters_array:
		emitter.process_material.initial_velocity_min = min_velocity
		emitter.process_material.initial_velocity_max = max_velocity


func change_gravity(new_gravity: Vector2):
	for emitter in thruster_emitters_array:
		emitter.process_material.gravity.x = new_gravity.x
		emitter.process_material.gravity.y = new_gravity.y
