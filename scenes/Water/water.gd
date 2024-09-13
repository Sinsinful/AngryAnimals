extends Area2D

@onready var splash = $splash


func _on_body_entered(body):
	splash.play()
