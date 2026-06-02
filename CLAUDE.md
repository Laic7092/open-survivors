# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
godot --help # CLI Commands
```

## Architecture

OpenSurvivors — a Vampire Survivors-like roguelite built with Godot 4.6 (GDScript).

All game content is data-driven. RefCounted scripts under `scripts/data/` define items, enemies, stages, relics, arcanas, characters, and unlocks — adding content means adding data, not logic. Stage definitions are lazy-loaded from `scripts/data/stages/stage_{id}.gd`.

### Services (`scripts/services/`)

Autoloads (global singletons). `EventBus` — cross-module signal bus + runtime config key-value store. `SaveManager`, `PowerUpManager` (meta-progression), `I18N` (`.t()` for strings), `RelicManager`, `ArcanaManager`, `SceneManager`, `EnemyRegistry`, `ObjectPoolManager`, `AudioManager`, `DataRegistry`, `UnlockManager`, `LevelUpService`.

### Core (`scripts/core/`)

Game runtime systems (Nodes, children of Main). `main.gd` wires everything at scene start: creates `GameState`, `WaveSystem`, `CurseSystem`, `StageGenerator`, `CameraController`, feeds them player ref + spawn callbacks. `GameState` holds all runtime state (time, kills, difficulty, wave/curse state). `StageGenerator` builds the map. `EnemyManager` — data-driven enemy system (array-based batch processing).

### Entities (`scripts/entities/`)

Organized by type:
- `player/` — `player.gd` (CharacterBody2D) owns two RefCounted objects: `WeaponManager` and `PassiveInventory`. Weapons are `WeaponState` objects.
- `enemy/` — `enemy_proxy.gd`, `enemy_projectile.gd`
- `pickup/` — `pickup.gd`, `xp_gem.gd`, `relic_entity.gd`, `stage_item_pickup.gd`
- `fx/` — `floating_text.gd`, `emoji_node.gd`, `explosion_fx.gd`, `proj_vis.gd`
- `projectile/` — `projectile_mover.gd`, `fireball_node.gd`, `runetracer_updater.gd`
- `weapon_behaviors/` — 41 static weapon fire logic scripts

### Map (`scripts/map/`)

Scene elements: `prop.gd`, `breakable_wall.gd`, `healing_fountain.gd`, `treasure_chest.gd`, `hazard_zone.gd`, `boost_zone.gd`, `interactable.gd`.

### Key Patterns

- Use `EventBus` signals over direct node traversal. Use `EventBus.set_config/get_config` for runtime shared state.
- Level-up / arcana choice pause the game tree (`get_tree().paused = true`).
- Object pooling: return gems/floating text to `ObjectPoolManager`, never `queue_free()`.
- All user-facing text through `I18N.t("key")`.
