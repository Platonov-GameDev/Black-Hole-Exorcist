extends Node


var current_health := 100

signal destroyed


func take_damage(amount):
	current_health -= amount
	if current_health <= 0:
		destroyed.emit()
