# Copyright © 2019-2021 Hugo Locurcio and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.
extends Node


## Plays a sound non-positionally. The AudioStreamPlayer node will be added to the `parent`
## specified as parameter. The AudioStreamPlayer node will be freed automatically
## when the sound is done playing.
func play(parent: Node, stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var audio_stream_player := AudioStreamPlayer.new()
	audio_stream_player.bus = "Effects"
	audio_stream_player.stream = stream
	audio_stream_player.volume_db = volume_db
	audio_stream_player.pitch_scale = pitch_scale
	parent.add_child(audio_stream_player)
	audio_stream_player.play()
	# warning-ignore:return_value_discarded
	audio_stream_player.connect("finished", audio_stream_player, "queue_free")


## Plays a sound with 2D position. The AudioStreamPlayer2D node will be added to the `parent`
## specified as parameter. The AudioStreamPlayer2D node will be freed automatically
## when the sound is done playing.
func play_2d(parent: Node, stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var audio_stream_player_2d := AudioStreamPlayer2D.new()
	audio_stream_player_2d.bus = "Effects"
	audio_stream_player_2d.stream = stream
	audio_stream_player_2d.volume_db = volume_db
	audio_stream_player_2d.pitch_scale = pitch_scale
	parent.add_child(audio_stream_player_2d)
	audio_stream_player_2d.play()
	# warning-ignore:return_value_discarded
	audio_stream_player_2d.connect("finished", audio_stream_player_2d, "queue_free")


## Plays a sound with 3D position. The AudioStreamPlayer3D node will be added to the `parent`
## specified as parameter. The AudioStreamPlayer3D node will be freed automatically
## when the sound is done playing.
## The default unit size is greatly increased to make sounds easier to hear.
func play_3d(parent: Node, stream: AudioStream, unit_db: float = 0.0, pitch_scale: float = 1.0, unit_size = 25.0) -> void:
	var audio_stream_player_3d := AudioStreamPlayer3D.new()
	audio_stream_player_3d.bus = "Effects"
	audio_stream_player_3d.stream = stream
	audio_stream_player_3d.unit_db = unit_db
	audio_stream_player_3d.pitch_scale = pitch_scale
	audio_stream_player_3d.unit_size = unit_size
	# Disable the distance low-pass filter as the original MDK doesn't have such an effect.
	audio_stream_player_3d.attenuation_filter_cutoff_hz = 20500
	parent.add_child(audio_stream_player_3d)
	audio_stream_player_3d.play()
	# warning-ignore:return_value_discarded
	audio_stream_player_3d.connect("finished", audio_stream_player_3d, "queue_free")
