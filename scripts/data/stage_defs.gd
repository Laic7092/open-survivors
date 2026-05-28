extends RefCounted
# Stage definitions — static data for the stage selection system.
# Each entry: id, name, desc, time_limit, bg_color,
# modifiers, spawn curve params, unlock condition.

const STAGES = [
	{
		"id": 0,
		"name": "Mad Forest",
		"desc": "A dark forest overrun by evil.\nSurvive until dawn.",
		"time_limit": 1800.0,  # 30 minutes
		"bg_color": Color(0.04, 0.04, 0.10),
		"map_width": 3200,
		"map_height": 2400,
		"move_speed_mod": 1.0,
		"enemy_speed_mod": 1.0,
		"spawn_base_interval": 2.0,
		"spawn_min_interval": 0.3,
		"spawn_ramp_time": 30.0,
		"wave_size_interval": 30.0,
		"difficulty_ramp_time": 60.0,
		"unlock_req": "",
	},
	{
		"id": 1,
		"name": "Inlaid Library",
		"desc": "Halls of forbidden knowledge.\n+25% Move Speed. Narrow corridor.",
		"time_limit": 1800.0,
		"bg_color": Color(0.08, 0.02, 0.12),
		"map_width": 1400,
		"map_height": 4800,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.15,
		"spawn_base_interval": 1.8,
		"spawn_min_interval": 0.25,
		"spawn_ramp_time": 25.0,
		"wave_size_interval": 25.0,
		"difficulty_ramp_time": 50.0,
		"unlock_req": "clear_stage_0",  # beat Mad Forest
	},
	{
		"id": 2,
		"name": "Il Molise",
		"desc": "Peaceful meadow hiding a secret.\n15 min limit. Enemies stay still.",
		"time_limit": 900.0,
		"bg_color": Color(0.06, 0.16, 0.04),
		"map_width": 4000,
		"map_height": 4000,
		"move_speed_mod": 1.0,
		"enemy_speed_mod": 0.0,  # stationary enemies
		"spawn_base_interval": 1.0,
		"spawn_min_interval": 0.12,
		"spawn_ramp_time": 18.0,
		"wave_size_interval": 20.0,
		"difficulty_ramp_time": 40.0,
		"unlock_req": "clear_stage_1",  # beat Inlaid Library
	},
]


static func get_stage(id: int) -> Dictionary:
	for s in STAGES:
		if s["id"] == id:
			return s
	return STAGES[0]


static func get_stage_count() -> int:
	return STAGES.size()
