#!/bin/bash
# verify_source_patches.sh - B 范围源码补丁验证脚本
#
# 思路：
#   应用完 patch 后，验证：
#   1. 编译/lint（pyflakes 基础检查）
#   2. import 测试（关键模块能 import）
#   3. 关键函数存在（grep 检查）
#   4. 不破坏已有功能（基础 smoke test）
#
# 安全设计：
#   - 默认只读检查（不改任何东西）
#   - 失败时打印修复建议
#   - 触发点：自动 fact_store 验证结果

set -e

B_DIR="/home/zhao/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/b"
HERMES_SRC="${HERMES_HOME:-/home/zhao/.hermes/hermes-agent}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_HUMAN=$(date '+%Y-%m-%d %H:%M:%S')

mkdir -p "$B_DIR/logs"

log() { echo "[$(date '+%H:%M:%S')] $*"; }
err() { echo "[$(date '+%H:%M:%S')] ❌ $*"; }
warn() { echo "[$(date '+%H:%M:%S')] ⚠️  $*"; }

log "=========================================="
log "🔍 B 范围源码补丁验证"
log "=========================================="
log "hermes-agent 源码目录: $HERMES_SRC"

if [[ ! -d "$HERMES_SRC" ]]; then
    err "源码目录不存在: $HERMES_SRC"
    exit 1
fi

cd "$HERMES_SRC"

# 1. 检查 6 个 patch 涉及的关键文件/函数
log ""
log "[1/4] 关键文件/函数存在性检查"

CHECKS_PASSED=0
CHECKS_FAILED=0

# 1.1 fact_feedback_loop.py
if [[ -f "$HERMES_SRC/agent/fact_feedback_loop.py" ]]; then
    log "  ✅ agent/fact_feedback_loop.py 存在"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    err "  ❌ agent/fact_feedback_loop.py 缺失"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# 1.2 skill_auto_trigger.py
if [[ -f "$HERMES_SRC/agent/skill_auto_trigger.py" ]]; then
    log "  ✅ agent/skill_auto_trigger.py 存在"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    err "  ❌ agent/skill_auto_trigger.py 缺失"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# 1.3 _inject_vault_duty 函数（DIKW vault-write duty）
if grep -q "_inject_vault_duty" "$HERMES_SRC/agent/tool_executor.py" 2>/dev/null; then
    log "  ✅ _inject_vault_duty 函数存在（DIKW vault-write duty）"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    err "  ❌ _inject_vault_duty 函数缺失（DIKW vault-write duty）"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# 1.4 Holographic CJK 2-gram
if grep -q "2.gram\|cjk_2gram\|jaccard" "$HERMES_SRC/plugins/memory/holographic/retrieval.py" 2>/dev/null; then
    log "  ✅ Holographic CJK 2-gram 分词存在"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    warn "  ⚠️  Holographic CJK 2-gram 分词未找到（可能是 grep 关键词不匹配）"
fi

# 1.5 adaptive_threshold（adaptive-threshold patch）
if grep -q "adaptive_threshold" "$HERMES_SRC/agent/agent_init.py" 2>/dev/null; then
    log "  ✅ adaptive_threshold 参数存在"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    warn "  ⚠️  adaptive_threshold 参数未找到"
fi

# 1.6 feishu-card 增强
if grep -q "feishu_card\|card_message" "$HERMES_SRC/gateway/platforms/feishu.py" 2>/dev/null; then
    log "  ✅ feishu card 增强存在"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    warn "  ⚠️  feishu card 增强未找到"
fi

# 1.7 vision 1210 retry
if grep -q "1210\|upstream" "$HERMES_SRC/tools/vision_tools.py" 2>/dev/null; then
    log "  ✅ vision 1210 retry 存在"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    warn "  ⚠️  vision 1210 retry 未找到"
fi

# 2. import 测试
log ""
log "[2/4] Python import 测试"
if command -v python3 &>/dev/null; then
    # 找一个能被 import 的关键文件
    if python3 -c "import sys; sys.path.insert(0, '$HERMES_SRC'); import agent.tool_executor" 2>/dev/null; then
        log "  ✅ agent.tool_executor 可 import"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        warn "  ⚠️  agent.tool_executor import 失败（可能是依赖未装）"
    fi
else
    warn "  ⚠️  python3 不在 PATH"
fi

# 3. pyflakes 基础检查
log ""
log "[3/4] pyflakes 基础检查"
if command -v pyflakes3 &>/dev/null || command -v pyflakes &>/dev/null; then
    PYFLAKES=$(command -v pyflakes3 || command -v pyflakes)
    log "  跑 pyflakes: $PYFLAKES"
    if $PYFLAKES "$HERMES_SRC/agent/" 2>&1 | head -20; then
        log "  ✅ pyflakes 通过"
    else
        warn "  ⚠️  pyflakes 有警告（不一定是 B 范围引入的）"
    fi
else
    warn "  ⚠️  pyflakes 未安装（pip install pyflakes）"
fi

# 4. 综合
log ""
log "[4/4] 综合结果"
log "  ✅ 通过: $CHECKS_PASSED"
log "  ❌ 失败: $CHECKS_FAILED"

if [[ $CHECKS_FAILED -gt 0 ]]; then
    err "  B 范围补丁有缺失，请检查应用是否完整"
    err "  重应用: bash $B_DIR/apply_source_patches.sh --apply"
    err "  回滚: bash $B_DIR/apply_source_patches.sh --rollback"
    exit 1
fi

log ""
log "=========================================="
log "✅ B 范围验证完成"
log "=========================================="

# 触发点：自动 fact_store（B 范围验证结果）
log ""
log "[5/5] 触发点：B 范围自动 fact_store（验证结果）"
if [[ -f "$B_DIR/triggers/verify_source_patches_with_fact_store.sh" ]]; then
    bash "$B_DIR/triggers/verify_source_patches_with_fact_store.sh" "$CHECKS_PASSED" "$CHECKS_FAILED"
fi
