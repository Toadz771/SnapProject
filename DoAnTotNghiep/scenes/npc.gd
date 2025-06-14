extends Area2D

@export var required_objects: Array[String] = ["Chair"]
@export var exclamation_text: String = "!!!!"
@export var unsolved_text: String = "I have been standing here for so long... I really need a chair"
@export var solved_text: String = "Great... now the gamemaker is forcing me to dance..."
@export var sprite_frames: SpriteFrames
@onready var interaction_container = $LabelContainer
@onready var exclamation_container = $ExclamationContainer
@onready var animated_sprite = $AnimatedSprite2D
@onready var explosion_particles = $ExplosionParticles

var interacting = false
var time = 0.0
var initial_position = Vector2.ZERO
var is_puzzle_solved = false

var jump_button = null
var interact_button = null
var player = null

signal puzzle_solved

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if exclamation_container:
		exclamation_container.get_node("MarginContainer/Label").text = exclamation_text
	if interaction_container:
		interaction_container.get_node("MarginContainer/Label").text = unsolved_text
	interaction_container.visible = false
	exclamation_container.visible = false
	initial_position = position
	if animated_sprite:
		if sprite_frames:
			animated_sprite.sprite_frames = sprite_frames
			animated_sprite.play("default")
	jump_button = get_ui_node_or_null("JumpButtonContainer/JumpButton")
	interact_button = get_ui_node_or_null("JumpButtonContainer/InteractButton")

func _process(delta):
	if not interacting and not is_puzzle_solved:
		for body in get_tree().get_nodes_in_group("pickable"):
			if body.global_position.distance_to(global_position) < 120 and not body.get("held"):
				_on_object_dropped(body)

func _on_body_entered(body):
	if body.is_in_group("player"):
		interacting = true
		player = body
		exclamation_container.visible = true
		interaction_container.visible = false
		if jump_button and interact_button:
			jump_button.visible = false
			interact_button.visible = true
		if player and player.has_method("set_can_interact"):
			player.set_can_interact(true)

func _on_body_exited(body):
	if body.is_in_group("player"):
		interacting = false
		player = null
		exclamation_container.visible = false
		interaction_container.visible = false
		if jump_button and interact_button:
			jump_button.visible = true
			interact_button.visible = false
		if body and body.has_method("set_can_interact"):
			body.set_can_interact(false)

func _input(event):
	if interacting:
		if event is InputEventScreenTouch and event.pressed:
			if is_inside_interact_button(event.position):
				if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
					exclamation_container.visible = false
					interaction_container.visible = true
					if is_puzzle_solved:
						interaction_container.get_node("MarginContainer/Label").text = solved_text
					else:
						interaction_container.get_node("MarginContainer/Label").text = unsolved_text

func _on_object_dropped(object):
	if not is_puzzle_solved and object.name in required_objects:
		is_puzzle_solved = true
		emit_signal("puzzle_solved")
		if explosion_particles:
			explosion_particles.emitting = true
		if animated_sprite:
			if sprite_frames and sprite_frames.has_animation("satisfied"):
				animated_sprite.play("satisfied")
		object.queue_free()

func get_ui_node_or_null(path: String):
	var root = get_tree().root
	var current_scene = get_tree().current_scene
	if current_scene:
		var canvas_layer = current_scene.get_node_or_null("CanvasLayer")
		if canvas_layer:
			var ui_node = canvas_layer.get_node_or_null("UI/" + path)
			if ui_node:
				return ui_node
		canvas_layer = root.get_node_or_null("CanvasLayer")
		if canvas_layer:
			var ui_node = canvas_layer.get_node_or_null("UI/" + path)
			if ui_node:
				return ui_node
	return null

func is_inside_interact_button(touch_pos: Vector2) -> bool:
	if not interact_button:
		return false
	var button_size = interact_button.texture_normal.get_size() * interact_button.scale
	var button_rect = Rect2(interact_button.global_position, button_size)
	return button_rect.has_point(touch_pos)
