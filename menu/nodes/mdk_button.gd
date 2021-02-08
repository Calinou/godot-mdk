## Like a Button, but plays a sound when the button is pressed.
extends Button
class_name MDKButton


func _pressed():
	Sound.play(Sound.Type.NON_POSITIONAL, self, MDKData.audio_samples["OPTBUTT"])
