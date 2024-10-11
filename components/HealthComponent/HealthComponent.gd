extends Node


@export var current_health := 100
@export var score_reward := 0

signal destroyed
signal damage_taken


func take_damage(amount):
	current_health -= amount
	damage_taken.emit()
	if current_health <= 0:
		destroyed.emit()
		AudioPlayer.obstacle_destroyed_audio.play()
		GameManager.update_score(GameManager.score + score_reward)
		get_parent().call_deferred("queue_free")
	else:
		AudioPlayer.obstacle_hit_audio.play()
