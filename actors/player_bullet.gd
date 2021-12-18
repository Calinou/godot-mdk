extends CPUParticles

# Should match the effect's particle lifetime in seconds.
const LIFETIME = 1.0

var timer := 0.0


func _ready() -> void:
	emitting = true


func _process(delta: float) -> void:
	timer += delta

	if timer > LIFETIME:
		# Remove the particle effect to save resources.
		queue_free()
