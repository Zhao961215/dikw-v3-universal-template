#!/bin/bash
# apply_with_fact_store.sh - 触发点 1：apply 末尾自动 fact_store 应用历史
#
# 思路：
#   跑完 apply_localization.sh 后 → 自动写 1 条 fact 到 fact_queue
#   fact 记录：本次应用时间、覆盖范围、产物大小
#   下次主上启动时，由 fact_store 工具统一消化（fact_queue → Holographic）
#
# 触发：A1 apply_localization.sh 跑成功后，自动调用本脚本
#
# 关键设计：预留 B/C 扩展点
#   - fact_queue 目录是通用的，B/C 触发点也写到同一目录
#   - 任何 Agent 实例都能消费 fact_queue
#   - 不修改 A1 文件（用 wrapper 模式）

set -e

FACT_QUEUE="/tmp/dikw_fact_queue"
APPLY_DIR="/home/zhao/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_HUMAN=$(date '+%Y-%m-%d %H:%M:%S')

mkdir -p "$FACT_QUEUE"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# 1. 收集本次 apply 信息
LEVEL="${1:-medium}"
APPLY_LOG="${APPLY_DIR}/logs/apply_${TIMESTAMP}.log"
SIZE_BEFORE=$(stat -c %s "$APPLY_DIR/../通用版_v3/02-SOUL.md" 2>/dev/null || echo 0)
SIZE_AFTER=$(stat -c %s "/home/zhao/.hermes/SOUL.md" 2>/dev/null || echo 0)

# 2. 写 1 条 method 类 fact（应用历史）
FACT_FILE="$FACT_QUEUE/apply_history_${TIMESTAMP}.json"
cat > "$FACT_FILE" << EOF
{
  "trigger": "apply_with_fact_store",
  "timestamp": "$DATE_HUMAN",
  "level": "$LEVEL",
  "method": "DIKW 自增强回路触发点 1：apply 应用历史",
  "content": "A2 触发点 1 - apply 应用历史 - 级别 $LEVEL - 时间 $DATE_HUMAN - SOUL.md $SIZE_BEFORE → $SIZE_AFTER 字节",
  "query": "A2 触发点 1 apply 应用历史 级别 时间 字节 DIKW 自增强回路",
  "category": "general",
  "source": "a2_trigger_1"
}
EOF

log "✅ 触发点 1：fact_queue 写入完成"
log "   fact 文件: $FACT_FILE"
log "   内容预览: $(cat $FACT_FILE | head -c 100)..."

# 3. 累计统计
STATS_FILE="$APPLY_DIR/a2/stats/fact_queue_count.txt"
COUNT=$(ls "$FACT_QUEUE"/*.json 2>/dev/null | wc -l)
echo "$COUNT" > "$STATS_FILE"
log "   fact_queue 累计: $COUNT 条"

# 4. 输出待 fact_store 的 fact 列表（给主上 / 后续工具消费）
echo ""
echo "=========================================="
echo "📦 fact_queue 待 fact_store 的 fact 列表"
echo "=========================================="
for f in "$FACT_QUEUE"/*.json; do
    if [[ -f "$f" ]]; then
        echo "  📄 $f"
        echo "     $(jq -r '.method // .trigger // "未知"' "$f" 2>/dev/null || grep '"trigger"' "$f" | head -1)"
    fi
done

log ""
log "💡 消费方式："
log "   1. 主上系统下次启动 → fact_store 工具读 /tmp/dikw_fact_queue/*.json → 写入 Holographic"
log "   2. 手工消费：python3 -c \"import json, os; [print(json.load(open(f))['content']) for f in os.listdir('/tmp/dikw_fact_queue') if f.endswith('.json')]\""
log "   3. 预留 B/C：未来 B/C 触发点也写到 fact_queue，统一消化"
