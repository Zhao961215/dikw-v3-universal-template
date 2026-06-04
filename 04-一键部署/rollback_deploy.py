#!/usr/bin/env python3
"""
rollback_deploy.py - DIKW v3 一键回滚脚本

回滚 deploy_dikw.py 做的所有改动：
  1. 找所有 .bak-时间戳 文件
  2. 找所有 .a_range_backup/、.b_range_backup/、.c_range_backup/ 备份目录
  3. 用最近的时间戳恢复
  4. 删除部署时新建的目录

用法：
  python3 rollback_deploy.py
  python3 rollback_deploy.py --hermes-src /custom/hermes-agent
  python3 rollback_deploy.py --dry-run  # 只看不实际回滚
"""

import argparse
import os
import shutil
import sys
from datetime import datetime
from pathlib import Path

# =================== 常量 ===================
HERMES_HOME = Path(os.path.expanduser("~/.hermes"))
DEFAULT_HERMES_SRC = HERMES_HOME / "hermes-agent"

# 通用版 4 文件
GENERIC_FILES = [
    "00-README.md",
    "01-记忆系统使用指南.md",
    "02-SOUL.md",
    "03-AGENTS.md",
]

# 部署时新建的目录
DEPLOYED_DIRS = [
    HERMES_HOME / "data" / "knowledge" / "vault" / "00-系统文档" / "本地化覆盖层_v3" / "a2",
    HERMES_HOME / "c_localization_index",
]


def log_print(msg, level="info"):
    icons = {"info": "ℹ️ ", "success": "✅", "warning": "⚠️ ", "error": "❌", "step": "▶️"}
    icon = icons.get(level, "")
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] {icon} {msg}", flush=True)


def find_latest_backup(bak_dir, prefix=""):
    """找最新的备份目录"""
    if not bak_dir.exists():
        return None
    candidates = [d for d in bak_dir.iterdir() if d.is_dir() and d.name.startswith(prefix)]
    if not candidates:
        return None
    # 按名字排序（带时间戳）
    candidates.sort(reverse=True)
    return candidates[0]


def rollback_generic_files(dry_run=False):
    """回滚通用版 4 文件"""
    log_print("▶️ 回滚通用版 4 文件...", "step")
    
    rolled = 0
    for filename in GENERIC_FILES:
        # 找 .bak-时间戳
        if filename == "00-README.md":
            file_path = HERMES_HOME / filename
        elif filename == "01-记忆系统使用指南.md":
            file_path = HERMES_HOME / "data" / "knowledge" / "vault" / "00-系统文档" / filename
        else:
            file_path = HERMES_HOME / filename
        
        bak_files = sorted(file_path.parent.glob(f"{filename}.bak-*"), reverse=True)
        if bak_files:
            latest_bak = bak_files[0]
            log_print(f"  ✅ {filename} → 恢复 {latest_bak.name}", "success")
            if not dry_run:
                shutil.copy2(latest_bak, file_path)
            rolled += 1
        else:
            log_print(f"  ⚠️  {filename} 无 .bak 备份（可能 deploy 没改）", "warning")
    
    return rolled


def rollback_c_modules(hermes_src, dry_run=False):
    """回滚 C 5 个新模块（如果有 .c_range_backup/）"""
    log_print("▶️ 回滚 C 5 个新模块...", "step")
    
    c_backup = find_latest_backup(hermes_src / ".c_range_backup")
    if not c_backup:
        log_print("  ⚠️  无 .c_range_backup/，跳过", "warning")
        return 0
    
    log_print(f"  找到 C 备份: {c_backup.name}", "info")
    if not dry_run:
        # 实际恢复逻辑：找到 c_backup 里的 5 个新模块，覆盖回去
        for mod_name in ["cirAAF_mechanic.py", "cirAAF_mechanic.sh", "information_flow", "hermes-plugins", "wondelai-skills"]:
            src = c_backup / mod_name
            if mod_name in ["cirAAF_mechanic.py", "cirAAF_mechanic.sh", "information_flow"]:
                dst = hermes_src / "agent" / mod_name
            else:
                dst = hermes_src / mod_name
            
            if src.exists() and dst.exists():
                if src.is_dir():
                    shutil.rmtree(dst)
                    shutil.copytree(src, dst)
                else:
                    shutil.copy2(src, dst)
                log_print(f"    ✅ {mod_name} 已恢复", "success")
    return 1


def rollback_b_patches(hermes_src, dry_run=False):
    """回滚 B 6 个 patch（用 git）"""
    log_print("▶️ 回滚 B 6 个 patch（用 git）...", "step")
    
    b_backup = find_latest_backup(hermes_src / ".b_range_backup")
    if not b_backup:
        log_print("  ⚠️  无 .b_range_backup/，跳过", "warning")
        log_print("  建议：手动 `git checkout <file>` 恢复", "info")
        return 0
    
    log_print(f"  找到 B 备份: {b_backup.name}", "info")
    log_print("  提示：B 范围实际改的是 hermes-agent 源码", "info")
    log_print("  建议：手动执行 `git status` + `git diff` 确认差异", "info")
    log_print("        然后 `git checkout <file>` 恢复单个文件", "info")
    return 1


def rollback_deployed_dirs(dry_run=False):
    """删除部署时新建的目录"""
    log_print("▶️ 清理部署时新建的目录...", "step")
    
    for d in DEPLOYED_DIRS:
        if d.exists():
            log_print(f"  ✅ 清理 {d}", "success")
            if not dry_run:
                shutil.rmtree(d)
        else:
            log_print(f"  ⚠️  {d} 不存在，跳过", "warning")


def main():
    parser = argparse.ArgumentParser(
        description="DIKW v3 一键回滚",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--hermes-src",
        type=str,
        default=str(DEFAULT_HERMES_SRC),
        help=f"hermes-agent 源码目录（默认: {DEFAULT_HERMES_SRC}）"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="只看不实际回滚"
    )
    parser.add_argument(
        "--keep-deployed-dirs",
        action="store_true",
        help="保留 a2/、c_localization_index/ 等部署目录（不删除）"
    )
    
    args = parser.parse_args()
    args.hermes_src = Path(args.hermes_src)
    
    log_print("🔙 DIKW v3 一键回滚", "step")
    log_print(f"  ~/.hermes: {HERMES_HOME}", "info")
    log_print(f"  hermes-src: {args.hermes_src}", "info")
    log_print(f"  模式: {'DRY-RUN' if args.dry_run else '实际回滚'}", "info")
    log_print("", "info")
    
    # 回滚
    rollback_generic_files(dry_run=args.dry_run)
    log_print("", "info")
    rollback_c_modules(args.hermes_src, dry_run=args.dry_run)
    log_print("", "info")
    rollback_b_patches(args.hermes_src, dry_run=args.dry_run)
    log_print("", "info")
    
    if not args.keep_deployed_dirs:
        rollback_deployed_dirs(dry_run=args.dry_run)
    else:
        log_print("  跳过清理部署目录（--keep-deployed-dirs）", "info")
    
    log_print("", "info")
    log_print("==========================================", "step")
    log_print("🎉 回滚完成", "success")
    log_print("==========================================", "step")
    log_print("  ⚠️  建议: 跑 `git status` 确认所有文件已恢复", "info")


if __name__ == "__main__":
    main()
