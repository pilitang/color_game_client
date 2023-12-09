@tool
class_name BaseControl
extends Control

signal result_data(value)
signal init_complete()
signal load_anim_complete()
signal on_click(node)
signal on_long_click(node)

var 	clickTime = 0
var 	clickPosition = Vector2.ZERO
var itemRoot : BaseControl = null

enum {
	RESULT_OK,
	RESULT_CANCELED
}

class GResult :
	var code = RESULT_OK
	var data = null
	func _init(p_code,p_data = null):
		self.code = p_code
		self.data = p_data



@export var styleBox : StyleBox = null : set = set_styleBox
@export var enter_anim :  Animation = null
@export var exit_anim :  Animation = null
@export var is_anim = true
@export var on_click_anim :  Animation = null
var baseAnimationPlayer : AnimationPlayer = null
func _ready():
	await get_tree().process_frame
	if is_anim:
		init_anim()
		playEnter()
	
	await get_tree().create_timer(0.2)
	init_complete.emit()
	

func init_anim():	
	if enter_anim == null and exit_anim == null :
		return
	baseAnimationPlayer = AnimationPlayer.new()
	var animationLibrary = AnimationLibrary.new()
	if enter_anim != null :
		animationLibrary.add_animation("enter",enter_anim)
	if exit_anim != null :
		animationLibrary.add_animation("exit",exit_anim)
	if on_click_anim != null:
		animationLibrary.add_animation("on_click_anim",on_click_anim)
	baseAnimationPlayer.add_animation_library("",animationLibrary)
	add_child(baseAnimationPlayer)
#	
	
func playEnter():
	if enter_anim != null and baseAnimationPlayer != null :
		baseAnimationPlayer.play("enter")


		
func playExit():
	if exit_anim != null and baseAnimationPlayer != null :
		baseAnimationPlayer.play("exit")
		await baseAnimationPlayer.animation_finished

#func queue_free():
#	if is_anim:
#		await playExit()
#	super.queue_free()

func set_styleBox(value) :
	styleBox = value
	queue_redraw()
	
func _gui_input(event):
#	if event is InputEventMouseMotion:
		
	if event is InputEventScreenTouch :
		if event.pressed == true:
			clickTime = Time.get_ticks_msec()
			clickPosition = event.position
		if event.pressed == false:
			var diff = Time.get_ticks_msec() - clickTime
			clickTime = 0
			if event.position.distance_to(clickPosition)<2 :
				if mouse_filter == Control.MOUSE_FILTER_STOP :
					accept_event()
				if diff < 800:
					emit_signal("on_click",self)
					if on_click_anim != null and baseAnimationPlayer != null :
						baseAnimationPlayer.play("on_click_anim")
					click()
				else :
					emit_signal("on_long_click",self)
					long_click()
				
func click():
	pass
func long_click():
	pass

	
func _draw():
	if styleBox !=null :
		draw_style_box(styleBox, Rect2(Vector2(0,0) ,  size ))


