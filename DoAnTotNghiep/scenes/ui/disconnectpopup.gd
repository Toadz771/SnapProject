extends Control

signal reconnect_pressed

@onready var message_label = $PopupCenter/PopupPanel/Message
@onready var reconnect_button = $PopupCenter/PopupPanel/ReconnectButton

func _ready():
	reconnect_button.pressed.connect(_on_reconnect_button_pressed)
	reconnect_button.mouse_filter = Control.MOUSE_FILTER_STOP
	reconnect_button.disabled = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_reconnect_button_pressed():
	message_label.text = "Reconnecting..."
	emit_signal("reconnect_pressed")

func reset_label_text():
	message_label.text = "Connection to the server lost! Please try again with a better internet condition!"
