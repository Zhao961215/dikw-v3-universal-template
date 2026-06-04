#!/bin/bash
# verify_with_diff_pattern.sh - 触发点 2：verify 末尾自动 fact_store diff pattern
#
# 思路：
#   verify_localized.sh 跑完 diff 后 → 抽 1-5 条 diff pattern → fact_store
#   每次跑吸收 1 个新 pattern → 累计覆盖"通用版 vs 本地风格差异"
#   下次 apply 时，可以参考 fact_queue 里的 pattern，调整 overlay
#
# 关键设计：预留 B/C 扩展点
#   - 模式分类器（按行类型：代码块差异 / 引号差异 / 链接差异 / 表格差异）
#   - B/C 触发点也用同样的 pattern 分类器

set -e

FACT_QUEUE="/tmp/dikw_fact_queue"
APPLY_DIR="/home/zhao/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_HUMAN=$(date '+%Y-%m-%d %H:%M:%S')

# 参数：要 fact_store 的最大 diff 模式数（避免 spam）
MAX_FACTS="${1:-5}"

mkdir -p "$FACT_QUEUE"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=========================================="
log "触发点 2：verify diff pattern 自动 fact_store"
log "=========================================="
log "MAX_FACTS: $MAX_FACTS"

# 1. 跑 verify（如果之前没跑过）
if [[ ! -d /tmp/verify_localized_* ]]; then
    log "[1/4] 先跑 verify_localized.sh..."
    bash "$APPLY_DIR/tests/verify_localized.sh" 2>&1 | tail -20
fi

# 2. 找最新的 verify 目录
LATEST_VERIFY=$(ls -td /tmp/verify_localized_* 2>/dev/null | head -1)
if [[ -z "$LATEST_VERIFY" ]]; then
    log "❌ 没有 verify 目录，无法抽取 diff pattern"
    exit 1
fi
log "[2/4] 最新 verify 目录: $LATEST_VERIFY"

# 3. 抽取 diff pattern（按文件 + 按行类型）
PATTERN_COUNT=0
for f in SOUL.md AGENTS.md "data/knowledge/vault/00-系统文档/记忆系统使用指南.md"; do
    BUILD_FILE="$LATEST_VERIFY/home/zhao/.hermes/$f"
    LOCAL_FILE="/home/zhao/.hermes/$f"

    if [[ ! -f "$BUILD_FILE" ]]; then
        continue
    fi

    # 抽 1 个有代表性的 pattern（每文件 1 个，按"代码块"或"引号"分类）
    DIFF_SAMPLE=$(diff "$BUILD_FILE" "$LOCAL_FILE" 2>/dev/null | head -30)

    # 分类 pattern
    PATTERN_TYPE="unknown"
    if echo "$DIFF_SAMPLE" | grep -qE "^\< \`" ; then
        PATTERN_TYPE="code_block"
        PATTERN_DESC="通用版用 \\\`代码块\\\` 包裹某些术语，本地用普通文本"
    elif echo "$DIFF_SAMPLE" | grep -qE "「|」" ; then
        PATTERN_TYPE="bracket_style"
        PATTERN_DESC="通用版用 \\\`「」\\\` 引号，本地用其他引号风格"
    elif echo "$DIFF_SAMPLE" | grep -qE "^\< \| " ; then
        PATTERN_TYPE="table_format"
        PATTERN_DESC="表格列宽或对齐方式差异"
    else
        PATTERN_TYPE="formatting"
        PATTERN_DESC="格式风格差异（引号/空行/链接包裹）"
    fi

    # 写 fact
    FACT_FILE="$FACT_QUEUE/diff_pattern_${PATTERN_TYPE}_${TIMESTAMP}.json"
    cat > "$FACT_FILE" << EOF
{
  "trigger": "verify_with_diff_pattern",
  "timestamp": "$DATE_HUMAN",
  "pattern_type": "$PATTERN_TYPE",
  "file": "$f",
  "method": "DIKW 自增强回路触发点 2：diff pattern",
  "content": "A2 触发点 2 - $f diff pattern: $PATTERN_DESC",
  "query": "A2 触发点 2 diff pattern $PATTERN_TYPE $f DIKW 自增强回路 风格",
  "category": "lesson",
  "source": "a2_trigger_2"
}
EOF

    log "  ✅ $f pattern: $PATTERN_TYPE"
    PATTERN_COUNT=$((PATTERN_COUNT + 1))

    if [[ $PATTERN_COUNT -ge $MAX_FACTS ]]; then
        log "  ⚠️ 已达 MAX_FACTS=$MAX_FACTS 上限，停止抽取"
        break
    fi
done

# 4. 累计统计
STATS_FILE="$APPLY_DIR/a2/stats/fact_queue_count.txt"
COUNT=$(ls "$FACT_QUEUE"/*.json 2>/dev/null | wc -l)
echo "$COUNT" > "$STATS_FILE"
log "[3/4] fact_queue 累计: $COUNT 条"

log "[4/4] ✅ 触发点 2 完成"
log ""
log "💡 消费方式："
log "   主上系统下次启动 → fact_store 工具读 /tmp/dikw_fact_queue/*.json → 写入 Holographic"
log "   应用：下次 apply 时可参考这些 pattern 调整 overlay"
