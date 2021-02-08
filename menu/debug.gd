extends Control


func _ready() -> void:
	var name := "SC_STAT"
	var first_4_bytes := MDKData.byte_arrays[name].subarray(0, 3) as PoolByteArray

	# Interpret image width and height as 16-bit unsigned integers.
	# Can't use `<<` here for some reason.
	var width := first_4_bytes[1] * first_4_bytes[1] + first_4_bytes[0]
	var height := first_4_bytes[3] * first_4_bytes[3] + first_4_bytes[2]
	if name == "SKULL":
		# Workaround since the automatically detected size isn't correct.
		width = 256
		height = 256

	var image_data := MDKData.byte_arrays[name].subarray(4, -1) as PoolByteArray
	var image := Image.new()
	# Create image in L8 then convert it to RGBA. This way, we can apply our own
	# palette conversion more easily.
	image.create_from_data(width, height, false, Image.FORMAT_L8, image_data)
	image.convert(Image.FORMAT_RGBA8)

	image.lock()

	for y in image.get_height():
		for x in image.get_width():
			for index in MDKData.COLOR_PALETTE.size():
				if image.get_pixel(x, y) == Color8(index, index, index):
					image.set_pixel(x, y, MDKData.COLOR_PALETTE[index])

	image.unlock()

	var texture := ImageTexture.new()
	texture.create_from_image(image)
	# Disable filter and mipmaps for a "pixel art" appearance.
	texture.flags = 0
	$TextureRect.texture = texture


func _on_OPTBUTT_pressed() -> void:
	Sound.play(Sound.Type.NON_POSITIONAL, self, MDKData.audio_samples["OPTBUTT"])


func _on_SNDTEST_pressed() -> void:
	Sound.play(Sound.Type.NON_POSITIONAL, self, MDKData.audio_samples["SNDTEST"])


func _on_OPTSONG_pressed() -> void:
	Sound.play(Sound.Type.NON_POSITIONAL, self, MDKData.audio_samples["OPTSONG"])
