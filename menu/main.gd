extends Control

var byte_arrays := {}

# Key is the sample name, value is a BinResource.
var audio_samples := {}

## Represents a binary resource in one of the MDK archive files.
class BinResource:
	## The resource's name (case-sensitive).
	var name := ""

	## The resource's offset (relative to the start of the file).
	var offset := 0

	## The resource's size in bytes. If `-1`, the length isn't calculated yet.
	## Only the `.MTI` and `.SNI` formats encode the length in the files.
	## With `.BNI` and `.MTO`, the lengths have to be calculated manually.
	var length := -1


	func _init(p_name: String, p_offset: int, p_length: int = -1) -> void:
		name = p_name
		offset = p_offset
		length = p_length


	func _to_string() -> String:
		return "%s (offset %d, length %d)" % [name, offset, length]


# BNI format specification:
# <http://www.watto.org/specs.html?specs=Archive_BNI>
#// ARCHIVE HEADER
#  4 - Archive Length [+4]
#  4 - Number of Files
#
#// DETAILS DIRECTORY
#  // for each file
#    12 - Filename (null terminated, filled with nulls, no file extension)
#    4 - File Offset [+4]
#
#// FILE DATA
#  // for each file
#    X - File Data

# MTI format specification:
# <http://www.watto.org/specs.html?specs=Archive_MTI>
#	// ARCHIVE HEADER
#  4 - Archive Length [+4]
#  12 - Archive Filename (replacing ".mti" with ".mat") (nulls to fill)
#  4 - Archive Length [+12]
#  4 - Number Of Files
#
#// DETAILS DIRECTORY
#  // for each file
#    12 - Filename (null terminated, filled with nulls, no file extension)
#    2 - null
#    4 - null
#    2 - Unknown
#    4 - File Offset [+4]
#
#// FILE DATA
#  // for each file
#    X - File Data
#    0-3 - null Padding to a multiple of 4 bytes

# MTO format specification:
# <http://www.watto.org/specs.html?specs=Archive_MTO>
#// ARCHIVE HEADER
#  4 - Archive Length [+4]
#  12 - Archive Filename (replacing ".mto" with ".mat") (nulls to fill)
#  4 - Archive Length [+12]
#  4 - Number Of Files
#
#// DETAILS DIRECTORY
#  // for each file
#    8 - Filename (null terminated, filled with nulls, no file extension)
#    4 - File Offset
#
#// FILE DATA
#  // for each file
#    X - File Data
#    0-3 - null Padding to a multiple of 4 bytes

# SNI format specification:
# <http://www.watto.org/specs.html?specs=Archive_SNI>
#// ARCHIVE HEADER
#  4 - Archive Length [+4]
#  12 - Archive Filename (replacing ".sni" with ".snd") (nulls to fill)
#  4 - Archive Length [+12]
#  4 - Number Of Files
#
#// DETAILS DIRECTORY
#  // for each file
#    12 - Filename (null terminated, filled with nulls, no file extension)
#    2 - Unknown (0/1/3)
#    2 - Unknown
#    4 - File Offset [+4]
#    4 - File Length
#
#// FILE DATA
#  // for each file
#    X - File Data
#    0-3 - null Padding to a multiple of 4 bytes


# Function adapted from <https://github.com/Gianclgar/GDScriptAudioImport/blob/master/GDScriptAudioImport.gd>.
# Thanks GiancIgar!
func parse_wav(bytes: PoolByteArray) -> AudioStreamSample:
	#print("========")
	var new_stream := AudioStreamSample.new()

	for i in 100:
		var those4bytes := str(char(bytes[i]) + char(bytes[i + 1]) + char(bytes[i + 2]) + char(bytes[i + 3]))

		if those4bytes == "RIFF":
			pass
			#print("RIFF OK at bytes %d-%d" % [i, i + 3])
			# RIP bytes 4-7 integer for now.
		if those4bytes == "WAVE":
			pass
			#print("WAVE OK at bytes %d-%d" % [i, i + 3])
		if those4bytes == "fmt ":
			pass
			#print("fmt OK at bytes %d-%d" % [i, i + 3])

			# Get format subchunk size, 4 bytes next to "fmt " are an int32.
			var format_subchunk_size = bytes[i + 4] + (bytes[i + 5] << 8) + (bytes[i + 6] << 16) + (bytes[i + 7] << 24)
			#print("Format subchunk size: %d" % format_subchunk_size)

			# Using format_subchunk index so it's easier to understand what's going on.
			# `fsc0` is byte 8 after start of "fmt ".
			var fsc0: int = i + 8

			# Get format code [Bytes 0-1].
			var format_code := bytes[fsc0] + (bytes[fsc0 + 1] << 8)
			var format_name := ""
			if format_code == 0:
				format_name = "8_BITS"
			elif format_code == 1:
				format_name = "16_BITS"
			elif format_code == 2:
				format_name = "IMA_ADPCM"
			#print("Format: %d (%s)" % [format_code, format_name])
			new_stream.format = format_code

			# Get channel num [Bytes 2-3].
			var channel_num := bytes[fsc0 + 2] + (bytes[fsc0 + 3] << 8)
			#print("Number of channels: %d" % channel_num)
			# Set our AudioStreamSample to stereo if needed.
			new_stream.stereo = channel_num == 2

			# Get sample rate [Bytes 4-7].
			var sample_rate := bytes[fsc0 + 4] + (bytes[fsc0 + 5] << 8) + (bytes[fsc0 + 6] << 16) + (bytes[fsc0 + 7] << 24)
			#print("Sample rate: %d" % sample_rate)
			# Set our AudioStreamSample mixrate.
			new_stream.mix_rate = sample_rate

			# Get byte_rate [Bytes 8-11] because we can.
			var byte_rate := bytes[fsc0 + 8] + (bytes[fsc0 + 9] << 8) + (bytes[fsc0 + 10] << 16) + (bytes[fsc0 + 11] << 24)
			#print("Byte rate: %d" % byte_rate)

			# Same with bits*sample*channel [Bytes 12-13].
			var bits_sample_channel := bytes[fsc0 + 12] + (bytes[fsc0 + 13] << 8)
			#print("BitsPerSample * Channel / 8: %d" % bits_sample_channel)
			# Bits per sample [Bytes 14-15].
			var bits_per_sample := bytes[fsc0 + 14] + (bytes[fsc0 + 15] << 8)
			#print("Bits per sample: %d" % bits_per_sample)

		if those4bytes == "data":
			var audio_data_size := bytes[i + 4] + (bytes[i + 5] << 8) + (bytes[i + 6] << 16) + (bytes[i + 7] << 24)
			#print("Audio data/stream size is %d bytes." % audio_data_size)

			var data_entry_point: int = i + 8
			#print("Audio data starts at byte %d." % data_entry_point)

			new_stream.data = bytes.subarray(data_entry_point, data_entry_point + audio_data_size - 1)

	# Get samples and set loop end.
	# warning-ignore:integer_division
	var sample_num := new_stream.data.size() / 4
	new_stream.loop_end = sample_num
	# Change to 0 or delete this line if you don't want loop. Also check out modes 2 and 3 in the docs.
	new_stream.loop_mode = 0

	return new_stream


func read_textures() -> void:
	var file := File.new()
	var path := "res://mdk/TRAVERSE/TRAVSPRT.BNI"
	var err := file.open(path, File.READ)
	if err != OK:
		OS.alert("Couldn't open file at path \"%s\" (error code %d)." % [path, err])
		get_tree().quit(1)


	var archive_size := file.get_32() + 4
	print("Archive size: %d" % archive_size)
	var num_files := file.get_32()
	print("%d files in TRAVSPRT.BNI." % num_files)

	var resources := []
	for _idx in num_files:
		# All file names are ASCII-only.
		var file_name := file.get_buffer(12).get_string_from_ascii()
		var file_offset := file.get_32() + 4
		resources.push_back(BinResource.new(file_name, file_offset))

	for idx in resources.size() - 1:
		# Calculate length for resources since they're not specified in the file.
		resources[idx].length = resources[idx + 1].offset - resources[idx].offset

	# Calculate the size of the last file (`SKULL`).
	resources[-1].length = archive_size - resources[-1].offset

	for resource in resources:
		file.seek(resource.offset)
		byte_arrays[resource.name] = file.get_buffer(resource.length)

	# Try to reverse engineer the image format
	for i in 100:
		var num := 0
		num += byte_arrays["K_IDLE"][i * 2] << 8
		num += byte_arrays["K_IDLE"][i * 2 + 1]
		#num += byte_arrays["K_IDLE"][i * 4 + 2] << 8
		#num += byte_arrays["K_IDLE"][i * 4 + 3]
		print(num)

	file.close()


func read_sounds(path: String) -> void:
	var file := File.new()
	var err := file.open(path, File.READ)
	if err != OK:
		OS.alert("Couldn't open file at path \"%s\" (error code %d)." % [path, err])
		get_tree().quit(1)

	var archive_size := file.get_32() + 4
	#print("Archive size: %d" % archive_size)
	# Skip archive name and second archive size as we don't need them.
	file.seek(file.get_position() + 12 + 4)

	var num_files := file.get_32()
	#print("%d files in MDKSOUND.SNI." % num_files)

	var resources := []
	for _idx in num_files:
		# All file names are ASCII-only.
		var file_name := file.get_buffer(12).get_string_from_ascii()
		# Skip unknown fields.
		file.seek(file.get_position() + 2 + 2)
		var file_offset := file.get_32() + 4
		var file_length := file.get_32()
		resources.push_back(BinResource.new(file_name, file_offset, file_length))

	for resource in resources:
		file.seek(resource.offset)
		var wav_bytes := file.get_buffer(resource.length)
		audio_samples[resource.name] = parse_wav(wav_bytes)

	file.close()


func _ready() -> void:
	read_textures()
	read_sounds("res://mdk/MISC/MDKSOUND.SNI")
	read_sounds("res://mdk/FALL3D/FALL3D.SNI")
	read_sounds("res://mdk/TRAVERSE/TRAVERSE.SNI")

	# Level-specific sounds.
	# Thesesshould be loaded only when playing the level in question,
	# as file names may conflict for music.
	#read_sounds("res://mdk/TRAVERSE/LEVEL3/LEVEL3O.SNI")
	#read_sounds("res://mdk/TRAVERSE/LEVEL3/LEVEL3S.SNI")
	#read_sounds("res://mdk/TRAVERSE/LEVEL4/LEVEL4O.SNI")
	# FIXME: `LEVEL4S.SNI` fails to load.
	#read_sounds("res://mdk/TRAVERSE/LEVEL4/LEVEL4S.SNI")
	#read_sounds("res://mdk/TRAVERSE/LEVEL5/LEVEL5O.SNI")
	#read_sounds("res://mdk/TRAVERSE/LEVEL5/LEVEL5S.SNI")
	# FIXME: `LEVEL6S.SNI` fails to load.
	#read_sounds("res://mdk/TRAVERSE/LEVEL6/LEVEL6S.SNI")
	#read_sounds("res://mdk/TRAVERSE/LEVEL6/LEVEL6O.SNI")
	#read_sounds("res://mdk/TRAVERSE/LEVEL7/LEVEL7O.SNI")
	#read_sounds("res://mdk/TRAVERSE/LEVEL7/LEVEL7S.SNI")
	#read_sounds("res://mdk/TRAVERSE/LEVEL8/LEVEL8O.SNI")
	#read_sounds("res://mdk/TRAVERSE/LEVEL8/LEVEL8S.SNI")


func _on_OPTBUTT_pressed() -> void:
	Sound.play(Sound.Type.NON_POSITIONAL, self, audio_samples["OPTBUTT"])


func _on_SNDTEST_pressed() -> void:
	Sound.play(Sound.Type.NON_POSITIONAL, self, audio_samples["SNDTEST"])


func _on_OPTSONG_pressed() -> void:
	Sound.play(Sound.Type.NON_POSITIONAL, self, audio_samples["OPTSONG"])


#func update_image() -> void:
#	var img := byte_arrays["K_IDLE"].subarray(slice_start, slice_end) as PoolByteArray
#	var image := Image.new()
#	image.create_from_data((slice_end - slice_start) / 128, (slice_end - slice_start) % 128, false, Image.FORMAT_L8, img)
#
#	var texture := ImageTexture.new()
#	texture.create_from_image(image)
#	$TextureRect.texture = texture
