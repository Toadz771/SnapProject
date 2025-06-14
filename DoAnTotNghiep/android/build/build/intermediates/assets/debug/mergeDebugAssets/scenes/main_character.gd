extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -900.0
const PUSH_FORCE = 150.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 1.5

@onready var sprite_2d = $Sprite2D
@onready var joystick_base = get_ui_node_or_null("JoystickBase")
@onready var joystick_knob = get_ui_node_or_null("JoystickBase/JoystickKnob")
@onready var jump_button = get_ui_node_or_null("JumpButtonContainer/JumpButton")
@onready var jump_anim = get_ui_node_or_null("JumpButtonContainer/JumpButton/AnimationPlayer")
@onready var interact_button = get_ui_node_or_null("JumpButtonContainer/InteractButton")
@onready var interact_anim = get_ui_node_or_null("JumpButtonContainer/InteractButton/AnimationPlayer")  # New reference

var joystick_active = false
var joystick_direction = Vector2.ZERO
var joystick_radius = 100.0  
var effective_knob_size = Vector2.ZERO
var knob_rest_position = Vector2.ZERO

var active_touches = {}  # Tracks all active touches
var joystick_touch_id = -1  # Tracks which finger is controlling the joystick
var can_interact = false  # Tracks if player is near an NPC

func _ready():
	if not joystick_base or not joystick_knob or not jump_button or not jump_anim or not interact_button or not interact_anim:
		print("Warning: Some UI elements not found, disabling touch controls")
		return
	
	# Joystick Setup
	joystick_base.size = Vector2(100, 100)
	var effective_size = joystick_base.size * joystick_base.scale
	joystick_base.position = Vector2(75.0, -effective_size.y - 75.0)
	
	var knob_texture_size = joystick_knob.texture_normal.get_size() if joystick_knob.texture_normal else Vector2(50, 50)
	effective_knob_size = knob_texture_size * joystick_knob.scale * joystick_base.scale
	
	var base_center_global = joystick_base.global_position + (joystick_base.size * joystick_base.scale / 2)
	var desired_knob_global = base_center_global - effective_knob_size / 2
	knob_rest_position = (desired_knob_global - joystick_base.global_position) / joystick_base.scale
	joystick_knob.position = knob_rest_position
	
	# Jump and Interact Button Setup
	jump_button.scale = Vector2(1.5, 1.5)
	interact_button.scale = Vector2(1.5, 1.5)
	var jump_button_container = jump_button.get_parent()
	var jump_button_size = jump_button.texture_normal.get_size() * jump_button.scale if jump_button.texture_normal else Vector2(50, 50)
	var effective_jump_size = jump_button_size * jump_button_container.scale
	jump_button_container.position = Vector2(get_viewport_rect().size.x - 75.0 - effective_jump_size.x, -effective_jump_size.y - 75.0)
	
	jump_button.visible = true
	interact_button.visible = false

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	var direction = joystick_direction.x if joystick_base else Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 10 * delta)

	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is RigidBody2D:
			collider.apply_central_impulse(-collision.get_normal() * PUSH_FORCE)

	if is_on_floor():
		if direction != 0:
			sprite_2d.flip_h = direction < 0
			sprite_2d.animation = "running"
		else:
			sprite_2d.animation = "default"
	else:
		sprite_2d.animation = "jumping"

func _input(event):
	if not joystick_base or not jump_button:
		return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			active_touches[event.index] = event.position
			handle_touch_start(event.index, event.position)
		else:
			if event.index in active_touches:
				active_touches.erase(event.index)
			handle_touch_end(event.index)

	elif event is InputEventScreenDrag:
		if event.index in active_touches:
			active_touches[event.index] = event.position
			handle_touch_move(event.index, event.position)

func handle_touch_start(index, position):
	if joystick_touch_id == -1 and is_inside_joystick(position):
		joystick_active = true
		joystick_touch_id = index
		update_joystick(position)

	# Separate checks for JumpButton and InteractButton
	if is_inside_jump_button(position) and jump_button.visible:
		if is_on_floor() and jump_button and jump_button.visible:
			velocity.y = JUMP_VELOCITY
			if jump_anim:
				jump_anim.play("press")
	elif is_inside_interact_button(position) and interact_button.visible:
		if can_interact and interact_button and interact_button.visible:
			var event = InputEventKey.new()
			event.keycode = KEY_E
			event.pressed = true
			Input.parse_input_event(event)
			if interact_anim:
				interact_anim.play("press")

func handle_touch_end(index):
	if index == joystick_touch_id:
		joystick_active = false
		joystick_touch_id = -1
		if joystick_knob:
			joystick_knob.position = knob_rest_position
		joystick_direction = Vector2.ZERO

func handle_touch_move(index, position):
	if index == joystick_touch_id and joystick_knob:
		update_joystick(position)

func is_inside_joystick(touch_pos: Vector2) -> bool:
	if not joystick_base:
		return false
	var base_center_global = joystick_base.global_position + (joystick_base.size * joystick_base.scale / 2)
	var knob_rect = Rect2(base_center_global - effective_knob_size / 2, effective_knob_size)
	return knob_rect.has_point(touch_pos)

func is_inside_jump_button(touch_pos: Vector2) -> bool:
	if not jump_button:
		return false
	var button_size = jump_button.texture_normal.get_size() * jump_button.scale
	var button_rect = Rect2(jump_button.global_position, button_size)
	return button_rect.has_point(touch_pos)

# New function to check InteractButton bounds
func is_inside_interact_button(touch_pos: Vector2) -> bool:
	if not interact_button:
		return false
	var button_size = interact_button.texture_normal.get_size() * interact_button.scale
	var button_rect = Rect2(interact_button.global_position, button_size)
	return button_rect.has_point(touch_pos)

func update_joystick(touch_pos):
	if not joystick_base or not joystick_knob:
		return
	var base_center_global = joystick_base.global_position + (joystick_base.size * joystick_base.scale / 2)
	var offset = touch_pos - base_center_global
	var distance = offset.length()

	if distance > joystick_radius:
		offset = offset.normalized() * joystick_radius

	var desired_knob_center_global = base_center_global + offset
	var desired_knob_global = desired_knob_center_global - effective_knob_size / 2
	joystick_knob.position = (desired_knob_global - joystick_base.global_position) / joystick_base.scale
	joystick_direction = offset / joystick_radius

# Helper function to dynamically find UI nodes
func get_ui_node_or_null(path: String):
	var root = get_tree().root
	var current_scene = get_tree().current_scene
	if current_scene:
		# Try to find UI under the current scene's CanvasLayer
		var canvas_layer = current_scene.get_node_or_null("CanvasLayer")
		if canvas_layer:
			var ui_node = canvas_layer.get_node_or_null("UI/" + path)
			if ui_node:
				return ui_node
		# Fallback to root CanvasLayer if exists
		canvas_layer = root.get_node_or_null("CanvasLayer")
		if canvas_layer:
			var ui_node = canvas_layer.get_node_or_null("UI/" + path)
			if ui_node:
				return ui_node
	return null

# Public method for NPC to set interaction state
func set_can_interact(value: bool):
	can_interact = value
