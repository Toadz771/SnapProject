extends Area2D

@export var target_level: int = 1
@export var level_scene_path: String = "res://scenes/levels/level1.tscn"
@export var spawn_offset: Vector2 = Vector2(50, 0)

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var has_entered: bool = false # Prevent multiple transitions

func _ready():
	if target_level == -1 or level_scene_path.is_empty() or not spawn_point or not collision_shape:
		visible = false
		monitoring = false
		return
	
	spawn_point.position = spawn_offset
	update_portal_state()
	LevelManager.level_unlocked.connect(_on_level_unlocked)
	add_to_group("portals")

func update_portal_state():
	if LevelManager.is_level_unlocked(target_level):
		visible = true
		monitoring = true
		monitorable = true
	else:
		visible = false
		monitoring = false
		monitorable = false

func _on_level_unlocked(level: int):
	if level == target_level:
		update_portal_state()

func _process(_delta):
	if Engine.is_editor_hint() and spawn_point:
		spawn_point.position = spawn_offset

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") and LevelManager.is_level_unlocked(target_level) and not has_entered:
		has_entered = true
		var current_level = get_tree().current_scene.level
		LevelManager.set_last_entry_portal(current_level)
		if ResourceLoader.exists(level_scene_path):
			TransitionManager.transition_to_scene(level_scene_path)

func get_spawn_position() -> Vector2:
	return global_position + spawn_offset
