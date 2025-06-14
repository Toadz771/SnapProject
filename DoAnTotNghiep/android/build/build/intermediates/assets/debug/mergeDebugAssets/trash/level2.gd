extends Node

var held_object = null
var http_request = HTTPRequest.new()
var spawned_object = null
@onready var camera_button = $CanvasLayer/TopUI/LeftButtons/CameraButton
@onready var button_2 = $CanvasLayer/TopUI/LeftButtons/Button2
@onready var button_3 = $CanvasLayer/TopUI/LeftButtons/Button3
@onready var settings_button = $CanvasLayer/TopUI/SettingsButton
@onready var goal_counter = $CanvasLayer/TopUI/GoalCounter
@onready var player = $CharacterBody2D  # Reference to the player

var scanning_active = false
var camera_plugin = null
var current_scanned_object = ""
var level: int = 2  # Level 1

func _ready():
	print("Main scene (Level ", level, ") initialized")
	print("CanvasLayer: ", $CanvasLayer)
	
	# Report total puzzles to LevelManager
	var total_puzzles = get_tree().get_nodes_in_group("npc").size()
	LevelManager.set_total_puzzles(level, total_puzzles)
	print("Detected ", total_puzzles, " NPCs (puzzles) in Level ", level)
	
	# Connect pickable objects
	for node in get_tree().get_nodes_in_group("pickable"):
		node.clicked.connect(_on_pickable_clicked)
		node.dropped_on_npc.connect(_on_object_dropped_on_npc)

	# Connect NPCs for puzzle solving
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc.has_signal("puzzle_solved"):
			npc.puzzle_solved.connect(_on_puzzle_solved)
		else:
			print("Warning: NPC ", npc.name, " does not have puzzle_solved signal")

	# Update goal counter using LevelManager
	if goal_counter:
		update_goal_counter()

	if camera_button:
		print("Camera button found")
		var err = camera_button.pressed.connect(_on_camera_button_pressed)
		if err != OK:
			print("Failed to connect camera button pressed signal: ", err)
	else:
		print("Camera button not found")
	
	if button_2:
		button_2.pressed.connect(_on_button_2_pressed)
	if button_3:
		button_3.pressed.connect(_on_button_3_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_button_pressed)
	
	if Engine.has_singleton("GodotGetImage"):
		camera_plugin = Engine.get_singleton("GodotGetImage")
		print("Camera plugin found")
		var err1 = camera_plugin.connect("image_request_completed", Callable(self, "_on_image_request_completed"))
		var err2 = camera_plugin.connect("permission_not_granted_by_user", Callable(self, "_on_permission_denied"))
		if err1 != OK:
			print("Failed to connect image_request_completed: ", err1)
		if err2 != OK:
			print("Failed to connect permission_not_granted_by_user: ", err2)
	else:
		print("Camera plugin not found. Camera unavailable.")
	
	add_child(http_request)
	var err3 = http_request.request_completed.connect(_on_http_request_completed)
	if err3 != OK:
		print("Failed to connect HTTP request_completed: ", err3)

	# Position player based on portal entry
	if player:
		var entry_portal_level = LevelManager.get_last_entry_portal()
		if entry_portal_level != -1:
			print("Player entered Level ", level, " from portal to Level ", entry_portal_level)
			for portal in get_tree().get_nodes_in_group("portals"):
				if portal.target_level == entry_portal_level:
					player.global_position = portal.get_spawn_position()
					print("Player spawned at ", player.global_position, " near portal to Level ", entry_portal_level)
					break
					
	LevelManager.set_last_entry_portal(level)

func _on_http_request_completed(result, response_code, headers, body):
	print("HTTP request completed with result: ", result, ", response code: ", response_code)
	scanning_active = false
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		if parse_result == OK:
			var response = json.get_data()
			if response is Dictionary and "object" in response:
				var object_name = response["object"]
				if object_name != "none":
					spawn_object(object_name)
				print("Received from server: ", response)
			else:
				print("Invalid response format: ", response)
		else:
			print("Failed to parse server response: ", json.get_error_message())
	else:
		print("HTTP request failed: ", result, ", Response code: ", response_code)
		if body:
			print("Response body: ", body.get_string_from_utf8())
		if ConnectionManager.is_connected:
			ConnectionManager._handle_disconnection()

func spawn_object(object_type):
	var scene_path = "res://scenes/objects/" + object_type + ".tscn"
	print("Attempting to load scene: ", scene_path)
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
				print("Spawned: ", obj.name)
			else:
				print("Error: Loaded scene root is not RigidBody2D, got: ", obj.get_class())
		else:
			print("Error: Resource is not a PackedScene: ", scene_path)
	else:
		print("No scene found for: ", scene_path)

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
	print("Camera button pressed at: ", Time.get_ticks_msec())
	if camera_plugin and ConnectionManager.is_connected:
		print("Camera plugin is available")
		if OS.get_granted_permissions().find("android.permission.CAMERA") == -1:
			print("Requesting camera permission")
			OS.request_permission("android.permission.CAMERA")
			await get_tree().create_timer(1.0).timeout
			if OS.get_granted_permissions().find("android.permission.CAMERA") == -1:
				print("Camera permission denied")
				return
			print("Camera permission granted")
		print("Getting camera image")
		camera_plugin.getCameraImage()
		scanning_active = true
		current_scanned_object = ""
	else:
		print("Camera plugin not found or not connected")

func _on_image_request_completed(dict):
	print("Image request completed")
	if $CanvasLayer:
		$CanvasLayer.visible = true
	if dict and dict.has("0") and ConnectionManager.is_connected:
		var image_buffer = dict["0"]
		print("Image buffer size: ", image_buffer.size())
		if image_buffer.size() > 0:
			var img = Image.new()
			var jpg_err = img.load_jpg_from_buffer(image_buffer)
			if jpg_err == OK:
				print("Image loaded as JPG")
			else:
				var png_err = img.load_png_from_buffer(image_buffer)
				if png_err == OK:
					print("Image loaded as PNG")
				else:
					print("Failed to load image: JPG error ", jpg_err, ", PNG error ", png_err)
					scanning_active = false
					return
			var max_size = Vector2i(320, 240)
			if img.get_width() > max_size.x or img.get_height() > max_size.y:
				img.resize(max_size.x, max_size.y, Image.INTERPOLATE_LANCZOS)
				print("Image resized to: ", img.get_size())
			var png_bytes = img.save_png_to_buffer()
			print("PNG bytes size: ", png_bytes.size())
			var base64_image = Marshalls.raw_to_base64(png_bytes)
			print("Base64 image length: ", base64_image.length())
			if base64_image.length() == 0:
				print("Base64 encoding failed")
				scanning_active = false
				return
			if not base64_image.begins_with("iVBORw0KGgo"):
				print("Invalid base64: does not start with PNG header")
				scanning_active = false
				return
			var message = {"type": "image", "data": base64_image}
			print("Message dictionary: ", {"type": "image", "data_length": message["data"].length()})
			var json_string = JSON.stringify(message)
			print("JSON payload length: ", json_string.length())
			if json_string.length() < 50:
				print("Invalid JSON payload: ", json_string)
				scanning_active = false
				return
			print("JSON payload preview: ", json_string.substr(0, 100), "...")
			var headers = ["Content-Type: application/json"]
			var url = "http://192.168.61.101:5000/detect"
			var req_err = http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)
			if req_err == OK:
				print("Sent image to server")
			else:
				print("Failed to send HTTP request: ", req_err)
				scanning_active = false
		else:
			print("No image data")
			scanning_active = false
	else:
		print("Invalid image dictionary or not connected")
		scanning_active = false

func _on_permission_denied():
	print("Permission denied")
	if $CanvasLayer:
		$CanvasLayer.visible = true
	scanning_active = false
	if camera_plugin:
		camera_plugin.resendPermission()

func _on_button_2_pressed():
	print("Button 2 pressed")

func _on_button_3_pressed():
	print("Button 3 pressed")

func _on_settings_button_pressed():
	print("Settings button pressed")

func _exit_tree():
	http_request.queue_free()

func _on_object_dropped_on_npc(object):
	print("Object dropped: ", object.name, " at ", Time.get_ticks_msec())
	var overlapping_npcs = get_tree().get_nodes_in_group("npc")
	for npc in overlapping_npcs:
		if npc.overlaps_area(object):
			print("Found overlapping NPC: ", npc.name, " at ", Time.get_ticks_msec())
			npc._on_object_dropped(object)
			break
		else:
			print("No overlap with NPC: ", npc.name, " at ", Time.get_ticks_msec())

func _on_puzzle_solved():
	print("Puzzle solved signal received for Level ", level)
	LevelManager.puzzle_solved(level)
	if goal_counter:
		update_goal_counter()

func update_goal_counter():
	if LevelManager.completed_puzzles[level] >= LevelManager.total_puzzles_per_level[level]:
		goal_counter.text = "All objectives cleared"
	else:
		goal_counter.text = str(LevelManager.completed_puzzles[level]) + "/" + str(LevelManager.total_puzzles_per_level[level])
