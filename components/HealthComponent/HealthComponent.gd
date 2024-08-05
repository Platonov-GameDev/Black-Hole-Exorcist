extends Node


var current_health := 100

signal destroyed
signal damage_taken


func take_damage(amount):
	current_health -= amount
	damage_taken.emit()
	if current_health <= 0:
		destroyed.emit()
