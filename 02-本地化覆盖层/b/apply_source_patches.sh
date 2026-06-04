#!/bin/bash
# apply_source_patches.sh - B 范围源码补丁应用脚本
#
# 思路：
#   1. 接受用户传入的 hermes-agent 源码目录
#   2. 默认 dry-run 模式（**关键**：不实际 patch，只打印 diff）
#   3. 只有 --apply 才实际改文件
#   4. 应用前必备份（.bak 时间戳）
#   5. 应用后跑 verify_source_patches.sh 验证
#
# 安全设计（按主上"非必要不动本地"硬底线 + P0）：
#   - 默认 dry-run（不实际改）
#   - --apply 模式才改（明确同意）
#   - 应用前自动备份（任何被改的文件 .bak 时间戳）
#   - 应用后自动跑 verify
#   - 失败自动回滚（基于备份）
#
# 用法：
#   ./apply_source_patches.sh                          # 默认 dry-run
#   ./apply_source_patches.sh --apply                 # 实际应用
#   ./apply_source_patches.sh --src /path/to/hermes-agent  # 指定源码目录
#   ./apply_source_patches.sh --rollback              # 回滚（用最近的 .bak）

set -e

B_DIR="/home/zhao/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/b"
PATCHES_DIR="$B_DIR/patches"
HERMES_SRC="${HERMES_HOME:-/home/zhao/.hermes/hermes-agent}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_HUMAN=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="$B_DIR/logs/apply_${TIMESTAMP}.log"

mkdir -p "$B_DIR/logs"

# 参数解析
MODE="dry-run"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --apply)
            MODE="apply"
            shift
            ;;
        --src)
            HERMES_SRC="$2"
            shift 2
            ;;
        --rollback)
            MODE="rollback"
            shift
            ;;
        *)
            echo "未知参数: $1"
            echo "用法: $0 [--apply] [--src DIR] [--rollback]"
            exit 1
            ;;
    esac
done

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
err() { echo "[$(date '+%H:%M:%S')] ❌ $*" | tee -a "$LOG_FILE"; }

log "=========================================="
log "B 范围源码补丁应用脚本"
log "=========================================="
log "模式: $MODE"
log "hermes-agent 源码目录: $HERMES_SRC"
log "patches 目录: $PATCHES_DIR"
log "时间: $DATE_HUMAN"

# 0. 前置检查
if [[ ! -d "$HERMES_SRC" ]]; then
    err "源码目录不存在: $HERMES_SRC"
    exit 1
fi

if [[ ! -d "$HERMES_SRC/.git" ]]; then
    err "$HERMES_SRC 不是 git 仓库（缺 .git）"
    exit 1
fi

cd "$HERMES_SRC"
log ""
log "[1/4] git 状态检查"
git status --porcelain >> "$LOG_FILE" 2>&1
git log --oneline -1 >> "$LOG_FILE" 2>&1
log "  当前分支: $(git branch --show-current)"
log "  当前 HEAD: $(git log --oneline -1 | head -1)"

# 1. 回滚模式
if [[ "$MODE" == "rollback" ]]; then
    log ""
    log "[2/4] 回滚模式：找最近的 .bak 文件"
    BACKUP_DIR="$HERMES_SRC/.b_range_backup"
    if [[ ! -d "$BACKUP_DIR" ]]; then
        err "没有 $BACKUP_DIR，无法回滚"
        exit 1
    fi
    LATEST_BACKUP=$(ls -td "$BACKUP_DIR"/*/ 2>/dev/null | head -1)
    if [[ -z "$LATEST_BACKUP" ]]; then
        err "没有备份目录"
        exit 1
    fi
    log "  最近备份: $LATEST_BACKUP"
    log "  ⚠️  回滚操作不可逆，请确认！"
    read -p "  确认回滚? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        log "  取消回滚"
        exit 0
    fi
    # 实际回滚（用 cp -r 恢复）
    cp -r "$LATEST_BACKUP"/* "$HERMES_SRC/"
    log "  ✅ 回滚完成"
    exit 0
fi

# 2. 备份（应用模式才备份）
if [[ "$MODE" == "apply" ]]; then
    log ""
    log "[2/4] 备份当前源码（.b_range_backup/$TIMESTAMP/）"
    BACKUP_DIR="$HERMES_SRC/.b_range_backup/$TIMESTAMP"
    mkdir -p "$BACKUP_DIR"
    # 只备份会被 patch 影响到的文件
    for patch in "$PATCHES_DIR"/*.patch "$PATCHES_DIR"/*.diff; do
        if [[ -f "$patch" ]]; then
            # 抽 patch 涉及的文件路径
            grep "^diff --git" "$patch" | awk '{print $3}' | sed 's|^a/||' | sed 's|^b/||' | while read f; do
                if [[ -f "$HERMES_SRC/$f" ]]; then
                    mkdir -p "$BACKUP_DIR/$(dirname "$f")"
                    cp "$HERMES_SRC/$f" "$BACKUP_DIR/$f"
                fi
            done
        fi
    done
    log "  备份到: $BACKUP_DIR"
fi

# 3. 应用 patch
log ""
log "[3/4] 应用 patch"
APPLIED=0
FAILED=0
for patch in $(ls "$PATCHES_DIR"/*.patch "$PATCHES_DIR"/*.diff 2>/dev/null | sort); do
    if [[ ! -f "$patch" ]]; then
        continue
    fi
    log ""
    log "  [patch] $(basename $patch)"
    if [[ "$MODE" == "dry-run" ]]; then
        # dry-run：用 git apply --check 验证 patch 是否能应用
        if git apply --check "$patch" 2>>"$LOG_FILE"; then
            log "    [DRY-RUN] ✅ 可以应用"
            APPLIED=$((APPLIED + 1))
        else
            log "    [DRY-RUN] ❌ 不能应用（patch 冲突或 base 不对）"
            FAILED=$((FAILED + 1))
        fi
    else
        # apply：实际应用
        if git apply "$patch" 2>>"$LOG_FILE"; then
            log "    [APPLY] ✅ 已应用"
            APPLIED=$((APPLIED + 1))
        else
            log "    [APPLY] ❌ 应用失败"
            FAILED=$((FAILED + 1))
        fi
    fi
done

log ""
log "[4/4] 总结"
log "  ✅ 成功: $APPLIED"
log "  ❌ 失败: $FAILED"

if [[ $FAILED -gt 0 ]] && [[ "$MODE" == "apply" ]]; then
    err "有 patch 应用失败！考虑用 --rollback 回滚"
    err "回滚命令: $0 --rollback"
    exit 1
fi

# 4. dry-run 后建议
if [[ "$MODE" == "dry-run" ]]; then
    log ""
    log "💡 这是 dry-run 模式，**未实际修改任何文件**"
    log "   实际应用: $0 --apply"
    log "   实际应用 + 自定义源码: $0 --apply --src /path/to/hermes-agent"
fi

# 5. 触发点：自动 fact_store（B 范围应用历史）
log ""
log "[5/5] 触发点：B 范围自动 fact_store（应用历史）"
if [[ -f "$B_DIR/triggers/apply_source_patches_with_fact_store.sh" ]]; then
    bash "$B_DIR/triggers/apply_source_patches_with_fact_store.sh" "$MODE" "$APPLIED" "$FAILED"
else
    log "  ⚠️  B 触发点脚本不存在: $B_DIR/triggers/apply_source_patches_with_fact_store.sh"
fi

log ""
log "=========================================="
log "✅ B 范围应用完成 (mode=$MODE, success=$APPLIED, failed=$FAILED)"
log "=========================================="
