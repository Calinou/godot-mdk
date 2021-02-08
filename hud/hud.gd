extends Control


onready var vitals := $Vitals as TextureRect
onready var people_dead := $Vitals/PeopleDead as TextureProgress


func _ready() -> void:
	vitals.texture = MDKData.image_textures["SC_STAT"]
	people_dead.texture_progress = MDKData.image_textures["SC_BSTAT"]


func _process(delta: float) -> void:
	# Placeholder to see the progress bar being effective.
	$Vitals/PeopleDead.value += delta * 0.15
