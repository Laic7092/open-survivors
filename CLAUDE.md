# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
godot  # Run the game (editor window, or F5/F6 in editor)
```

## Architecture

OpenSurvivors — a Vampire Survivors-like roguelite built with Godot 4.6 (GDScript).

All game content is data-driven. RefCounted scripts under `scripts/data/` define items, enemies, stages, relics, arcanas, characters, and unlocks — adding content means adding data, not logic. Stage definitions are lazy-loaded from `scripts/data/stages/stage_{id}.gd`.

### Autoloads

`EventBus` — cross-module signal bus + runtime config key-value store. `SaveManager`, `PowerUpManager` (meta-progression), `I18N` (`.t()` for strings), `RelicManager`, `ArcanaManager`, `SceneManager`, `EnemyRegistry`, `ObjectPoolManager`, `AudioManager`.

### Core (`scripts/core/`)

`main.gd` wires everything at scene start: creates `GameState`, `WaveSystem`, `CurseSystem`, `StageGenerator`, `CameraController`, feeds them player ref + spawn callbacks. `GameState` holds all runtime state (time, kills, difficulty, wave/curse state). `StageGenerator` builds the map: background, themed props, boundary walls, interactables (chests, fountains, hazards, boosts, breakable walls).

### Entities (`scripts/entities/`)

`player.gd` (CharacterBody2D) owns two RefCounted objects: `WeaponManager` (processes all weapons per frame) and `PassiveInventory` (recalculates stats on upgrade). Weapons are `WeaponState` objects tracking type/level/cooldown/evolved. `enemy.gd` is data-driven: type determines stats, shape, behavior (chase/wavy/stationary), ranged attacks.

### Key Patterns

- Use `EventBus` signals over direct node traversal. Use `EventBus.set_config/get_config` for runtime shared state.
- Level-up / arcana choice pause the game tree (`get_tree().paused = true`).
- Object pooling: return gems/floating text to `ObjectPoolManager`, never `queue_free()`.
- All user-facing text through `I18N.t("key")`.
