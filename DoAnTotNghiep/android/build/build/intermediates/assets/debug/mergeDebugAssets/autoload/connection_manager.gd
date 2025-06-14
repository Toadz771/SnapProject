extends Node

var is_connected: bool = true
var current_popup: Control = null
var disconnect_popup_scene: PackedScene = preload("res://scenes/ui/disconnectpopup.tscn")
var http_request: HTTPRequest = null
var connection_timer: Timer = null
var canvas_layer: CanvasLayer = null  # New CanvasLayer to hold the popup

func _ready():
	# Create and add CanvasLayer
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10  # High layer to ensure it’s on top
	add_child(canvas_layer)
	
	setup_connection_monitor()
	var current_scene = get_tree().current_scene
	if current_scene:
		print("Current scene name: ", current_scene.name)

func setup_connection_monitor():
	# Clean up existing timer and request
	if connection_timer and is_instance_valid(connection_timer):
		connection_timer.stop()
		connection_timer.queue_free()
	if http_request and is_instance_valid(http_request):
		http_request.queue_free()
	
	# Create new HTTPRequest
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_connection_check_completed)
	http_request.timeout = 2.0
	
	# Create new Timer
	connection_timer = Timer.new()
	add_child(connection_timer)
	connection_timer.wait_time = 2.0
	connection_timer.connect("timeout", _check_connection)
	connection_timer.start()
	
	# Initial check
	_check_connection()

func _check_connection():
	if http_request and not is_instance_valid(http_request):
		http_request = null
	if http_request:
		http_request.queue_free()
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_connection_check_completed)
	http_request.timeout = 2.0
	
	var headers = ["Content-Type: application/json"]
	var url = "http://192.168.43.45:5000/health"
	var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		if is_instance_valid(http_request):
			http_request.queue_free()
		_handle_disconnection()

func _on_connection_check_completed(result, response_code, headers, body):
	if http_request and is_instance_valid(http_request):
		print("Connection check: Request completed - Result: ", result, ", Response Code: ", response_code)
		http_request.queue_free()
		http_request = null
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		if not is_connected:
			is_connected = true
			_handle_reconnection()
	else:
		is_connected = false
		_handle_disconnection()

func _handle_disconnection():
	if not is_connected and (not current_popup or not current_popup.visible):
		if disconnect_popup_scene and canvas_layer:
			current_popup = disconnect_popup_scene.instantiate()
			if current_popup:
				current_popup.reconnect_pressed.connect(_on_reconnect_pressed)
				canvas_layer.add_child(current_popup)  # Add to CanvasLayer instead of scene root
				current_popup.visible = true
				get_tree().paused = true
				print("Disconnect popup displayed on CanvasLayer")

func _handle_reconnection():
	if current_popup and current_popup.visible:
		current_popup.visible = false
		current_popup.queue_free()
		current_popup = null
		get_tree().paused = false
		print("Reconnection successful, popup closed")

func _on_reconnect_pressed():
	print("Reconnect attempt started (resetting like _ready)")
	if current_popup and current_popup.visible:
		current_popup.visible = false
	if http_request and is_instance_valid(http_request):
		http_request.queue_free()
	if current_popup and is_instance_valid(current_popup):
		current_popup.queue_free()
	current_popup = null
	is_connected = false
	get_tree().paused = false
	setup_connection_monitor()
