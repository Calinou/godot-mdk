extends Node

enum Skill {
	EASY,
	MEDIUM,
	HARD,
	NIGHTMARE,
}

var SKILL_NAMES := [
	tr("Easy"),
	tr("Normal"),
	tr("Hard"),
	tr("Nightmare"),
]

## The current skill level.
var skill: int = Skill.MEDIUM


func _ready() -> void:
	skill = Settings.file.get_value("game", "skill", Skill.MEDIUM)
