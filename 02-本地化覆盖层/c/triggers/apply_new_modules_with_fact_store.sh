#!/bin/bash
# apply_new_modules_with_fact_store.sh - C 范围触发点：apply 应用历史

set -e

FACT_QUEUE="/tmp/dikw_fact_queue"
C_DIR="/home/zhao/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/c"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_HUMAN=$(date '+%Y-%m-%d %H:%M:%S')

MODE="${1:-dry-run}"
APPLIED="${2:-0}"
FAILED="${3:-0}"

mkdir -p "$FACT_QUEUE"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=========================================="
log "C 触发点：apply 应用历史 → fact_queue"
log "=========================================="
log "模式: $MODE | 成功: $APPLIED | 失败: $FAILED"

FACT_FILE="$FACT_QUEUE/c_apply_history_${TIMESTAMP}.json"
cat > "$FACT_FILE" << EOF
{
  "trigger": "c_apply_new_modules",
  "scope": "C",
  "timestamp": "$DATE_HUMAN",
  "mode": "$MODE",
  "applied": $APPLIED,
  "failed": $FAILED,
  "method": "DIKW 自增强回路 C 范围触发点：apply 应用历史",
  "content": "C 范围触发点 - 模式 $MODE - 成功 $APPLIED - 失败 $FAILED - 时间 $DATE_HUMAN",
  "query": "C 范围 触发点 apply 应用历史 $MODE $APPLIED $FAILED DIKW 自增强回路 hermes-agent 新模块 5 个",
  "category": "general",
  "source": "c_trigger_apply"
}
EOF

log "✅ fact_queue 写入完成"
log "   fact 文件: $FACT_FILE"
