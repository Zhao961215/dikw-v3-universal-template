#!/bin/bash
# apply_source_patches_with_fact_store.sh - B 范围触发点：apply 应用历史
#
# 思路：apply_source_patches.sh 末尾自动调用本脚本
# 写 1 条 method 类 fact 到 fact_queue
# 内容：本次应用模式（dry-run/apply/rollback）、成功/失败数
#
# 关键设计：与 A2 触发点用同一 fact_queue 目录

set -e

FACT_QUEUE="/tmp/dikw_fact_queue"
B_DIR="/home/zhao/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/b"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_HUMAN=$(date '+%Y-%m-%d %H:%M:%S')

# 参数：模式 + 成功数 + 失败数
MODE="${1:-dry-run}"
APPLIED="${2:-0}"
FAILED="${3:-0}"

mkdir -p "$FACT_QUEUE"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=========================================="
log "B 触发点：apply 应用历史 → fact_queue"
log "=========================================="
log "模式: $MODE | 成功: $APPLIED | 失败: $FAILED"

# 写 1 条 method 类 fact
FACT_FILE="$FACT_QUEUE/b_apply_history_${TIMESTAMP}.json"
cat > "$FACT_FILE" << EOF
{
  "trigger": "b_apply_source_patches",
  "scope": "B",
  "timestamp": "$DATE_HUMAN",
  "mode": "$MODE",
  "applied": $APPLIED,
  "failed": $FAILED,
  "method": "DIKW 自增强回路 B 范围触发点：apply 应用历史",
  "content": "B 范围触发点 - 模式 $MODE - 成功 $APPLIED - 失败 $FAILED - 时间 $DATE_HUMAN",
  "query": "B 范围 触发点 apply 应用历史 $MODE $APPLIED $FAILED DIKW 自增强回路 hermes-agent 源码 patch",
  "category": "general",
  "source": "b_trigger_apply"
}
EOF

log "✅ fact_queue 写入完成"
log "   fact 文件: $FACT_FILE"
