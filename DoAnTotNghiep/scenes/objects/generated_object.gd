extends RigidBody2D

signal clicked
signal dropped_on_npc

var held = false
var offset = Vector2.ZERO
var touch_id = -1
var last_drag_pos = Vector2.ZERO
var drag_velocity = Vector2.ZERO
var was_held = false

func _ready():
	input_pickable = true
	contact_monitor = true
	max_contacts_reported = 10
	body_entered.connect(_on_body_entered)

func _input_event(viewport, event, shape_idx):
	if event is InputEventScreenTouch and event.pressed:
		touch_id = event.index
		clicked.emit(self)
		offset = global_position - event.position
		last_drag_pos = event.position

func _input(event):
	if held and event is InputEventScreenDrag and event.index == touch_id:
		var target_pos = event.position + offset
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(global_position, target_pos)
		var result = space_state.intersect_ray(query)
		if result.is_empty():
			drag_velocity = (event.position - last_drag_pos) * 10
			global_position = target_pos
			last_drag_pos = event.position

	if held and event is InputEventScreenTouch and not event.pressed and event.index == touch_id:
		drop(drag_velocity)

func _process(delta):
	if not held and was_held:
		var overlapping_bodies = get_colliding_bodies()
		for body in overlapping_bodies:
			if body.is_in_group("npc"):
				emit_signal("dropped_on_npc", self)
				break

func pickup():
	if held:
		return
	freeze = true
	held = true
	set_collision_layer_value(1, false)
	drag_velocity = Vector2.ZERO
	was_held = true

func drop(impulse=Vector2.ZERO):
	if held:
		freeze = false
		apply_central_impulse(impulse)
		held = false
		set_collision_layer_value(1, true)
		touch_id = -1

func _on_body_entered(body):
	if not held and was_held and body.is_in_group("npc"):
		emit_signal("dropped_on_npc", self)
