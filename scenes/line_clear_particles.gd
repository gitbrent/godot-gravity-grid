extends CPUParticles2D

func _ready() -> void:
	emitting = true
	# Wait for the particles to finish falling, then delete the node
	await finished
	queue_free()
