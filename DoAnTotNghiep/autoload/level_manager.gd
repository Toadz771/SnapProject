extends Node

signal level_unlocked(level: int)

const TOTAL_LEVELS = 10

var unlocked_levels = {}
var total_puzzles_per_level = {}
var completed_puzzles = {}
var last_entry_portal: int = -1

func _ready():
	for level in range(0, TOTAL_LEVELS + 1):
		unlocked_levels[level] = false
		completed_puzzles[level] = 0
		total_puzzles_per_level[level] = 0
	unlocked_levels[0] = true
	unlocked_levels[1] = true

func is_level_unlocked(level: int) -> bool:
	if level < 0 or level > TOTAL_LEVELS:
		return false
	return unlocked_levels[level]

func set_total_puzzles(level: int, total: int):
	if level < 0 or level > TOTAL_LEVELS:
		return
	total_puzzles_per_level[level] = total

func puzzle_solved(level: int):
	if level < 0 or level > TOTAL_LEVELS:
		return
	completed_puzzles[level] += 1
	if level >= 1:
		if total_puzzles_per_level[level] > 0 and completed_puzzles[level] >= total_puzzles_per_level[level]:
			var next_level = level + 1
			if next_level <= TOTAL_LEVELS:
				unlocked_levels[next_level] = true
				emit_signal("level_unlocked", next_level)

func set_last_entry_portal(portal_target_level: int):
	last_entry_portal = portal_target_level

func get_last_entry_portal() -> int:
	return last_entry_portal

func reset_progress():
	for level in range(0, TOTAL_LEVELS + 1):
		unlocked_levels[level] = false
		completed_puzzles[level] = 0
		total_puzzles_per_level[level] = 0
	unlocked_levels[0] = true
	unlocked_levels[1] = true
