#!/bin/bash
# verify_new_modules_with_fact_store.sh - C 范围触发点：verify 验证结果

set -e

FACT_QUEUE="/tmp/dikw_fact_queue"
C_DIR="/home/zhao/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/c"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_HUMAN=$(date '+%Y-%m-%d %H:%M:%S')

CHECKS_PASSED="${1:-0}"
CHECKS_FAILED="${2:-0}"

mkdir -p "$FACT_QUEUE"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=========================================="
log "C 触发点：verify 验证结果 → fact_queue"
log "=========================================="
log "通过: $CHECKS_PASSED | 失败: $CHECKS_FAILED"

FACT_FILE="$FACT_QUEUE/c_verify_${TIMESTAMP}.json"
cat > "$FACT_FILE" << EOF
{
  "trigger": "c_verify_new_modules",
  "scope": "C",
  "timestamp": "$DATE_HUMAN",
  "checks_passed": $CHECKS_PASSED,
  "checks_failed": $CHECKS_FAILED,
  "method": "DIKW 自增强回路 C 范围触发点：verify 验证结果",
  "content": "C 范围触发点 - 验证通过 $CHECKS_PASSED - 验证失败 $CHECKS_FAILED - 时间 $DATE_HUMAN",
  "query": "C 范围 触发点 verify 验证 $CHECKS_PASSED $CHECKS_FAILED DIKW 自增强回路 hermes-agent 新模块",
  "category": "lesson",
  "source": "c_trigger_verify"
}
EOF

log "✅ fact_queue 写入完成"
log "   fact 文件: $FACT_FILE"
