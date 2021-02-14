# Copyright © 2021 Hugo Locurcio and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.
extends Control

signal new_game_pressed
signal load_game_pressed
signal options_pressed


func _on_NewGame_pressed() -> void:
	visible = false
	emit_signal("new_game_pressed")
	var level := preload("res://levels/3.tscn").instance()
	add_child(level)


func _on_LoadGame_pressed() -> void:
	visible = false
	emit_signal("load_game_pressed")


func _on_Options_pressed() -> void:
	visible = false
	emit_signal("options_pressed")


func _on_Quit_pressed() -> void:
	get_tree().quit()
