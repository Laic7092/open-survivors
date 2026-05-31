extends RefCounted
# Unlock type enums — tiny file, safe to preload anywhere.
# The bulk data dictionary lives in unlock_defs.gd (loaded lazily via DataRegistry).

enum UnlockableType { STAGE, ARCANA, CHARACTER, ITEM }
enum ConditionType {
	STAGE_CLEARED,
	PLAYER_LEVEL,
	RELIC_OWNED,
	SURVIVE_CHAR_TIME,
	TOTAL_KILLS,
	WEAPON_AT_LEVEL,
	ITEM_FOUND,
	DESTROY_LIGHT_SOURCES,
	START_WITH_CHAR,
	ALL_EVOLUTIONS,
	RUN_KILLS,
	CHAR_LEVEL,
	HAVE_WEAPONS_COUNT,
	PICKUP_COLLECTED,
}
