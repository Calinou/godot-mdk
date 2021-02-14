# Copyright © 2021 Hugo Locurcio and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.
## Like a Button, but plays a sound when the button is pressed.
extends Button
class_name MDKButton


## Called when the button is pressed.
func _pressed():
	Sound.play(Sound.Type.NON_POSITIONAL, self, MDKData.audio_samples["OPTBUTT"])
