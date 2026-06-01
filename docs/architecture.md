# OpenSurvivors Architecture

## Overview

OpenSurvivors — a Vampire Survivors-like roguelite built with Godot 4.6 (GDScript). The architecture follows a strict **six-layer unidirectional dependency** model, where each layer only depends on layers below it.

```
L0  data/      纯数据定义, 零外部依赖
L1  registry/  数据懒加载接入层
L2  systems/   纯逻辑系统 (不直接操作场景树)
L3  managers/  全局服务 (autoload 单例)
L4  entities/  游戏实体 (CharacterBody2D / Node2D)
L5  core/      生命周期编排 (main.gd + 流程控制)
L6  ui/        界面展示 (纯视觉, 无游戏逻辑)
```

```
依赖方向 (严格单向):
  L0 → L1 → L2 → L5 → L6
                ↗
       L3 ──────
       L4 ──────
```

---

## Layer 0: Data Layer

**Location:** `scripts/data/`

**Rule:** Pure data only. No `preload` of any Node type. No calls to autoloads (I18N, AudioManager, etc.). No scene tree access. No `extends Node`.

```
scripts/data/
├── item_types.gd           Enum: weapon/passive type IDs
├── unlock_types.gd         Enum: unlock condition types
├── collision_layers.gd     Collision layer bitmask constants
├── item_defs.gd            Weapon + passive item metadata (name, desc, color, stats)
├── enemy_defs.gd           Enemy type definitions (hp, speed, damage, shape, behavior)
├── arcana_defs.gd          Arcana card effects and metadata
├── relic_defs.gd           Relic definitions
├── character_defs.gd       Character stats and starting equipment
├── stage_defs.gd           Stage metadata registry (loads stage_{id}.gd lazily)
├── unlock_defs.gd          Unlock condition table (NO I18N; descriptions in UI layer)
├── powerup_formulas.gd     PowerUp level → stat bonus mapping formulas
├── passive_formulas.gd     Passive item type → stat effect formulas
├── evolutions.gd           Weapon evolution recipes (from weapon_manager)
├── weapon_manifest.gd       Weapon behavior registration table
├── i18n/                   Translation string maps
└── stages/
    └── stage_{id}.gd       Per-stage data dictionaries
```

**Key constraints:**
- No `I18N.t()` calls — use `name_key` / `desc_key` strings, translate in UI layer
- No preload of autoload scripts
- Use `static func` for accessors, not `class_name` (keeps files self-contained)

---

## Layer 1: Registry Layer

**Location:** `scripts/registry/`

**Rule:** Lazy-load data files on first access. Caches once loaded. Only depends on `data/`.

```
scripts/registry/
├── data_registry.gd        Autoload. Unified entry point for all data.
│    .items() → item_defs.gd
│    .enemies() → enemy_defs.gd
│    .arcanas() → arcana_defs.gd
│    .relics() → relic_defs.gd
│    .characters() → character_defs.gd
│    .stages() → stage_defs.gd
│    .unlocks() → unlock_defs.gd
│
└── enemy_pool_resolver.gd  Resolves string enemy names to type IDs
     (extracted from enemy_defs.gd to break the data↔data coupling)
```

**Why separate from data:**
- `data_registry` is an autoload Node (needs engine registration)
- `data/` files are plain `extends RefCounted` (pure data objects)
- Lazy loading keeps startup time fast

---

## Layer 2: System Layer

**Location:** `scripts/systems/`

**Rule:** Pure logic. No direct scene tree operations. Do NOT extend Node. Do NOT call `add_child`, `queue_free`, `get_tree`. Take inputs, return outputs. May call autoloads for read-only queries.

```
scripts/systems/
├── stat_pipeline.gd        NEW — Pure function stat calculator
│
│   Input:
│     - base values (class defaults)
│     - character stats
│     - powerup levels
│     - passive items dict {type: level}
│     - active arcana list
│
│   Output:
│     { might, area_mult, speed_mult, duration_mult, cooldown_mult,
│       growth_mult, luck, greed_mult, curse, recovery, armor,
│       move_speed, max_health, projectile_bonus, revivals, ... }
│
│   Processing order:
│     L0: reset to baseline → L1: character bonuses
│     → L2: powerup bonuses → L3: passive item formulas
│     → L4: arcana multipliers
│
│   Replaces:
│     player.recalculate_stats()  (computation part)
│     passive_inventory.recalculate()
│     PowerUpManager.get_stat_bonuses()
│     ArcanaManager.apply_stat_modifiers()
│
├── unlock_evaluator.gd     NEW — Pure condition checker
│   .evaluate(condition, run_state, persistent_state) → bool
│   .check_all(defs, state) → [unlocked_ids]
│
│   Replaces:
│     UnlockManager._conditions_met()
│     UnlockManager._condition_met()
│
├── arcana_runtime.gd       NEW — Arcana runtime effects
│   .process_time_effects(delta, active_list, player, game_time)
│   .on_level_up(active_list, player, new_level)
│   .attract_items(player)
│
│   Replaces:
│     ArcanaManager.process_time_effects()
│     ArcanaManager.on_player_level_up()
│
├── wave_system.gd          Existing — Wave-based enemy spawning
├── curse_system.gd         Existing — Cursed time after boss kills
└── level_up_service.gd     Existing — XP formulas, choice generation
```

**Design principle:** Systems are functions, not objects. They hold no state — state lives in `GameState`, `Player`, or `Managers`.

---

## Layer 3: Manager Layer

**Location:** `scripts/managers/`

**Rule:** Autoload singletons. Provide global services. Persistence delegated to `SaveManager`. Keep focused — one responsibility per manager.

```
scripts/managers/
├── save_manager.gd         Save/Load to disk (encrypted)
├── audio_manager.gd        BGM + SFX playback
├── scene_manager.gd        Scene transitions with loading screen
├── i18n.gd                 Translation: .t("key") → string
├── object_pool_manager.gd  Object pooling for gems, floating text, projectiles
├── enemy_registry.gd       Enemy type ID ↔ name registry
│
├── powerup_manager.gd      Meta-progression
│   ▸ gold / run_gold tracking
│   ▸ powerup level tracking
│   ▸ stage/character/hyper unlock bits
│   ▸ reroll/skip/banish per-run tracking
│   ✗ ~~get_stat_bonuses()~~ → StatPipeline
│
├── arcana_manager.gd       Arcana unlock + activation state
│   ▸ unlocked set
│   ▸ active list
│   ▸ query API (has_effect, active_arcanas_have_weapon_effect)
│   ✗ ~~apply_stat_modifiers()~~ → StatPipeline
│   ✗ ~~process_time_effects()~~ → ArcanaRuntime
│   ✗ ~~on_player_level_up()~~ → ArcanaRuntime
│
├── unlock_manager.gd       Unlock persistence + query + notification
│   ▸ completed set
│   ▸ run data tracking
│   ▸ persistent stat tracking
│   ▸ is_unlocked() query API
│   ▸ newly-unlocked notification tracking
│   ▸ save/load from SaveManager
│   ✗ ~~_conditions_met()~~ → UnlockEvaluator
│
├── relic_manager.gd        Relic collection + feature unlock queries
└── ...existing managers kept as-is
```

**Manager lifetime:**
- All created at game boot via `project.godot` `[autoload]`
- `_ready()` loads persisted state from `SaveManager`
- `process_mode = PROCESS_MODE_WHEN_PAUSED` (work during menus)

---

## Layer 4: Entity Layer

**Location:** `scripts/entities/`

**Rule:** Node-based game objects. Own their own state. No global orchestration logic. May query autoload managers but must not manage them.

```
scripts/entities/
├── player.gd              CharacterBody2D (class_name Player)
│   ▸ movement (wasd input)
│   ▸ health / XP / level
│   ▸ visual rendering (_draw)
│   ▸ owns: weapon_manager, passive_inventory
│
│   .recalculate_stats() → simplified:
│     var s = StatPipeline.calc(base, char, pu, passives, arcanas)
│     _apply_stats(s)  # pure assignment
│
├── weapon_manager.gd      Weapon logic orchestrator
│   ▸ weapons[]
│   ▸ process(delta) — cooldown, fire
│   ▸ add_or_upgrade / evolve / limit_break
│   ▸ fire_weapon(w) → delegates to behavior scripts
│   ▸ behavior registry (load from data/weapon_manifest.gd)
│   ✗ ~~EVOLUTION_RECIPES~~ → data/evolutions.gd
│   ✗ ~~hardcoded EnemyManager path~~ → injected reference
│
├── weapon_state.gd        Per-weapon state (type, level, cooldown, evo, amount)
│   ▸ no preload of item_defs — use DataRegistry
│
├── passive_inventory.gd   Passive item storage
│   ▸ { type: level } dict
│   ▸ add_or_upgrade / remove / get_level
│   ✗ ~~recalculate(player)~~ → StatPipeline
│
├── enemy_manager.gd       ECS-style batch enemy system (1034 lines, keep)
│   ▸ parallel arrays (Packed*Array) per entity
│   ▸ MultiMeshInstance2D batch rendering
│   ▸ EnemyProxy thin wrapper for weapon compatibility
│
├── enemy_proxy.gd         RefCounted — delegates .global_position, .take_damage
│
├── weapon_behaviors/      41x static func scripts (keep, with constraints)
│   ▸ signature: fire(w, weapon_manager, player, get_enemies)
│   ▸ ✗ NO direct access to player._private_members
│   ▸ ✗ NO queue_free() — use ObjectPoolManager
│   ▸ ✗ NO hardcoded AudioManager — use injected context
│
├── pickup.gd, xp_gem.gd, prop.gd, ... (existing)
└── ...
```

**Entity patterns used:**
- **Player**: traditional CharacterBody2D with signals
- **Enemies**: ECS batch array (performance critical — 500+ simultaneous enemies)
- **Projectiles**: lightweight Node2D created via ObjectPoolManager
- **Props**: managed by PropManager

---

## Layer 5: Core Layer

**Location:** `scripts/core/`

**Rule:** Game lifecycle orchestrator. Creates subsystems, wires dependencies, drives `_process`. Minimal logic — delegates to layers below.

```
scripts/core/
├── main.gd                 Main game loop (~250 lines, slimmed)
│
│   _ready():
│     ▸ create GameState
│     ▸ create Player, CameraController
│     ▸ create SpawnManager, WaveSystem, CurseSystem
│     ▸ create StageGenerator
│     ▸ create UI (HUD, level up screen)
│     ▸ wire signals
│     ▸ call StageGenerator.generate()
│
│   _process(delta):
│     ▸ GameState.game_time += delta
│     ▸ GameState.update_difficulty(delta)
│     ▸ GameFlow.update(delta)
│     ▸ wave_system.process(delta)
│     ▸ curse_system.process(delta)
│     ▸ camera.process(delta)
│     ▸ spawn_manager.process_delayed()
│     ▸ arcana_runtime.process_time_effects(delta)
│     ▸ pickup_timer.process(delta)
│     ▸ ui_bridge.sync()
│
├── game_flow.gd            NEW — Game flow state machine
│   ▸ states: PLAYING | LEVEL_UP | ARCANA_CHOICE | PAUSED | GAME_OVER | COMPLETE
│   ▸ handles: level-up menu show/hide, game over sequence, stage complete
│   ▸ Extracted from main.gd._on_player_leveled_up, _on_player_died, etc.
│
├── input_handler.gd        NEW — Input dispatch
│   ▸ ESC → toggle pause
│   ▸ F11 → toggle fullscreen
│   ▸ 1-4 → set game speed
│   ▸ E → interact with props
│   ▸ Extracted from main.gd._unhandled_input
│
├── run_config.gd           NEW — Strongly-typed config (replaces EventBus KV store)
│   ▸ selected_stage: Dictionary
│   ▸ selected_character: Dictionary
│   ▸ hurry_mode: bool
│   ▸ hyper_mode: bool
│   ▸ endless_mode: bool
│   ▸ arcana_enabled: bool
│   ▸ random_events: bool
│   ▸ inverse_mode: bool
│   ▸ alt_music: bool
│
├── game_state.gd           Runtime state container (keep, slim)
│   ▸ game_time / total_kills / difficulty
│   ▸ wave_* / curse_* / boss_* state
│   ▸ map metrics
│   ▸ set_stage_data(data) — import stage config
│
├── event_bus.gd            Signal hub ONLY (remove KV store)
│   ▸ signals: stage_started, game_over, player_leveled_up, enemy_killed, ...
│   ✗ ~~set_config/get_config/clear_config~~ → RunConfig
│
├── spawn_manager.gd        Unified spawning (keep)
│   ▸ spawn_enemy / spawn_boss / spawn_pickup
│   ▸ spawn_stage_relics / spawn_stage_items
│   ▸ enemy death drops
│
├── stage_generator.gd      Map generation (keep)
│   ▸ background / decor / props / boundary walls
│   ▸ interactables: chests, fountains, hazards, boosts
│
├── camera_controller.gd    Camera follow + shake (keep)
│
├── ui_bridge.gd            NEW — Signal relay: main ↔ HUD
│   ▸ connects player/game_state signals to HUD methods
│   ▸ reduces main.gd forwarding boilerplate
│
└── pickup_timer.gd         Timed pickup spawning (keep)
```

**Autoloads assigned to core layer:**
- `EventBus` — signal hub (autoload, cross-module)
- `DataRegistry` — data access (autoload, lazy)

---

## Layer 6: UI Layer

**Location:** `scripts/ui/`

**Rule:** Visual presentation only. No game logic. No direct calls to entities or systems. Communicate via `EventBus` signals.

```
scripts/ui/
├── main_menu.gd            Title screen
├── character_select.gd     Character selection
├── stage_select.gd         Stage selection
├── hud.gd                  In-game HUD (timer, health, weapons, passives, minimap)
├── level_up_screen.gd      Level-up choice UI
├── arcana_choice_screen.gd Arcana picker
├── pause_overlay.gd        Pause menu
├── collection_screen.gd    Collection viewer
├── powerup_screen.gd       PowerUp shop
├── relic_screen.gd         Relic viewer
├── save_screen.gd          Save/load UI
├── debug_weapon_select.gd  Debug weapon picker
├── unlock_notification.gd  New unlock toast
├── item_acquired_notification.gd Item pickup toast
│
├── unlock_descriptions.gd  NEW — I18N string formatting for unlock conditions
│   (moved from data/unlock_defs.gd UnlockCondition.description())
│
├── ui_bridge.gd            Signal relay (shared with core/)
│
├── ui_utils.gd             UI helper functions
├── icon_generator.gd       Procedural icon rendering
└── theme/                  UI theme resources
```

---

## Data Flow: One Game Run

```
1. MainMenu → select stage + character + modes
2. SceneManager.change_scene("main.tscn")
       │
3. main.gd._ready()
       │
       ├── RunConfig holds selection
       ├── GameState.set_stage_data(RunConfig.selected_stage)
       ├── Player._ready()
       │     └── StatPipeline.calc(base, character, powerups)
       ├── StageGenerator.generate()
       └── wave_system starts
       │
4. _process(delta)  [~60fps]
       │
       ├── game_flow.update(delta)
       ├── GameState.game_time += delta
       ├── GameState.update_difficulty(delta)
       ├── wave_system.process(delta)
       ├── curse_system.process(delta)
       ├── player._process(delta)
       │     ├── weapon_manager.process(delta)
       │     │     └── fire() → weapon_behavior { creates projectiles }
       │     └── recalculate_stats() on upgrade
       │           └── StatPipeline.calc(...)
       ├── enemy_manager.process(delta)
       │     └── collision / movement / MultiMesh render
       ├── camera.process(delta)
       ├── arcana_runtime.process_time_effects(delta)
       ├── spawn_manager.process_delayed_spawns()
       └── ui_bridge.sync()
             └── HUD updates
       │
5. Game over / Stage complete
       │
       ├── GameState.set_game_over()
       ├── GameFlow shows results
       ├── PowerUpManager.end_run()
       ├── UnlockEvaluator.check_all(run_data) → new unlocks
       └── SceneManager.change_scene("menu")
```

---

## EventBus Signals

All cross-module communication via EventBus signals. No direct node references between layers.

```
Game Events:
  stage_started(stage_data)
  stage_completed(stage_id, time)
  game_over(kills, level, time)
  player_leveled_up(level)
  enemy_killed(enemy_type, position, is_boss)
  boss_spawned(boss_type)
  curse_level_changed(level)
  relic_collected(relic_id)
  arcana_activated(arcana_id)

Unlock Events:
  weapon_upgraded(weapon_type, level)
  item_evolved(weapon_type)
  light_source_destroyed()
  pickup_collected(pickup_type)
  stage_item_collected(item_type)
  gold_collected(amount)
```

---

## Weapon Behavior Contract

All 41 weapon behaviors in `scripts/entities/weapon_behaviors/` follow:

```gdscript
# Signature (unchanged):
static func fire(w: WeaponState, weapon_manager: WeaponManager,
                 player: Player, get_enemies: Callable) -> void

# Rules:
#   ✓ Use weapon_manager shared helpers for hit detection
#   ✓ Use ObjectPoolManager.spawn() instead of queue_free()
#   ✓ Read player stats via public methods, not private vars
#   ✓ Pass context struct instead of accessing private fields
#
#   ✗ Do NOT access: player._crit_chance, player._crit_mult
#   ✗ Do NOT call: player.get_node("..."), queue_free()
```

---

## Stat Pipeline Detail

```gdscript
# systems/stat_pipeline.gd
# Pure function — no side effects, no scene access

static func calc(
    base: Dictionary,
    character: Dictionary,
    powerup_levels: Dictionary,
    passives: Dictionary,       # { type: level }
    active_arcanas: Array       # [arcana_id, ...]
) -> Dictionary:
    # Phase 0: Baseline
    var s = _baseline()

    # Phase 1: Character bonuses
    _apply_character(s, character)

    # Phase 2: PowerUp bonuses (using powerup_formulas.gd)
    _apply_powerups(s, powerup_levels)

    # Phase 3: Passive item formulas (using passive_formulas.gd)
    _apply_passives(s, passives)

    # Phase 4: Arcana multipliers
    _apply_arcanas(s, active_arcanas)

    return s
```

**Usage in player.gd:**

```gdscript
func recalculate_stats():
    var s = StatPipeline.calc(
        _get_base_stats(),
        EventBus.get_config("selected_character", {}),
        PowerUpManager.levels,
        passive_inventory.get_all(),
        ArcanaManager.get_active()
    )
    _apply_snapshot(s)
    _clamp_health()
    health_changed.emit(health, max_health)

func _apply_snapshot(s: Dictionary):
    might = s.might
    area_mult = s.area_mult
    speed_mult = s.speed_mult
    duration_mult = s.duration_mult
    cooldown_mult = s.cooldown_mult
    growth_mult = s.growth_mult
    luck = s.luck
    greed_mult = s.greed_mult
    curse = s.curse
    recovery = s.recovery
    armor = s.armor
    max_health = s.max_health
    move_speed = s.move_speed
    projectile_bonus = s.projectile_bonus
    revivals = s.revivals
    pickup_range = s.pickup_range
    charm = s.charm
    _crit_chance = s.crit_chance
```

---

## Configuration: RunConfig vs EventBus

| Before | After |
|--------|-------|
| `EventBus.set_config("hurry_mode", true)` | `RunConfig.hurry_mode = true` |
| `EventBus.get_config("selected_stage", {})` | `RunConfig.selected_stage` |
| `EventBus.set_stage_config(data)` | `RunConfig.selected_stage = data; EventBus.stage_started.emit(data)` |
| No type safety | All fields typed in RunConfig script |

**Keep in EventBus:** Signals only. The KV store is removed.

---

## Migration Steps

### Phase 1: Data purity (no behavioral changes)
1. Remove `I18N.t()` from `data/unlock_defs.gd` → `ui/unlock_descriptions.gd`
2. Remove `I18N.t()` from `data/character_defs.gd` — return key instead
3. Move `EVOLUTION_RECIPES` from `weapon_manager.gd` → `data/evolutions.gd`
4. Remove direct `preload item_defs` from `weapon_state.gd` — use DataRegistry
5. Create `data/weapon_manifest.gd` — weapon behavior registration

### Phase 2: Stat Pipeline (behind a flag)
1. Implement `systems/stat_pipeline.gd` alongside existing code
2. Compare outputs — verify bit-exact match
3. Flip player to use StatPipeline
4. Remove `passive_inventory.recalculate()`, `PowerUpManager.get_stat_bonuses()`

### Phase 3: Split God Objects
1. Extract `core/game_flow.gd` from `main.gd`
2. Extract `core/input_handler.gd` from `main.gd`
3. Extract `core/ui_bridge.gd` from `main.gd`
4. Create `core/run_config.gd`, migrate EventBus KV usage
5. Create `systems/unlock_evaluator.gd`, strip UnlockManager
6. Create `systems/arcana_runtime.gd`, strip ArcanaManager

### Phase 4: Weapon behavior hardening
1. Enforce no-`_private`-member access in behavior scripts
2. Switch to ObjectPoolManager for projectile lifecycle
3. Remove hardcoded scene path in `weapon_manager.gd`

### Phase 5: Registry cleanup
1. Move `enemy_defs.gd`'s `preload stage_defs` → `registry/enemy_pool_resolver.gd`
2. Verify no circular loads
