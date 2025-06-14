extends Node

@export var level: int = 1

var held_object = null
var http_request = HTTPRequest.new()
var spawned_object = null
@onready var camera_button = $CanvasLayer/TopUI/LeftButtons/CameraButton
@onready var home_button = $CanvasLayer/TopUI/LeftButtons/HomeButton
@onready var button_3 = $CanvasLayer/TopUI/LeftButtons/Button3
@onready var settings_button = $CanvasLayer/TopUI/SettingsButton
@onready var goal_counter = $CanvasLayer/TopUI/GoalCounter
@onready var player = $CharacterBody2D

var scanning_active = false
var camera_plugin = null
var current_scanned_object = ""

func _ready():
	var total_puzzles = get_tree().get_nodes_in_group("npc").size()
	LevelManager.set_total_puzzles(level, total_puzzles)

	for node in get_tree().get_nodes_in_group("pickable"):
		node.clicked.connect(_on_pickable_clicked)
		node.dropped_on_npc.connect(_on_object_dropped_on_npc)

	for npc in get_tree().get_nodes_in_group("npc"):
		if npc.has_signal("puzzle_solved"):
			npc.puzzle_solved.connect(_on_puzzle_solved)

	if goal_counter:
		update_goal_counter()

	if camera_button:
		camera_button.pressed.connect(_on_camera_button_pressed)

	if home_button:
		home_button.pressed.connect(_on_home_button_pressed)
	if button_3:
		button_3.pressed.connect(_on_button_3_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_button_pressed)

	if Engine.has_singleton("GodotGetImage"):
		camera_plugin = Engine.get_singleton("GodotGetImage")
		camera_plugin.connect("image_request_completed", Callable(self, "_on_image_request_completed"))
		camera_plugin.connect("permission_not_granted_by_user", Callable(self, "_on_permission_denied"))

	add_child(http_request)
	http_request.request_completed.connect(_on_http_request_completed)

	if player:
		var entry_portal_level = LevelManager.get_last_entry_portal()
		if entry_portal_level != -1:
			for portal in get_tree().get_nodes_in_group("portals"):
				if portal.target_level == entry_portal_level:
					player.global_position = portal.get_spawn_position()
					break

func _on_http_request_completed(result, response_code, headers, body):
	scanning_active = false
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var response = json.get_data()
			if response is Dictionary and "object" in response:
				var object_name = response["object"]
				if object_name != "none":
					spawn_object(object_name)

func spawn_object(object_type):
	var scene_path = "res://scenes/objects/" + object_type + ".tscn"
	if ResourceLoader.exists(scene_path):
		var packed_scene = load(scene_path)
		if packed_scene is PackedScene:
			var obj = packed_scene.instantiate()
			if obj is RigidBody2D:
				add_child(obj)
				spawned_object = obj
				var character = $CharacterBody2D
				if character:
					obj.global_position = character.global_position + Vector2(100, -50)
				else:
					obj.global_position = Vector2(100, 100)
				obj.add_to_group("pickable")
				obj.clicked.connect(_on_pickable_clicked)
				obj.dropped_on_npc.connect(_on_object_dropped_on_npc)

func _on_pickable_clicked(object):
	if !held_object:
		object.pickup()
		held_object = object

func _unhandled_input(event):
	if event is InputEventScreenTouch and not event.pressed:
		if held_object:
			held_object.drop(Vector2.ZERO)
			held_object = null

func _on_camera_button_pressed():
	if camera_plugin and ConnectionManager.is_connected:
		if OS.get_granted_permissions().find("android.permission.CAMERA") == -1:
			OS.request_permission("android.permission.CAMERA")
			await get_tree().create_timer(1.0).timeout
			if OS.get_granted_permissions().find("android.permission.CAMERA") == -1:
				return
		camera_plugin.getCameraImage()
		scanning_active = true
		current_scanned_object = ""

func _on_image_request_completed(dict):
	if $CanvasLayer:
		$CanvasLayer.visible = true
	if dict and dict.has("0") and ConnectionManager.is_connected:
		var image_buffer = dict["0"]
		if image_buffer.size() > 0:
			var img = Image.new()
			var jpg_err = img.load_jpg_from_buffer(image_buffer)
			if jpg_err != OK:
				var png_err = img.load_png_from_buffer(image_buffer)
				if png_err != OK:
					scanning_active = false
					return
			var max_size = Vector2i(320, 240)
			if img.get_width() > max_size.x or img.get_height() > max_size.y:
				img.resize(max_size.x, max_size.y, Image.INTERPOLATE_LANCZOS)
			var png_bytes = img.save_png_to_buffer()
			var base64_image = Marshalls.raw_to_base64(png_bytes)
			if base64_image.length() == 0:
				scanning_active = false
				return
			if not base64_image.begins_with("iVBORw0KGgo"):
				scanning_active = false
				return
			var message = {"type": "image", "data": base64_image}
			var json_string = JSON.stringify(message)
			if json_string.length() < 50:
				scanning_active = false
				return
			var headers = ["Content-Type: application/json"]
			var url = "http://192.168.61.101:5000/detect"
			var req_err = http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)
			if req_err != OK:
				scanning_active = false
		else:
			scanning_active = false
	else:
		scanning_active = false

func _on_permission_denied():
	if $CanvasLayer:
		$CanvasLayer.visible = true
	scanning_active = false
	if camera_plugin:
		camera_plugin.resendPermission()

func _on_home_button_pressed():
	TransitionManager.transition_to_scene("res://level_select.tscn")

func _on_button_3_pressed():
	pass

func _on_settings_button_pressed():
	TransitionManager.transition_to_scene("res://scenes/ui/options.tscn")

func _exit_tree():
	http_request.queue_free()

func _on_object_dropped_on_npc(object):
	var overlapping_npcs = get_tree().get_nodes_in_group("npc")
	for npc in overlapping_npcs:
		if npc.overlaps_area(object):
			npc._on_object_dropped(object)
			break

func _on_puzzle_solved():
	LevelManager.puzzle_solved(level)
	if goal_counter:
		update_goal_counter()

func update_goal_counter():
	if LevelManager.completed_puzzles[level] >= LevelManager.total_puzzles_per_level[level]:
		goal_counter.text = "Level cleared!!"
	else:
		goal_counter.text = str(LevelManager.completed_puzzles[level]) + "/" + str(LevelManager.total_puzzles_per_level[level])
