extends Area2D


func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if not is_instance_valid(body): return
	var player = body as PlayerBody
	player.die()
