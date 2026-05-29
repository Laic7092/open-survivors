extends RefCounted
# Centralized collision layer constants.
# Every entity that sets collision_layer / collision_mask must use these.

# Layer values (set on collision_layer)
const PLAYER := 2            # bit 1
const ENEMY := 4             # bit 2
const ENEMY_PROJECTILE := 8  # bit 3
const XP_GEM := 16           # bit 4
const PICKUP := 32           # bit 5

# Common mask combinations
const MASK_ENEMIES := ENEMY | ENEMY_PROJECTILE   # 4 | 8 = 12
const MASK_PLAYER := PLAYER                       # 2
