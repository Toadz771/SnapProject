extends Node

signal level_unlocked(level: int)
# Total levels in the game (excluding Level 0)
const TOTAL_LEVELS = 10

# Track which levels are unlocked (including Level 0)
var unlocked_levels = {}

# Track total puzzles per level (set dynamically by level scripts)
var total_puzzles_per_level = {}

# Track completed puzzles per level
var completed_puzzles = {}

# Add at the top of the script
var last_entry_portal: int = -1  # Tracks the target_level of the portal entered (-1 = none)

func _ready():
	# Initialize level data, including Level 0
	for level in range(0, TOTAL_LEVELS + 1):  # Start from 0
		unlocked_levels[level] = false
		completed_puzzles[level] = 0
		total_puzzles_per_level[level] = 0
	
	# Level 0 and Level 1 are unlocked by default
	unlocked_levels[0] = true
	unlocked_levels[1] = true

# Check if a level is unlocked
func is_level_unlocked(level: int) -> bool:
	if level < 0 or level > TOTAL_LEVELS:
		return false
	return unlocked_levels[level]

# Set the total number of puzzles for a level (called by level scripts)
func set_total_puzzles(level: int, total: int):
	if level < 0 or level > TOTAL_LEVELS:
		return
	total_puzzles_per_level[level] = total
	print("Level ", level, " has ", total, " puzzles")

# Called when a puzzle is solved in a level
func puzzle_solved(level: int):
	if level < 0 or level > TOTAL_LEVELS:
		return
	
	completed_puzzles[level] += 1
	print("Puzzle solved in Level ", level, ". Completed: ", completed_puzzles[level], "/", total_puzzles_per_level[level])
	
	# Only levels 1 and above unlock the next level
	if level >= 1:  # Exclude Level 0 from unlocking progression
		if total_puzzles_per_level[level] > 0 and completed_puzzles[level] >= total_puzzles_per_level[level]:
			# Unlock the next level if it exists
			var next_level = level + 1
			if next_level <= TOTAL_LEVELS:
				unlocked_levels[next_level] = true
				emit_signal("level_unlocked", next_level)
				print("Level ", next_level, " unlocked!")

func set_last_entry_portal(portal_target_level: int):
	last_entry_portal = portal_target_level
	print("Set last entry portal to Level ", portal_target_level)

func get_last_entry_portal() -> int:
	return last_entry_portal

# Reset progress (optional, for testing)
func reset_progress():
	for level in range(0, TOTAL_LEVELS + 1):  # Start from 0
		unlocked_levels[level] = false
		completed_puzzles[level] = 0
		total_puzzles_per_level[level] = 0
	unlocked_levels[0] = true
	unlocked_levels[1] = true
