# Wiki Alignment Progress

> 基于 [Vampire Survivors Wiki](https://vampire.survivors.wiki/) 对齐武器系统
> 记录日期: 2026-05-31

## 架构概览

### 数据流

```
item_defs.gd (DATA + WIKI_DATA)
    ↓
weapon_state.gd (_BASE + _UPGRADES + _LIMIT_BREAKS)
    ↓                        ↓
weapon_manager.gd         weapon_behaviors/*.gd
(EVOLUTION_RECIPES,       (per-weapon fire logic)
 arcana hooks, LB API)
    ↓
level_up_screen.gd
(choices, evolution, LB UI)
```

### 核心数据结构

| 数据 | 位置 | 说明 |
|------|------|------|
| `DATA` | `item_defs.gd` | 显示名、描述、颜色、进化键、最大等级 |
| `WIKI_DATA` | `item_defs.gd` | 参考元数据：击退、穿透、暴击倍率、几率、稀有度 |
| `_BASE` | `weapon_state.gd` | 基础属性：冷却、伤害、区域、速度、弹射物数量、穿透 |
| `_UPGRADES` | `weapon_state.gd` | 逐级升级数组（索引 0 = Lv2 奖励） |
| `_LIMIT_BREAKS` | `weapon_state.gd` | 限界突破选项：属性、数值、稀有度权重、上限 |
| `EVOLUTION_RECIPES` | `weapon_manager.gd` | 进化配方：所需被动/武器 + 等级 |

### _apply_level_data() 所支持的键

| 键 | 效果 |
|-----|--------|
| `dmg` | 增加固定伤害 |
| `area_pct` | 增加基础区域的 X%（以像素为单位） |
| `amt` | 增加弹射物数量 |
| `pierce` | 增加穿透次数 |
| `speed` | 增加固定速度 |
| `speed_pct` | 增加基础速度的 X% |
| `duration_pct` | 🔲 已解析，尚未实现（持续时间为全局属性） |
| `cd` | 固定秒数的冷却缩减 |
| `cd_pct` / `cooldown_pct` | 百分比冷却缩减 |

### WeaponState 字段

```gdscript
var type: int
var level: int
var max_level: int
var cooldown: float
var cooldown_timer: float
var damage: float
var area: float
var speed: float
var amount: int = 1
var pierce: int = 1
var evolved: bool = false
var limit_break_level: int = 0
var limit_break_bonuses: Dictionary = {}
var custom_state: Dictionary = {}
```

---

## 武器对齐状态

### 已完成（10 / 41 种武器）

| 武器 | 等级 | 升级表 | 限界突破 | 行为 | 描述/翻译 |
|--------|-------|---------|-----------|----------|----------------|
| 鞭子 | ✅ | ✅ | ✅ | ✅ 弧形命中框、击退、朝向 | ✅ |
| 魔法杖 | ✅ | ✅ | ✅ | ✅ 最近目标、顺序射击、穿透追踪 | ✅ |
| 小刀 | ✅ | ✅ | ✅ | ✅ 朝向、间隔递减、穿透追踪 | ✅ |
| 大蒜 | ✅ | ✅ | ✅ | ✅（已有光环逻辑） | ✅ |
| 斧头 | ✅ | ✅ | ✅ | ✅ 新增：穿透追踪、自定义回调 | ✅ |
| 火杖 | ✅ | ✅ | ✅ | ✅ 重写：弧形、穿透追踪、接触爆炸 | ✅ |
| 十字架 | ✅ | ✅ | ✅ | ✅（已有回旋镖逻辑） | ✅ |
| 圣经 | ✅ | ✅ | ✅ | ✅（已有轨道逻辑） | ✅ |
| 圣水 | ✅ | ✅ | ✅ | ✅（已有水洼逻辑） | ✅ |
| 符文追踪器 | ✅ | ✅ | ✅ | ✅（已有弹射逻辑） | ✅ |

### 待处理（31 / 41 种武器）

| 武器 | wiki | 等级 | 升级表 | 限界突破 | 行为 | 注释 |
|--------|------|-------|---------|-----------|----------|--------|
| 闪电戒指 | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| 五芒星 | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| 桃子 | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| 黑檀之翼 | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Phiera | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Eight | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Gatti Amari | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Song of Mana | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Shadow Pinion | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Clock Lancet | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Laurel | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Vento Sacro | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| 骨头 | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| 樱桃炸弹 | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Carréllo | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Celestial Dusting | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| La Robba | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Greatest Jubilee | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| 手镯 | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Candybox | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| 胜利之剑 | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Flames of Misspell | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Pako Battiliar | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Ammo Appalate | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| 混沌符文 | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Glass Fandango | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Santa Javelin | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| 盖亚凝视 | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| 魔法石 | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Phas3r | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |
| Arma Dio | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 | |

---

## 已完成行为清单

### 已完成武器的关键模式

| 模式 | 武器 | 实现 |
|--------|---------|------------|
| **穿透追踪** | 魔法杖、小刀、斧头、火杖 | 每个弹射物上的 `pierce_remaining` 元数据 + 自定义命中回调 |
| **顺序射击** | 魔法杖（0.06 秒错开）、小刀（0.05-0.01 秒错开） | 弹射物生成循环中的 `create_timer()` |
| **面朝方向** | 鞭子、小刀 | `player.direction` 用于射击方向 |
| **弧线射击** | 鞭子、火杖 | 面朝方向的角扇形（鞭子）、弧形散射（火杖） |
| **朝向最近目标** | 魔法杖 | 按距离排序，选取最近目标 |
| **击退** | 鞭子 | `DataRegistry.items().wiki_knockback()` * 120 |
| **反弹** | 符文追踪器 | 已通过 `runetracer_updater.gd` 实现 |
| **水洼** | 圣水 | 已通过 `santa_water.gd` 实现 |
| **轨道** | 圣经、桃子、黑檀之翼 | 已通过 `weapon_manager._update_bird_orbits()` 实现 |
| **回旋镖** | 十字架 | 已通过 `cross.gd` 实现 |

### _apply_level_data() 所使用的特殊升级键

- **`"cd"`** (平减): 大蒜（Lv3/5/7 各 -0.1 秒）
- **`"pierce"`** (增加): 小刀（Lv5/8）、斧头（Lv4/7）
- **`"duration_pct"`** (已解析): 符文追踪器、圣水、圣经 — 🔲 尚不可操作

---

## 限界突破系统

### 数据模式

```gdscript
_LIMIT_BREAKS[weapon_type] = {
    "options": [
        {"stat": "might_pct",  "value": 0.5, "rarity": 10, "max_total": -1},
        {"stat": "area_pct",   "value": 2.5, "rarity": 10, "max_total": 1000.0},
        {"stat": "speed_pct",  "value": 5.0, "rarity": 10, "max_total": 300.0},
        {"stat": "amt",        "value": 1,   "rarity": 1,  "max_total": 20},
        {"stat": "pierce",     "value": 1,   "rarity": 5,  "max_total": 10},
        {"stat": "base_dmg",   "value": 0.5, "rarity": -1, "max_total": -1},
    ]
}
```

### 选择算法（`_weighted_pick`）

1. 分离保证选项（`rarity = -1`，始终包含）
2. 使用加权随机选择从加权池中选取，直至达到 `_LIMIT_BREAK_CHOICE_COUNT`（3）
3. 尊重 `max_total` 上限，排除已上限选项
4. 返回必选项 + 加权选项的混合

### UI 流程

```
武器满级 + 大福音书遗物
    → level_up_screen.gd 检测 w.can_limit_break()
    → 编码为 -100 - type
    → _add_limit_break_choice() 渲染卡片
    → 玩家选择 → apply_limit_break()
    → 更新 weapon_state + recalculate_stats()
```

---

## 已知限制

| 限制 | 说明 |
|-----------|-------------|
| 🔲 **持续时间追踪** | `duration_pct` 已在 `_apply_level_data()` 中解析但被跳过——持续时间目前是全局属性（`player.duration_bonus`），而非每武器属性 |
| 🔲 **限界突破 UI** | 加权选择工作正常，但 UI 缺少视觉重量指示器、平滑动画和完整的“稀有”样式 |
| 🔲 **移动输入限界突破数据** | 当前设定为合理默认值——需要对照 wiki 逐一验证各武器 |
| 🔲 **被动限界突破** | 限界突破系统目前仅适用于武器；被动物品没有限界突破 |
| 🔲 **秘术集成** | 秘术 API 钩子已存在，但需要逐步接入各武器行为脚本 |

---

## 对齐工作流

对齐武器时：

1. 从 `https://vampire.survivors.wiki/w/WeaponName` 获取 wiki 数据
2. 收集基础属性、升级表、限界突破选项、效果、描述
3. 更新 `item_defs.gd` 中的 `max_level` 和 `desc`
4. 更新 `weapon_state.gd` 中的 `_BASE`（`cd`, `dmg`, `amt`, `pierce`）
5. 更新 `weapon_state.gd` 中的 `_UPGRADES`（逐级数组）
6. 更新 `weapon_state.gd` 中的 `_LIMIT_BREAKS`
7. 根据需要重写 `weapon_behaviors/weapon.gd`：
   - 新增 `pierce` 追踪（如尚未实现）
   - 匹配 wiki 效果描述
   - 必要时添加 `custom_state` 使用
8. 更新 `i18n/en.gd` 和 `i18n/zh.gd` 中的描述文本
