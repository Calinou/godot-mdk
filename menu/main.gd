extends Control

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
	print("========")
	var new_stream := AudioStreamSample.new()

	for i in 100:
		var those4bytes := str(char(bytes[i]) + char(bytes[i + 1]) + char(bytes[i + 2]) + char(bytes[i + 3]))

		if those4bytes == "RIFF":
			print("RIFF OK at bytes " + str(i) + "-" + str(i + 3))
			# RIP bytes 4-7 integer for now.
		if those4bytes == "WAVE":
			print("WAVE OK at bytes " + str(i) + "-" + str(i + 3))
		if those4bytes == "fmt ":
			print("fmt OK at bytes " + str(i) + "-" + str(i + 3))

			# Get format subchunk size, 4 bytes next to "fmt " are an int32.
			var formatsubchunksize = bytes[i + 4] + (bytes[i + 5] << 8) + (bytes[i + 6] << 16) + (bytes[i + 7] << 24)
			print("Format subchunk size: " + str(formatsubchunksize))

			# Using formatsubchunk index so it's easier to understand what's going on.
			# `fsc0` is byte 8 after start of "fmt ".
			var fsc0: int = i + 8

			# Get format code [Bytes 0-1].
			var format_code := bytes[fsc0] + (bytes[fsc0+1] << 8)
			var format_name := ""
			if format_code == 0:
				format_name = "8_BITS"
			elif format_code == 1:
				format_name = "16_BITS"
			elif format_code == 2:
				format_name = "IMA_ADPCM"
			print("Format: %d (%s)" % [format_code, format_name])
			new_stream.format = format_code

			# Get channel num [Bytes 2-3].
			var channel_num := bytes[fsc0+2] + (bytes[fsc0+3] << 8)
			print("Number of channels: %d" % channel_num)
			# Set our AudioStreamSample to stereo if needed.
			if channel_num == 2:
				new_stream.stereo = true

			# Get sample rate [Bytes 4-7].
			var sample_rate := bytes[fsc0+4] + (bytes[fsc0+5] << 8) + (bytes[fsc0+6] << 16) + (bytes[fsc0+7] << 24)
			print("Sample rate: %d" % sample_rate)
			# Set our AudioStreamSample mixrate.
			new_stream.mix_rate = sample_rate

			# Get byte_rate [Bytes 8-11] because we can.
			var byte_rate := bytes[fsc0+8] + (bytes[fsc0+9] << 8) + (bytes[fsc0+10] << 16) + (bytes[fsc0+11] << 24)
			print("Byte rate: %d" % byte_rate)

			# Same with bits*sample*channel [Bytes 12-13].
			var bits_sample_channel := bytes[fsc0+12] + (bytes[fsc0+13] << 8)
			print("BitsPerSample * Channel / 8: %d" % bits_sample_channel)
			# Bits per sample [Bytes 14-15].
			var bits_per_sample := bytes[fsc0+14] + (bytes[fsc0+15] << 8)
			print("Bits per sample: %d" % bits_per_sample)

		if those4bytes == "data":
			var audio_data_size := bytes[i+4] + (bytes[i+5] << 8) + (bytes[i+6] << 16) + (bytes[i+7] << 24)
			print("Audio data/stream size is %d bytes." % audio_data_size)

			var data_entry_point: int = i + 8
			print("Audio data starts at byte %d." % data_entry_point)

			new_stream.data = bytes.subarray(data_entry_point, data_entry_point+audio_data_size-1)

	# Get samples and set loop end.
	var sample_num := new_stream.data.size() / 4
	new_stream.loop_end = sample_num
	new_stream.loop_mode = 0 # Change to 0 or delete this line if you don't want loop, also check out modes 2 and 3 in the docs.

	return new_stream

# Key is the sample name, value is an AudioStream.
var audio_samples := {}

func _ready() -> void:
	var file := File.new()
	var path := "res://mdk/MISC/MDKSOUND.SNI"
	var err := file.open(path, File.READ)
	if err != OK:
		push_error("Couldn't open file at path \"%s\" (error code %d)." % [path, err])

	var archive_size := file.get_32() + 4
	print("Archive size: %d" % archive_size)
	# Skip archive name and second archive size as we don't need them.
	file.seek(file.get_position() + 12 + 4)

	var num_files := file.get_32()
	print("%d files in archive." % num_files)

	var file_names := []
	var file_offsets := []
	var file_lengths := []
	for _idx in num_files:
		var file_name := file.get_buffer(12).get_string_from_ascii()
		# Skip unknown fields.
		file.seek(file.get_position() + 2 + 2)
		var file_offset := file.get_32() + 4
		var file_length := file.get_32()
		file_names.push_back(file_name)
		file_offsets.push_back(file_offset)
		file_lengths.push_back(file_length)
		print({file_name = file_name, file_offset = file_offset, file_length = file_length})

	for idx in file_offsets.size():
		file.seek(file_offsets[idx])
		var wav_bytes := file.get_buffer(file_lengths[idx])
		audio_samples[file_names[idx]] = parse_wav(wav_bytes)


	file.close()


func _on_OPTBUTT_pressed() -> void:
	Sound.play(Sound.Type.NON_POSITIONAL, self, audio_samples["OPTBUTT"])


func _on_SNDTEST_pressed() -> void:
	Sound.play(Sound.Type.NON_POSITIONAL, self, audio_samples["SNDTEST"])


func _on_OPTSONG_pressed() -> void:
	Sound.play(Sound.Type.NON_POSITIONAL, self, audio_samples["OPTSONG"])
