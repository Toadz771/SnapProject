extends Control

@onready var level_0_button = $VBoxContainer/Level0Button
@onready var level_1_button = $VBoxContainer/Row1/Level1Button
@onready var level_2_button = $VBoxContainer/Row1/Level2Button
@onready var level_3_button = $VBoxContainer/Row1/Level3Button
@onready var level_4_button = $VBoxContainer/Row1/Level4Button
@onready var level_5_button = $VBoxContainer/Row1/Level5Button
@onready var level_6_button = $VBoxContainer/Row2/Level6Button
@onready var level_7_button = $VBoxContainer/Row2/Level7Button
@onready var level_8_button = $VBoxContainer/Row2/Level8Button
@onready var level_9_button = $VBoxContainer/Row2/Level9Button
@onready var level_10_button = $VBoxContainer/Row2/Level10Button

func _ready():
	update_buttons()
	
	level_0_button.pressed.connect(_on_level_button_pressed.bind(0))
	level_1_button.pressed.connect(_on_level_button_pressed.bind(1))
	level_2_button.pressed.connect(_on_level_button_pressed.bind(2))
	level_3_button.pressed.connect(_on_level_button_pressed.bind(3))
	level_4_button.pressed.connect(_on_level_button_pressed.bind(4))
	level_5_button.pressed.connect(_on_level_button_pressed.bind(5))
	level_6_button.pressed.connect(_on_level_button_pressed.bind(6))
	level_7_button.pressed.connect(_on_level_button_pressed.bind(7))
	level_8_button.pressed.connect(_on_level_button_pressed.bind(8))
	level_9_button.pressed.connect(_on_level_button_pressed.bind(9))
	level_10_button.pressed.connect(_on_level_button_pressed.bind(10))

func update_buttons():
	level_0_button.disabled = not LevelManager.is_level_unlocked(0)
	level_1_button.disabled = not LevelManager.is_level_unlocked(1)
	level_2_button.disabled = not LevelManager.is_level_unlocked(2)
	level_3_button.disabled = not LevelManager.is_level_unlocked(3)
	level_4_button.disabled = not LevelManager.is_level_unlocked(4)
	level_5_button.disabled = not LevelManager.is_level_unlocked(5)
	level_6_button.disabled = not LevelManager.is_level_unlocked(6)
	level_7_button.disabled = not LevelManager.is_level_unlocked(7)
	level_8_button.disabled = not LevelManager.is_level_unlocked(8)
	level_9_button.disabled = not LevelManager.is_level_unlocked(9)
	level_10_button.disabled = not LevelManager.is_level_unlocked(10)

func _on_level_button_pressed(level: int):
	if LevelManager.is_level_unlocked(level):
		var scene_path = "res://main.tscn" if level == 0 else "res://scenes/levels/level" + str(level) + ".tscn"
		TransitionManager.transition_to_scene(scene_path)
	else:
		print("Level ", level, " is locked!")
