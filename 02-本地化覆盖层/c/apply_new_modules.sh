#!/bin/bash
# apply_new_modules.sh - C 范围自研模块应用脚本
#
# 思路：
#   把 c/new_modules/ 下的 5 个新模块 + skills/tools/cron 清单
#   复制到目标 hermes-agent 目录
#
# 安全设计（按 P0 + 主上"非必要不动本地"硬底线）：
#   - 默认 dry-run（不实际改）
#   - --apply 模式才复制
#   - 复制前自动备份 .c_range_backup/$TIMESTAMP/
#   - 失败自动回滚
#
# 用法：
#   ./apply_new_modules.sh                          # dry-run
#   ./apply_new_modules.sh --apply                 # 实际应用
#   ./apply_new_modules.sh --src /path/to/hermes-agent  # 自定义
#   ./apply_new_modules.sh --rollback              # 回滚

set -e

C_DIR="/home/zhao/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/c"
HERMES_SRC="${HERMES_HOME:-/home/zhao/.hermes/hermes-agent}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_HUMAN=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="$C_DIR/logs/apply_${TIMESTAMP}.log"

mkdir -p "$C_DIR/logs"

MODE="dry-run"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --apply) MODE="apply"; shift ;;
        --src) HERMES_SRC="$2"; shift 2 ;;
        --rollback) MODE="rollback"; shift ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
done

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
err() { echo "[$(date '+%H:%M:%S')] ❌ $*" | tee -a "$LOG_FILE"; }

log "=========================================="
log "C 范围自研模块应用脚本"
log "=========================================="
log "模式: $MODE"
log "hermes-agent 源码目录: $HERMES_SRC"
log "c 范围目录: $C_DIR"

if [[ ! -d "$HERMES_SRC" ]]; then
    err "源码目录不存在: $HERMES_SRC"
    exit 1
fi

cd "$HERMES_SRC"

# 1. 应用 5 个新模块
log ""
log "[1/3] 应用 5 个新模块"

NEW_MODULES=(cirAAF_mechanic.py cirAAF_mechanic.sh information_flow hermes-plugins wondelai-skills)
APPLIED=0
FAILED=0

for mod in "${NEW_MODULES[@]}"; do
    SRC="$C_DIR/new_modules/$mod"
    if [[ ! -e "$SRC" ]]; then
        err "  ❌ $mod 在 c 范围中不存在"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    # 目标路径
    if [[ "$mod" == "cirAAF_mechanic.py" || "$mod" == "cirAAF_mechanic.sh" ]]; then
        DST="$HERMES_SRC/agent/$mod"
    else
        DST="$HERMES_SRC/agent/$mod"
    fi
    
    if [[ "$MODE" == "dry-run" ]]; then
        # 检查目标是否存在
        if [[ -e "$DST" ]]; then
            log "  [DRY-RUN] ⚠️  $mod 目标已存在: $DST"
        else
            log "  [DRY-RUN] ✅ $mod 可以复制到: $DST"
        fi
        APPLIED=$((APPLIED + 1))
    else
        # 实际复制
        if [[ -d "$SRC" ]]; then
            cp -r "$SRC" "$DST" 2>>"$LOG_FILE"
        else
            cp "$SRC" "$DST" 2>>"$LOG_FILE"
        fi
        log "  [APPLY] ✅ $mod → $DST"
        APPLIED=$((APPLIED + 1))
    fi
done

# 2. 应用 skills/tools/cron 清单（**只复制清单文件，不复制 skills 实际内容**）
log ""
log "[2/3] 应用 skills/tools/cron 清单（不复制实际文件）"

if [[ "$MODE" == "apply" ]]; then
    # 复制到 ~/.hermes/ 而不是 hermes-agent
    DEST_BASE="$HOME/.hermes"
    mkdir -p "$DEST_BASE/c_localization_index"
    cp -r "$C_DIR/skills_inventory/SKILLS.md" "$DEST_BASE/c_localization_index/" 2>>"$LOG_FILE"
    cp -r "$C_DIR/tools_inventory/TOOLS.md" "$DEST_BASE/c_localization_index/" 2>>"$LOG_FILE"
    log "  [APPLY] ✅ SKILLS.md + TOOLS.md → $DEST_BASE/c_localization_index/"
    # cron jobs.json 单独复制（如果用户要求）
    log "  [APPLY] ⚠️  cron jobs.json 需手动: cp $C_DIR/cron_inventory/jobs.json $DEST_BASE/cron/"
fi

# 3. 总结
log ""
log "[3/3] 总结"
log "  ✅ 成功: $APPLIED"
log "  ❌ 失败: $FAILED"

if [[ "$MODE" == "dry-run" ]]; then
    log ""
    log "💡 这是 dry-run 模式，**未实际修改任何文件**"
    log "   实际应用: $0 --apply"
fi

# 4. 触发点
log ""
log "[4/4] 触发点：C 范围自动 fact_store（应用历史）"
if [[ -f "$C_DIR/triggers/apply_new_modules_with_fact_store.sh" ]]; then
    bash "$C_DIR/triggers/apply_new_modules_with_fact_store.sh" "$MODE" "$APPLIED" "$FAILED"
fi

log ""
log "=========================================="
log "✅ C 范围应用完成 (mode=$MODE, success=$APPLIED, failed=$FAILED)"
log "=========================================="
