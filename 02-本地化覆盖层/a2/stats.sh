#!/bin/bash
# stats.sh - A2 累积统计：跟踪"距无感期还有多远"
#
# 输出：
#   1. fact_queue 累积条数（按触发点分类）
#   2. 4 维度偏差统计（对应 fact_8067 4 维度无感模型）
#   3. 估算"距无感期还差多少 session"
#   4. 推荐下一步动作

set -e

FACT_QUEUE="/tmp/dikw_fact_queue"
APPLY_DIR="/home/zhao/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3"

log() { echo "[$(date '+%H:%M:%S')] $*"; }
warn() { echo "[$(date '+%H:%M:%S')] ⚠️  $*"; }

log "=========================================="
log "📊 A2 累积统计"
log "=========================================="

if [[ ! -d "$FACT_QUEUE" ]]; then
    warn "fact_queue 目录不存在: $FACT_QUEUE"
    warn "请先跑任意触发点"
    exit 0
fi

# 1. fact_queue 累积条数（按触发点分类）
log ""
log "## 1. fact_queue 累积条数"
log ""

TOTAL=$(ls "$FACT_QUEUE"/*.json 2>/dev/null | wc -l)
log "  总计: $TOTAL 条"

# 按触发点分类
T1_COUNT=$(ls "$FACT_QUEUE"/apply_history_*.json 2>/dev/null | wc -l)
T2_COUNT=$(ls "$FACT_QUEUE"/diff_pattern_*.json 2>/dev/null | wc -l)
T3_COUNT=$(ls "$FACT_QUEUE"/deviation_*.json 2>/dev/null | wc -l)

log "  触发点 1 (apply_history): $T1_COUNT 条"
log "  触发点 2 (diff_pattern):  $T2_COUNT 条"
log "  触发点 3 (deviation):    $T3_COUNT 条"

# 2. 4 维度偏差统计
log ""
log "## 2. 4 维度偏差统计（对应 fact_8067 无感模型）"
log ""

BEHAVIOR_COUNT=$(ls "$FACT_QUEUE"/deviation_behavior_*.json 2>/dev/null | wc -l)
STYLE_COUNT=$(ls "$FACT_QUEUE"/deviation_style_*.json 2>/dev/null | wc -l)
KNOWLEDGE_COUNT=$(ls "$FACT_QUEUE"/deviation_knowledge_*.json 2>/dev/null | wc -l)
PERFORMANCE_COUNT=$(ls "$FACT_QUEUE"/deviation_performance_*.json 2>/dev/null | wc -l)

# 各维度当前覆盖率（用简化的累积模型）
# 起点 71% 平均分到 4 维度：行为 60% / 风格 50% / 知识 30% / 性能 100%
# 偏差 → 覆盖率降低
BEHAVIOR_COVERAGE=$((60 - BEHAVIOR_COUNT * 2))
STYLE_COVERAGE=$((50 - STYLE_COUNT * 2))
KNOWLEDGE_COVERAGE=$((30 - KNOWLEDGE_COUNT * 2))
PERFORMANCE_COVERAGE=$((100 - PERFORMANCE_COUNT * 2))

# 限幅
[[ $BEHAVIOR_COVERAGE -lt 0 ]] && BEHAVIOR_COVERAGE=0
[[ $STYLE_COVERAGE -lt 0 ]] && STYLE_COVERAGE=0
[[ $KNOWLEDGE_COVERAGE -lt 0 ]] && KNOWLEDGE_COVERAGE=0
[[ $PERFORMANCE_COVERAGE -lt 0 ]] && PERFORMANCE_COVERAGE=0

log "  行为:    $BEHAVIOR_COUNT 个偏差 → 当前覆盖率 $BEHAVIOR_COVERAGE%（无感阈值 80%）"
log "  风格:    $STYLE_COUNT 个偏差 → 当前覆盖率 $STYLE_COVERAGE%（无感阈值 70%）"
log "  知识:    $KNOWLEDGE_COUNT 个偏差 → 当前覆盖率 $KNOWLEDGE_COVERAGE%（无感阈值 60%）"
log "  性能:    $PERFORMANCE_COUNT 个偏差 → 当前覆盖率 $PERFORMANCE_COVERAGE%（无感阈值 100%）"

# 最低阈值
MIN_COVERAGE=$KNOWLEDGE_COVERAGE
[[ $BEHAVIOR_COVERAGE -lt $MIN_COVERAGE ]] && MIN_COVERAGE=$BEHAVIOR_COVERAGE
[[ $STYLE_COVERAGE -lt $MIN_COVERAGE ]] && MIN_COVERAGE=$STYLE_COVERAGE
[[ $PERFORMANCE_COVERAGE -lt $MIN_COVERAGE ]] && MIN_COVERAGE=$PERFORMANCE_COVERAGE

log ""
log "  最低维度: 知识 ($KNOWLEDGE_COVERAGE% > 60% 阈值 = $([ $KNOWLEDGE_COVERAGE -ge 60 ] && echo "无感" || echo "有感"))"

# 3. 估算"距无感期还差多少 session"
log ""
log "## 3. 距无感期估算（fact_8068 数学）"
log ""

# 简化的累积模型：
# 每次跑应用 = 行为 +0.5%, 风格 +0.3%, 知识 +0.2%, 性能 0%
# 行为到 80% 还要 (80 - BEHAVIOR_COVERAGE) / 0.5 = N session
# 风格到 70% 还要 (70 - STYLE_COVERAGE) / 0.3 = N session
# 知识到 60% 还要 (60 - KNOWLEDGE_COVERAGE) / 0.2 = N session

BEHAVIOR_NEED=$(( (80 - BEHAVIOR_COVERAGE) * 2 ))
STYLE_NEED=$(( (70 - STYLE_COVERAGE) * 100 / 30 ))
KNOWLEDGE_NEED=$(( (60 - KNOWLEDGE_COVERAGE) * 5 ))

# 限正数
[[ $BEHAVIOR_NEED -lt 0 ]] && BEHAVIOR_NEED=0
[[ $STYLE_NEED -lt 0 ]] && STYLE_NEED=0
[[ $KNOWLEDGE_NEED -lt 0 ]] && KNOWLEDGE_NEED=0

# 最低
MAX_NEED=$BEHAVIOR_NEED
[[ $STYLE_NEED -gt $MAX_NEED ]] && MAX_NEED=$STYLE_NEED
[[ $KNOWLEDGE_NEED -gt $MAX_NEED ]] && MAX_NEED=$KNOWLEDGE_NEED

log "  行为到 80% 还要: $BEHAVIOR_NEED session"
log "  风格到 70% 还要: $STYLE_NEED session"
log "  知识到 60% 还要: $KNOWLEDGE_NEED session"
log "  最低维度（知识）: $KNOWLEDGE_NEED session"
log ""
log "  📅 按主上使用频率（约 1 session/天）"
log "     无感期预计: $KNOWLEDGE_NEED 天 = 约 $((KNOWLEDGE_NEED / 7)) 周"

# 4. 推荐下一步
log ""
log "## 4. 推荐下一步"
log ""

if [[ $TOTAL -eq 0 ]]; then
    log "  ⚠️  fact_queue 为空。建议："
    log "     1. 跑一次 apply_localization.sh"
    log "     2. 跑一次 verify_localized.sh"
    log "     3. 跑一次 a2/triggers/detect_deviation.sh knowledge '示例偏差' '示例期望' '示例建议'"
elif [[ $KNOWLEDGE_NEED -gt 30 ]]; then
    log "  ⚠️  知识维度还差 $KNOWLEDGE_NEED session。建议："
    log "     1. 多用 detect_deviation.sh 报告知识偏差"
    log "     2. 强化 sync_to_generic.sh（从本地抽取更多 fact）"
elif [[ $KNOWLEDGE_NEED -gt 10 ]]; then
    log "  📊 接近无感期。还差 $KNOWLEDGE_NEED session。建议："
    log "     1. 继续累积（每次跑自动 fact_store）"
    log "     2. 关注应用历史（触发点 1）"
else
    log "  🎉 已进入无感期！建议："
    log "     1. 关注超越期（50+ session 可能比本地更准）"
    log "     2. 准备扩展 B/C 范围"
fi

log ""
log "=========================================="
log "✅ 统计完成"
log "=========================================="
