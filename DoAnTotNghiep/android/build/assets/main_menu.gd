extends Control

func _ready():
	pass

func _process(delta):
	pass

func _on_start_game_button_pressed():
	TransitionManager.transition_to_scene("res://level_select.tscn")

func _on_options_button_pressed():
	TransitionManager.transition_to_scene("res://scenes/ui/options.tscn")

func _on_exit_button_pressed():
	TransitionManager.transition_to_quit()
