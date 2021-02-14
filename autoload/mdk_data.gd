# Copyright © 2021 Hugo Locurcio and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.
## Reads texture and sound data from the MDK data files.
extends Node

## The MDK sprite color palette (manually reverse engineered from screenshots).
## Colors with a `#` comment aren't determined yet.
const COLOR_PALETTE := [
	Color8(0, 0, 0, 0),
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(0, 255, 0),
	Color8(0, 150, 0),
	Color8(0, 97, 0),
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(0, 89, 90),
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(0, 0, 0),
	Color8(255, 0, 0), #
	Color8(255, 255, 206),
	Color8(255, 235, 165),
	Color8(231, 207, 148),
	Color8(181, 186, 148),
	Color8(173, 166, 156),
	Color8(165, 158, 140),
	Color8(156, 150, 132),
	Color8(140, 142, 132),
	Color8(140, 150, 148),
	Color8(132, 134, 115),
	Color8(123, 121, 107),
	Color8(107, 113, 107),
	Color8(90, 89, 90),
	Color8(90, 81, 74),
	Color8(82, 73, 57),
	Color8(66, 65, 66),
	Color8(49, 48, 49),
	Color8(41, 40, 33),
	Color8(24, 24, 24),
	Color8(16, 8, 8),
	Color8(66, 48, 24),
	Color8(90, 40, 16),
	Color8(123, 56, 24),
	Color8(123, 73, 33),
	Color8(140, 89, 49),
	Color8(123, 105, 74),
	Color8(132, 113, 90),
	Color8(173, 121, 82),
	Color8(181, 142, 99),
	Color8(206, 166, 123),
	Color8(8, 0, 0),
	Color8(33, 0, 0),
	Color8(66, 8, 0),
	Color8(90, 24, 0),
	Color8(115, 36, 0),
	Color8(140, 52, 0),
	Color8(165, 69, 0),
	Color8(189, 93, 0),
	Color8(198, 121, 16),
	Color8(214, 154, 24),
	Color8(231, 190, 41),
	Color8(239, 223, 57),
	Color8(255, 255, 74),
	Color8(255, 255, 132),
	Color8(255, 255, 198),
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	Color8(255, 0, 0), #
	# ...this is all we need for `SC_STAT` so far.
]

## Holds texture data. Key is the resource name, value is a PoolByteArray.
var byte_arrays := {}

## Key is the texture name, value is an ImageTexture.
var image_textures := {}

## Key is the sample name, value is an AudioStreamSample.
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


## Loads a WAV stream.
func parse_wav(bytes: PoolByteArray) -> AudioStreamSample:
	# Function adapted from <https://github.com/Gianclgar/GDScriptAudioImport/blob/master/GDScriptAudioImport.gd>.
	# Thanks GiancIgar!
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
			var _format_subchunk_size = bytes[i + 4] + (bytes[i + 5] << 8) + (bytes[i + 6] << 16) + (bytes[i + 7] << 24)
			#print("Format subchunk size: %d" % _format_subchunk_size)

			# Using format_subchunk index so it's easier to understand what's going on.
			# `fsc0` is byte 8 after start of "fmt ".
			var fsc0: int = i + 8

			# Get format code [Bytes 0-1].
			var format_code := bytes[fsc0] + (bytes[fsc0 + 1] << 8)
			var _format_name := ""
			if format_code == 0:
				_format_name = "8_BITS"
			elif format_code == 1:
				_format_name = "16_BITS"
			elif format_code == 2:
				_format_name = "IMA_ADPCM"
			#print("Format: %d (%s)" % [format_code, _format_name])
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
			var _byte_rate := bytes[fsc0 + 8] + (bytes[fsc0 + 9] << 8) + (bytes[fsc0 + 10] << 16) + (bytes[fsc0 + 11] << 24)
			#print("Byte rate: %d" % _byte_rate)

			# Same with bits*sample*channel [Bytes 12-13].
			var _bits_sample_channel := bytes[fsc0 + 12] + (bytes[fsc0 + 13] << 8)
			#print("BitsPerSample * Channel / 8: %d" % _bits_sample_channel)
			# Bits per sample [Bytes 14-15].
			var _bits_per_sample := bytes[fsc0 + 14] + (bytes[fsc0 + 15] << 8)
			#print("Bits per sample: %d" % _bits_per_sample)

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


## Converts a MDK byte array to an ImageTexture.
func parse_texture(p_name: String, bytes: PoolByteArray) -> ImageTexture:
	var first_4_bytes := bytes.subarray(0, 3) as PoolByteArray

	# Interpret image width and height as 16-bit unsigned integers.
	# Can't use `<<` here for some reason.
	var width := first_4_bytes[1] * first_4_bytes[1] + first_4_bytes[0]
	var height := first_4_bytes[3] * first_4_bytes[3] + first_4_bytes[2]
	if p_name == "SKULL":
		# Workaround since the automatically detected size isn't correct.
		width = 256
		height = 256

	var image_data := bytes.subarray(4, -1) as PoolByteArray
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

	return texture


## Loads a MDK `.BNI` file.
func read_textures(path: String) -> void:
	var file := File.new()
	var err := file.open(path, File.READ)
	if err != OK:
		OS.alert("Couldn't open file at path \"%s\" (error code %d)." % [path, err])
		get_tree().quit(1)


	var archive_size := file.get_32() + 4
	#print("Archive size: %d" % archive_size)
	var num_files := file.get_32()
	#print("%d files in TRAVSPRT.BNI." % num_files)

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
		var bytes := file.get_buffer(resource.length)
		byte_arrays[resource.name] = bytes
		image_textures[resource.name] = parse_texture(resource.name, bytes)

	file.close()


## Loads a MDK `.SNI` file.
func read_sounds(path: String) -> void:
	var file := File.new()
	var err := file.open(path, File.READ)
	if err != OK:
		OS.alert("Couldn't open file at path \"%s\" (error code %d)." % [path, err])
		get_tree().quit(1)

	var _archive_size := file.get_32() + 4
	#print("Archive size: %d" % _archive_size)
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
	read_textures("res://mdk/TRAVERSE/TRAVSPRT.BNI")

	read_sounds("res://mdk/MISC/MDKSOUND.SNI")
	read_sounds("res://mdk/TRAVERSE/TRAVERSE.SNI")

	# Stage-specific sounds.
	#read_sounds("res://mdk/FALL3D/FALL3D.SNI")

	# Level-specific sounds.
	# These should be loaded only when playing the level in question
	# as file names may conflict (especially for music).
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

## Saves a PoolByteArray to disk for debugging purposes.
func save_bytes_to_disk(byte_name: String) -> void:
	assert(byte_name in byte_arrays, '"%s" is not in the list of MDK byte arrays.' % byte_name)

	var file := File.new()
	# warning-ignore:return_value_discarded
	file.open("user://%s.bin" % byte_name, File.WRITE)
	file.store_buffer(MDKData.byte_arrays[byte_name])
	file.close()
	print('MDKData: Saved byte array %s to "user://%s.bin".' % [byte_name, byte_name])


## Saves an audio sample to a WAV file for debugging purposes.
func save_sample_to_disk(sample_name: String) -> void:
	assert(sample_name in audio_samples, '"%s" is not in the list of MDK audio samples.' % sample_name)

	audio_samples[sample_name].save_to_wav("user://%s.wav" % sample_name)
	print('MDKData: Saved audio sample %s to "user://%s.wav".' % [sample_name, sample_name])
