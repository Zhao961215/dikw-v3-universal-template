#!/bin/bash
# detect_deviation.sh - 触发点 3：运行时偏差检测
#
# 思路：
#   接受用户/Agent 反馈"行为不符合预期" → 自动 fact_store
#   触发方式：手动调（Agent 跑通用版 + overlay 后发现偏差时）
#   或：自动调（verify_localized.sh 检测到新增 diff pattern 时）
#
# 关键设计：预留 B/C 扩展点
#   - 偏差类型枚举（行为/风格/知识/性能 4 维）
#   - 4 维对应 fact_8067 4 维度无感模型
#   - 累积后能统计"距无感期还有多远"

set -e

FACT_QUEUE="/tmp/dikw_fact_queue"
APPLY_DIR="/home/zhao/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_HUMAN=$(date '+%Y-%m-%d %H:%M:%S')

# 解析参数
DIMENSION="${1:-behavior}"        # behavior / style / knowledge / performance
DEVIATION_DESC="${2:-未描述}"      # 偏差描述
EXPECTED="${3:-未描述}"            # 期望行为
SUGGESTED_FIX="${4:-未建议}"       # 建议修复

mkdir -p "$FACT_QUEUE"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=========================================="
log "触发点 3：运行时偏差检测"
log "=========================================="
log "维度: $DIMENSION"
log "偏差: $DEVIATION_DESC"
log "期望: $EXPECTED"
log "建议: $SUGGESTED_FIX"

# 维度校验
case "$DIMENSION" in
    behavior|style|knowledge|performance) ;;
    *)
        log "❌ 维度必须是 behavior/style/knowledge/performance"
        exit 1
        ;;
esac

# 写 1 条 lesson fact
FACT_FILE="$FACT_QUEUE/deviation_${DIMENSION}_${TIMESTAMP}.json"
cat > "$FACT_FILE" << EOF
{
  "trigger": "detect_deviation",
  "timestamp": "$DATE_HUMAN",
  "dimension": "$DIMENSION",
  "deviation": "$DEVIATION_DESC",
  "expected": "$EXPECTED",
  "suggested_fix": "$SUGGESTED_FIX",
  "method": "DIKW 自增强回路触发点 3：运行时偏差",
  "content": "A2 触发点 3 - $DIMENSION 偏差: $DEVIATION_DESC | 期望: $EXPECTED | 建议: $SUGGESTED_FIX",
  "query": "A2 触发点 3 运行时偏差 $DIMENSION DIKW 自增强回路 期望 建议",
  "category": "lesson",
  "source": "a2_trigger_3"
}
EOF

log "✅ 触发点 3：fact_queue 写入完成"
log "   fact 文件: $FACT_FILE"

# 累计统计（按维度）
DIM_STATS="$APPLY_DIR/a2/stats/deviation_${DIMENSION}_count.txt"
COUNT=$(ls "$FACT_QUEUE"/deviation_${DIMENSION}_*.json 2>/dev/null | wc -l)
echo "$COUNT" > "$DIM_STATS"
log "   $DIMENSION 维度偏差累计: $COUNT 条"

log ""
log "💡 消费方式："
log "   主上系统下次启动 → fact_store 工具读 /tmp/dikw_fact_queue/*.json → 写入 Holographic"
log "   应用：下次 apply 时可参考这些偏差，针对性打补丁"

# 用法提示
if [[ "$DEVIATION_DESC" == "未描述" ]]; then
    log ""
    log "📋 用法："
    log "  $0 <dimension> <deviation> <expected> <suggested_fix>"
    log ""
    log "  示例："
    log "    $0 knowledge '回答 008163 持仓时数据错误' '应该从实体页读 35%' 'apply 时在 overlay 加实体页数据源说明'"
    log "    $0 style '输出报告时用了 emoji' '主上偏好无 emoji' 'overlay 加风格偏好：禁用 emoji'"
    log "    $0 behavior '回答投资问题时未走 11 步信息流' '应该先 fact_store 检索踩坑' 'verify 时检查 fact_store 调用记录'"
fi
