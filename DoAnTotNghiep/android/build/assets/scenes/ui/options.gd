extends Control

@onready var volume_slider = $MenuContainer/VolumeSlider
@onready var volume_label = $MenuContainer/VolumeLabel

func _ready():
	# Initialize slider value and update label
	volume_slider.value = 50  # Default volume
	update_volume_label()
	# Apply initial volume setting
	set_volume(volume_slider.value)

func _on_volume_slider_value_changed(value):
	# Update volume and label when slider changes
	set_volume(value)
	update_volume_label()

func set_volume(value: float):
	# Convert slider value (0-100) to decibels for AudioServer
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func update_volume_label():
	# Update label to show current volume
	volume_label.text = "Master Volume: " + str(int(volume_slider.value))

func _on_back_button_pressed():
	# Transition back to main menu
	TransitionManager.transition_to_scene("res://main_menu.tscn")
