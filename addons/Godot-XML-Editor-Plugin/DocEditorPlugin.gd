@tool
extends EditorPlugin

const MainScreen = preload("res://addons/XMLDocEditor/DocEditor.tscn")
var main_screen_instance

func _enter_tree():
	main_screen_instance = MainScreen.instantiate()
	get_editor_interface().get_editor_main_screen().add_child(main_screen_instance)
	_make_visible(false)

func _exit_tree():
	if main_screen_instance:
		main_screen_instance.queue_free()


func _has_main_screen():
	return true


func _make_visible(visible):
	if main_screen_instance:
		main_screen_instance.visible = visible


func _get_plugin_name():
	return "XMLDocEditor"


func _get_plugin_icon():
	return get_editor_interface().get_base_control().get_theme_icon("Node", "EditorIcons")
