extends GPUParticles2D


@export var direction: Vector3 = Vector3(1, 0, 0)

var particle_process_material: ParticleProcessMaterial


func _ready():
	particle_process_material = process_material
	
	particle_process_material.direction = direction
