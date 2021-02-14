extends Control

## If `true`, the player is in the main menu.
## If `false`, the player is in the in-game menu (pause menu).
var in_main_menu := true

onready var main := $Main as Control


func _ready() -> void:
	for node in get_tree().get_nodes_in_group("autofocus"):
		node.connect("visibility_changed", self, "_on_autofocus_visibility_changed", [node])


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_pause_menu"):
		if visible:
			hide_menu()
		else:
			show_menu()


## Hides the main/pause menu and restore the initial state.
func hide_menu() -> void:
	visible = false

	# Restore initial menu state so we can't display several menus at once.
	for menu in get_tree().get_nodes_in_group("menu"):
		menu.visible = false

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


## Shows the main/pause menu.
func show_menu() -> void:
	if not visible:
		visible = true
		main.visible = true

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


## Called when a node with the `autofocus` group has its visiblity change.
## This is used to automatically focus nodes for keyboard/controller navigation
## when they appear.
func _on_autofocus_visibility_changed(node: BaseButton) -> void:
	if node.is_visible_in_tree():
		node.grab_focus()
