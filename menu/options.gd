# Copyright © 2021 Hugo Locurcio and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.
extends Control

signal back_pressed

onready var skill_button := $VBoxContainer/Skill as Button


func _ready() -> void:
	update_skill_text()


## Updates the skill button text to match the skill level from the settings.
func update_skill_text() -> void:
	skill_button.text = "Skill - %s" % Game.SKILL_NAMES[Game.skill]


func _on_Sound_pressed() -> void:
	visible = false
	emit_signal("sound_pressed")


func _on_Controls_pressed() -> void:
	visible = false
	emit_signal("controls_pressed")


func _on_Skill_pressed() -> void:
	# Cycle through skill levels.
	Game.skill = (Game.skill + 1) % Game.Skill.size()
	update_skill_text()
	Settings.set_value("game", "skill", Game.skill)


func _on_Display_pressed() -> void:
	visible = false
	emit_signal("display_pressed")


func _on_Back_pressed() -> void:
	visible = false
	emit_signal("back_pressed")
