extends Area2D

@export var required_objects: Array[String] = ["Chair"]  # List of acceptable objects (only one needed)
@export var exclamation_text: String = "!!!!"  # Customizable exclamation text
@export var unsolved_text: String = "I have been standing here for so long... I really need a chair"  # Text when unsolved
@export var solved_text: String = "Great... now the gamemaker is forcing me to dance..."  # Text when solved
@onready var interaction_container = $LabelContainer  # Reference to the entire interaction container
@onready var exclamation_container = $ExclamationContainer  # Reference to the entire exclamation container
@onready var animated_sprite = $AnimatedSprite2D  # Reference to AnimatedSprite2D
var interacting = false
var time = 0.0  # For idle movement
var initial_position = Vector2.ZERO  # Store the NPC's starting position
var is_puzzle_solved = false  # Track puzzle state

# UI references
var jump_button = null
var interact_button = null
var player = null  # Reference to the player

signal puzzle_solved

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Set initial text for containers
	if exclamation_container:
		exclamation_container.get_node("MarginContainer/Label").text = exclamation_text
	else:
		print("ExclamationContainer not found on NPC ", name)
	if interaction_container:
		interaction_container.get_node("MarginContainer/Label").text = unsolved_text
	else:
		print("LabelContainer not found on NPC ", name)
	
	interaction_container.visible = false  # Hide interaction container initially
	exclamation_container.visible = false  # Hide exclamation container initially
	# Store initial position for idle movement
	initial_position = position
	# Start playing the idle animation
	if animated_sprite:
		animated_sprite.play("default")
	else:
		print("AnimatedSprite2D not found on NPC ", name)
	
	# Find UI nodes dynamically
	jump_button = get_ui_node_or_null("JumpButtonContainer/JumpButton")
	interact_button = get_ui_node_or_null("JumpButtonContainer/InteractButton")
	
	if not jump_button or not interact_button:
		print("Warning: JumpButton or InteractButton not found for NPC ", name)

func _process(delta):
	if not interacting and not is_puzzle_solved:
		for body in get_tree().get_nodes_in_group("pickable"):
			if body.global_position.distance_to(global_position) < 50 and not body.get("held"):
				_on_object_dropped(body)

func _on_body_entered(body):
	if body.is_in_group("player"):
		interacting = true
		player = body  # Store reference to the player
		exclamation_container.visible = true  # Show exclamation container
		interaction_container.visible = false  # Hide interaction container
		# Show InteractButton, hide JumpButton
		if jump_button and interact_button:
			jump_button.visible = false
			interact_button.visible = true
			print("Player near NPC ", name, ", showing InteractButton")
		if player and player.has_method("set_can_interact"):
			player.set_can_interact(true)

func _on_body_exited(body):
	if body.is_in_group("player"):
		interacting = false
		player = null  # Clear player reference
		exclamation_container.visible = false  # Hide exclamation container
		interaction_container.visible = false  # Hide interaction container
		# Show JumpButton, hide InteractButton
		if jump_button and interact_button:
			jump_button.visible = true
			interact_button.visible = false
			print("Player away from NPC ", name, ", showing JumpButton")
		if body and body.has_method("set_can_interact"):
			body.set_can_interact(false)

func _input(event):
	if interacting:
		if event is InputEventScreenTouch and event.pressed:
			if is_inside_interact_button(event.position):  # Check if touch is within InteractButton
				if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
					# Interact button pressed, show text container and hide exclamation container
					exclamation_container.visible = false
					interaction_container.visible = true
					if is_puzzle_solved:
						interaction_container.get_node("MarginContainer/Label").text = solved_text
					else:
						interaction_container.get_node("MarginContainer/Label").text = unsolved_text
					print("Interacted with NPC, showing: ", interaction_container.get_node("MarginContainer/Label").text)

func _on_object_dropped(object):
	if not is_puzzle_solved and object.name in required_objects:
		print("Puzzle solved! NPC received ", object.name)
		is_puzzle_solved = true
		emit_signal("puzzle_solved")
		if animated_sprite:
			animated_sprite.play("satisfied")
		else:
			print("Cannot play satisfied animation: AnimatedSprite2D not found")
		object.queue_free()
		print("Removed object: ", object.name)
	else:
		print("Wrong object dropped! Expected one of: ", required_objects, ", got: ", object.name)

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

# Function to check InteractButton bounds
func is_inside_interact_button(touch_pos: Vector2) -> bool:
	if not interact_button:
		return false
	var button_size = interact_button.texture_normal.get_size() * interact_button.scale
	var button_rect = Rect2(interact_button.global_position, button_size)
	return button_rect.has_point(touch_pos)
