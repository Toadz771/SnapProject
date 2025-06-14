extends CanvasLayer

var target_scene: String = ""
var should_quit: bool = false

@onready var dissolve_rect = $DissolveRect
@onready var animation_player = $AnimationPlayer

func _ready():
	# Set layer to render above scenes
	layer = 100
	# Initialize shader
	dissolve_rect.visible = false
	if dissolve_rect.material:
		dissolve_rect.material.set_shader_parameter("dissolve_threshold", 0.0)

func transition_to_scene(scene_path: String):
	if ResourceLoader.exists(scene_path):
		target_scene = scene_path
		should_quit = false
		animation_player.play("dissolve_to_black")
	else:
		push_error("Scene not found: " + scene_path)

func transition_to_quit():
	should_quit = true
	animation_player.play("dissolve_to_black")

func _on_animation_finished(anim_name: String):
	if anim_name == "dissolve_to_black":
		if should_quit:
			get_tree().quit()
		else:
			if target_scene != "":
				var error = get_tree().change_scene_to_file(target_scene)
				if error != OK:
					push_error("Failed to change scene: " + target_scene)
				else:
					# Ensure new scene is loaded before dissolving
					await get_tree().process_frame
					animation_player.play("dissolve_from_black")
			else:
				push_error("No target scene set")
	elif anim_name == "dissolve_from_black":
		dissolve_rect.visible = false
		target_scene = ""
