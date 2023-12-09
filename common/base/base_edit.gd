class_name BaseEdit
extends BaseControl

func _init():
	disable_scrollbars()

func disable_scrollbars():
	if is_class("TextEdit") :
		var empty_stylebox = StyleBoxEmpty.new()
		call("get_v_scroll_bar").set("theme_override_styles/scroll",empty_stylebox)
		call("get_h_scroll_bar").set("theme_override_styles/scroll",empty_stylebox)

func _ready():
	if is_class("LineEdit") :
		connect("text_change_rejected",Callable(self,"_on_content_text_change_rejected"))

func _on_content_text_change_rejected(rejected_substring):
	ToastRouter.showToast("不可以超过 "+str(self.max_length)+" 个字")
	pass # Replace with function body.

