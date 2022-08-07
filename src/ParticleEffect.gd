extends AnimatedSprite


func _ready():
	pass


func _on_ParticleEffect_animation_finished():
	playing = false
	hide()
	queue_free()
