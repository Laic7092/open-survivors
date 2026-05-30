# Desire Survivors — 项目说明

## 项目概述
Vampire Survivors 同人游戏，使用 Godot 4.6 制作。
项目目标：实现完整的 base game 内容（武器、被动、PowerUp、秘术、遗物、角色、关卡）。

## 技术栈
- **引擎**: Godot 4.6.2 (GDScript)
- **渲染**: 2D (CanvasItems)
- **构建工具**: 无（原生 Godot 项目）

## 项目结构
```
desire/
├── assets/              # 资源文件 (字体等)
├── export/              # 导出配置
├── scenes/              # 场景文件 (.tscn)
│   ├── main_menu.tscn   # 主菜单
│   ├── main.tscn        # 游戏主场景（运行时）
│   ├── character_select.tscn
│   ├── stage_select.tscn
│   ├── powerup_screen.tscn
│   ├── player.tscn
│   ├── enemy.tscn
│   └── ...
├── scripts/
│   ├── core/            # 核心系统
│   │   ├── game_state.gd        # 运行时状态管理
│   │   ├── event_bus.gd         # 事件总线
│   │   ├── curse_system.gd      # 诅咒系统
│   │   ├── stage_generator.gd   # 关卡生成
│   │   └── wave_system.gd       # 波次系统
│   ├── data/            # 数据定义（单⼀事实来源）
│   │   ├── item_defs.gd         # 武器 + 被动物品定义
│   │   ├── character_defs.gd    # 角色定义
│   │   ├── stage_defs.gd        # 关卡注册器
│   │   ├── arcana_defs.gd       # 22 张秘术定义
│   │   ├── relic_defs.gd        # 遗物定义
│   │   ├── unlock_defs.gd       # 解锁条件定义
│   │   ├── enemy_defs.gd        # 敌人数值定义
│   │   └── stages/             # 各关卡数据 (stage_0.gd ~ stage_15.gd)
│   ├── entities/         # 实体脚本
│   │   ├── player.gd            # 玩家
│   │   ├── enemy.gd             # 敌人
│   │   ├── weapon_manager.gd    # 武器管理器
│   │   ├── passive_inventory.gd # 被动物品背包
│   │   ├── projectile_mover.gd  # 弹射物移动
│   │   └── ...
│   ├── managers/         # 单例管理器 (autoload)
│   │   ├── powerup_manager.gd   # PowerUp + 金币 + 解锁
│   │   ├── save_manager.gd      # 存档
│   │   ├── audio_manager.gd     # 音效
│   │   ├── i18n.gd              # 国际化 (中/英)
│   │   ├── scene_manager.gd     # 场景切换
│   │   ├── relic_manager.gd     # 遗物状态
│   │   ├── arcana_manager.gd    # 秘术系统
│   │   ├── enemy_registry.gd    # 敌⼈注册
│   │   └── object_pool_manager.gd # 对象池
│   ├── map/             # 地图系统
│   ├── ui/              # UI 界面
│   │   ├── main_menu.gd
│   │   ├── main.gd              # 游戏主循环
│   │   ├── hud.gd               # 抬头显示
│   │   ├── pause_overlay.gd     # 暂停界面
│   │   ├── level_up_screen.gd   # 升级选择
│   │   ├── powerup_screen.gd    # PowerUp 购买
│   │   └── ...
│   └── test/            # 单元测试
│       ├── test_runner.gd       # 测试运行器
│       └── test_*.gd            # 各模块测试
└── project.godot
```

## 核心约定

### 数据定义
- 所有物品/角色/关卡数据集中在 `scripts/data/` 目录
- `item_defs.gd` 是武器和被动物品的唯一数据源
- 枚举值 `Player.UpgradeType` 与 `ItemDefs.Type` 保持同步
- 新物品必须同时在 `item_defs.gd`、`player.gd`（apply_upgrade）、`weapon_manager.gd`（如果需要进化）注册

### PowerUp 系统
- `powerup_manager.gd` 管理永久升级（PowerUp）和金
- 所有 27 个 base game PowerUp 已实现
- PowerUp 的 `get_stat_bonuses()` 返回各属性加成
- 成本公式：`base_cost * (1 + cur_lv)`

### 国际化 (i18n)
- `I18N` 是 autoload 单例，使用 `I18N.t("key", fallback)` 获取翻译
- 中英文双表在 `scripts/managers/i18n.gd` 中
- 新条目必须同时在 `_zh()` 和 `_en()` 中添加

### 关卡系统
- 16 个关卡（stage_0 ~ stage_15），数据在 `scripts/data/stages/`
- `stage_defs.gd` 通过 `load()` 按需加载
- 每个关卡数据包含：基础倍率、生成参数、场景道具、波次等

### 存档
- 3 个存档位，JSON 格式
- `save_manager.gd` 自动管理
- PowerUp、遗物、解锁状态跨存档共享（在 PowerUpManager 中维护）

## 修改指南

### 添加新武器
1. 在 `item_defs.gd` 的 `enum Type` 中添加枚举值
2. 在 `DATA` 字典中添加条目（包含 name/desc/color/evo_key/is_weapon/max_level）
3. 在 `WEAPON_TYPES` 数组中添加 ID
4. 在 `player.gd` 的 `UpgradeType` 枚举中添加
5. 在 `player.gd` 的 `apply_upgrade()` 的武器 match 分支中添加
6. 在 `character_defs.gd` 的 `get_weapon_name_key()` 中添加
7. 在 `pause_overlay.gd` 的静态 helper 函数中添加
8. 在 `icon_generator.gd` 的 `EMOJI` 和 `get_color()` 中添加
9. 在 `i18n.gd` 的中英文表中添加翻译
10. 如需要进化，在 `weapon_manager.gd` 的 `EVOLUTION_RECIPES` 中添加配方

### 添加新 PowerUp
1. 在 `powerup_manager.gd` 的 `POWERUPS` 字典中添加条目
2. 在 `get_stat_bonuses()` 中添加对应计算
3. 在 `i18n.gd` 中添加 `pu.xxx` 和 `pu.xxx_desc` 翻译

## 运行测试
```bash
godot --headless --script scripts/test/test_runner.gd
```
