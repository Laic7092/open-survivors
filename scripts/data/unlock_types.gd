extends RefCounted
# Unlock type enums — tiny file, safe to preload anywhere.
# The bulk data dictionary lives in unlock_defs.gd (loaded lazily via DataRegistry).

enum UnlockableType { STAGE, ARCANA, CHARACTER }
enum ConditionType { STAGE_CLEARED, PLAYER_LEVEL, RELIC_OWNED }
