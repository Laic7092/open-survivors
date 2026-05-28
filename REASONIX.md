# Desire Survivors — Working Knowledge

## Stack

- **Godot 4.6** — engine; GDScript language.
- **2D action game** — Vampire Survivors-like arena survival.
- **Procedural audio** — all SFX/BGM generated via `_mk_tone`, `_mk_noise`, `_mk_sweep`, `_mk_arpeggio`, `_mk_bgm_loop` in `audio_manager.gd`. No audio asset files.
- **Autoload singletons** — `AudioManager` (`scripts/audio_manager.gd`), `PowerUpManager` (`scripts/powerup_manager.gd`). Both use `process_mode = PROCESS_MODE_WHEN_PAUSED`.
- **Persistence** — `user://desire_survivors_save.json` via `FileAccess` (JSON). Managed by `PowerUpManager`.

## Layout

| Path | Contents |
|------|----------|
| `scripts/` | All `.gd` source files — player, enemies, HUD, UI screens, managers |
| `scenes/` | All `.tscn` scene files — match script names (e.g. `player.tscn` → `player.gd`) |
| `project.godot` | Engine config: resolution (1280×720), input bindings (WASD + arrows), autoloads, stretch mode `canvas_items` |
| `icon.svg` | Default Godot project icon |
| `.godot/` | Editor-local cache / metadata — not committed |

## Commands

No build / test / lint / format scripts — the project runs from the Godot Editor (press **F5**). No CI or test framework detected.

## Conventions

- **`extends <NodeType>`** in every script; `class_name` for cross-referenced types (e.g. `class_name Player` in `player.gd`).
- **Enum `UpgradeType`** in `player.gd` — weapon types (0–12) + passive upgrade IDs.
- **Signals** for cross-object communication (`died`, `leveled_up`, `upgrade_selected`, `toggle_pause`).
- **`_`-prefixed methods** for private/implementation use: `_fire_*` per weapon, `_spawn_*`, `_recalculate_passives`.
- **All UI built in code** (Button, Label, ColorRect) via `_draw()` / `add_child()` — no UI scene files. HUD redraws every frame via `queue_redraw()`.
- **`res://` path references** for preloading scenes: `preload("res://scenes/player.tscn")`.
- **Collision layers**: player=2, enemies=4, hurtbox masks=4 (enemy bodies), collect_area masks=16 (XP gem areas).
- **Format**: `key=` style in `project.godot`; `snake_case` in GDScript identifiers.

## Watch out for

- **Autoloads are required at tree load.** Adding a new autoload = edit both `scripts/*.gd` and the `[autoload]` section in `project.godot`.
- **HUD not a scene.** `hud.gd` extends `Control` and draws everything in `_draw()` — no `hud.tscn`. Changes to layout must modify drawing code.
- **Audio is code-only.** New SFX need a `_mk_*` call in `audio_manager.gd` `_generate_sounds()`. No `.ogg`/`.wav` files.
- **Collision layers are magic numbers** — layer/mask ints are hardcoded per script. Adding a new collision group requires cross-referencing `collision_layer` / `collision_mask` in `player.gd`, `enemy.gd`, and any pickup/gem scripts.
- **Save format is fragile.** `PowerUpManager` writes `user://desire_survivors_save.json`. Adding or renaming keys in the `POWERUPS` dict will silently break old saves (keys missing in loaded data get default 0).
- **`process_mode = PROCESS_MODE_WHEN_PAUSED`** on both managers — they keep running while the game is paused (level-up screen, pause overlay). New autoloads probably need the same flag.
