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
