#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
#  check_gdscript.sh — 全量 GDScript 验证
#
#  两步: 语法检查 → 集成测试
#  用 godot --headless 加载完整项目，autoload 和场景都可用。
#
#  环境变量: GODOT_BIN — Godot 路径
# ──────────────────────────────────────────────────────────────

set -u
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

find_godot() {
    [ -n "${GODOT_BIN:-}" ] && command -v "$GODOT_BIN" &>/dev/null && echo "$GODOT_BIN" && return
    for name in godot4 godot Godot; do
        command -v "$name" &>/dev/null && echo "$name" && return
    done
    for dir in \
        "$HOME/.steam/steam/steamapps/common/Godot/Godot" \
        "$HOME/.steam/steam/steamapps/common/Godot/godot4" \
        "$HOME/.local/share/Steam/steamapps/common/Godot/Godot" \
        "/Applications/Godot.app/Contents/MacOS/Godot"; do
        [ -x "$dir" ] && echo "$dir" && return
    done
    echo ""
}

GODOT="$(find_godot)"

if [ -z "$GODOT" ]; then
    echo "❌ 找不到 Godot。设置 GODOT_BIN，例如:"
    echo "   export GODOT_BIN=/usr/local/bin/godot"
    exit 1
fi

echo "🔧 $GODOT $("$GODOT" --version 2>&1)"

# ─── 1/2 语法检查 ─────────────────────────────────────────
echo ""
echo "═══ 语法检查 ═══"
echo ""
"$GODOT" --headless --path "$PROJECT_DIR" --quit 2>&1
rc=$?
if [ $rc -ne 0 ]; then
    echo "❌ 语法检查失败"
    exit $rc
fi
echo "✅ 通过"

# ─── 2/2 集成测试 ─────────────────────────────────────────
echo ""
echo "═══ 单元测试 ═══"
echo ""
"$GODOT" --headless "res://scenes/test_runner.tscn" --path "$PROJECT_DIR" 2>&1
rc=$?
echo ""
[ $rc -eq 0 ] && echo "✅ 全部通过" || echo "❌ 测试有失败"
exit $rc
