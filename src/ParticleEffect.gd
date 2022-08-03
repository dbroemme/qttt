extends AnimatedSprite


func _ready():
	print("In the ready of animated sprite")


func _on_ParticleEffect_animation_finished():
	print("Do stuff as soon as any animation finishes.")
	playing = false
	hide()
	queue_free()
