@tool
class_name BaseScrollContainer
extends ScrollContainer


func _init():
	disable_scrollbars()

func disable_scrollbars():
	var empty_stylebox = StyleBoxEmpty.new()
	get_v_scroll_bar().set("theme_override_styles/scroll",empty_stylebox)
	get_h_scroll_bar().set("theme_override_styles/scroll",empty_stylebox)
