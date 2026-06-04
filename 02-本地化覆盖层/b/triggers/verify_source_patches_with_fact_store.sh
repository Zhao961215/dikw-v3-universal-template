#!/bin/bash
# verify_source_patches_with_fact_store.sh - B 范围触发点：verify 验证结果
#
# 思路：verify_source_patches.sh 末尾自动调用本脚本
# 写 1 条 lesson 类 fact 到 fact_queue
# 内容：本次验证通过/失败数
#
# 关键设计：与 A2 触发点用同一 fact_queue 目录

set -e

FACT_QUEUE="/tmp/dikw_fact_queue"
B_DIR="/home/zhao/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/b"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_HUMAN=$(date '+%Y-%m-%d %H:%M:%S')

# 参数：通过数 + 失败数
CHECKS_PASSED="${1:-0}"
CHECKS_FAILED="${2:-0}"

mkdir -p "$FACT_QUEUE"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=========================================="
log "B 触发点：verify 验证结果 → fact_queue"
log "=========================================="
log "通过: $CHECKS_PASSED | 失败: $CHECKS_FAILED"

# 写 1 条 lesson 类 fact
FACT_FILE="$FACT_QUEUE/b_verify_${TIMESTAMP}.json"
cat > "$FACT_FILE" << EOF
{
  "trigger": "b_verify_source_patches",
  "scope": "B",
  "timestamp": "$DATE_HUMAN",
  "checks_passed": $CHECKS_PASSED,
  "checks_failed": $CHECKS_FAILED,
  "method": "DIKW 自增强回路 B 范围触发点：verify 验证结果",
  "content": "B 范围触发点 - 验证通过 $CHECKS_PASSED - 验证失败 $CHECKS_FAILED - 时间 $DATE_HUMAN",
  "query": "B 范围 触发点 verify 验证 $CHECKS_PASSED $CHECKS_FAILED DIKW 自增强回路 hermes-agent 源码 patch",
  "category": "lesson",
  "source": "b_trigger_verify"
}
EOF

log "✅ fact_queue 写入完成"
log "   fact 文件: $FACT_FILE"
