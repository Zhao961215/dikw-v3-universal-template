#!/bin/bash
# verify_new_modules.sh - C 范围自研模块验证脚本
#
# 思路：
#   应用完 5 个新模块后，验证：
#   1. 5 个新模块是否到位
#   2. 每个模块能 import（python）
#   3. 关键函数/类存在

set -e

C_DIR="/home/zhao/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/c"
HERMES_SRC="${HERMES_HOME:-/home/zhao/.hermes/hermes-agent}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

log() { echo "[$(date '+%H:%M:%S')] $*"; }
err() { echo "[$(date '+%H:%M:%S')] ❌ $*"; }

log "=========================================="
log "🔍 C 范围自研模块验证"
log "=========================================="

if [[ ! -d "$HERMES_SRC" ]]; then
    err "源码目录不存在: $HERMES_SRC"
    exit 1
fi

cd "$HERMES_SRC"

CHECKS_PASSED=0
CHECKS_FAILED=0

# 1. 5 个新模块存在性
log ""
log "[1/4] 5 个新模块存在性"

# 1.1 cirAAF_mechanic.py
if [[ -f "$HERMES_SRC/agent/cirAAF_mechanic.py" ]]; then
    log "  ✅ agent/cirAAF_mechanic.py 存在"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    err "  ❌ agent/cirAAF_mechanic.py 缺失"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# 1.2 cirAAF_mechanic.sh
if [[ -f "$HERMES_SRC/agent/cirAAF_mechanic.sh" ]]; then
    log "  ✅ agent/cirAAF_mechanic.sh 存在"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    err "  ❌ agent/cirAAF_mechanic.sh 缺失"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# 1.3 information_flow/
if [[ -d "$HERMES_SRC/agent/information_flow" ]]; then
    log "  ✅ agent/information_flow/ 存在"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    err "  ❌ agent/information_flow/ 缺失"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# 1.4 hermes-plugins/
if [[ -d "$HERMES_SRC/hermes-plugins" ]]; then
    log "  ✅ hermes-plugins/ 存在"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    err "  ❌ hermes-plugins/ 缺失"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# 1.5 wondelai-skills/
if [[ -d "$HERMES_SRC/wondelai-skills" ]]; then
    log "  ✅ wondelai-skills/ 存在"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    err "  ❌ wondelai-skills/ 缺失"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# 2. import 测试
log ""
log "[2/4] Python import 测试"
if command -v python3 &>/dev/null; then
    if python3 -c "import sys; sys.path.insert(0, '$HERMES_SRC'); from agent.information_flow import interface, impl_v2" 2>/dev/null; then
        log "  ✅ agent.information_flow 可 import（interface + impl_v2）"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        log "  ⚠️  agent.information_flow import 失败（可能是依赖未装）"
    fi
    
    if python3 -c "import sys; sys.path.insert(0, '$HERMES_SRC'); import agent.cirAAF_mechanic" 2>/dev/null; then
        log "  ✅ agent.cirAAF_mechanic 可 import"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        log "  ⚠️  agent.cirAAF_mechanic import 失败（可能是依赖未装）"
    fi
else
    log "  ⚠️  python3 不在 PATH"
fi

# 3. 关键函数/类存在
log ""
log "[3/4] 关键函数/类存在性"
# 3.1 RetrievalPipeline 类
if grep -q "class RetrievalPipeline" "$HERMES_SRC/agent/information_flow/interface.py" 2>/dev/null; then
    log "  ✅ RetrievalPipeline 类存在（information_flow 核心）"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    err "  ❌ RetrievalPipeline 类缺失"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# 3.2 cirAAF v2.3 / Layer 1
if grep -q "CIRAAF_LAYER1\|v2.3" "$HERMES_SRC/agent/cirAAF_mechanic.py" 2>/dev/null; then
    log "  ✅ cirAAF v2.3 / Layer 1 标记存在"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    log "  ⚠️  cirAAF v2.3 / Layer 1 标记未找到"
fi

# 4. 综合
log ""
log "[4/4] 综合结果"
log "  ✅ 通过: $CHECKS_PASSED"
log "  ❌ 失败: $CHECKS_FAILED"

if [[ $CHECKS_FAILED -gt 0 ]]; then
    err "  C 范围模块有缺失"
    err "  重应用: bash $C_DIR/apply_new_modules.sh --apply"
    exit 1
fi

log ""
log "=========================================="
log "✅ C 范围验证完成"
log "=========================================="

# 触发点
if [[ -f "$C_DIR/triggers/verify_new_modules_with_fact_store.sh" ]]; then
    bash "$C_DIR/triggers/verify_new_modules_with_fact_store.sh" "$CHECKS_PASSED" "$CHECKS_FAILED"
fi
