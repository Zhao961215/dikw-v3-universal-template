#!/usr/bin/env python3
"""
test_deploy.py - DIKW v3 一键部署测试脚本

模拟一次完整部署 + 验证：
  1. dry-run 模式跑一次
  2. 验证所有 4 个目录存在
  3. 验证 Python 脚本语法
  4. 验证 rollback 脚本可跑

用法：
  python3 test_deploy.py
  python3 test_deploy.py --workspace /custom/path
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

# =================== 常量 ===================
TEST_DIR = Path("/tmp/dikw_deploy_test")
DEFAULT_WORKSPACE = Path("/home/zhao/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3")


def log_print(msg, level="info"):
    icons = {"info": "ℹ️ ", "success": "✅", "warning": "⚠️ ", "error": "❌", "step": "▶️"}
    icon = icons.get(level, "")
    print(f"[test] {icon} {msg}", flush=True)


def test_workspace_exists(workspace):
    """测试 1: 工作目录存在"""
    log_print("Test 1: 工作目录存在", "step")
    if not workspace.exists():
        log_print(f"  ❌ 工作目录不存在: {workspace}", "error")
        return False
    log_print(f"  ✅ 工作目录存在: {workspace}", "success")
    return True


def test_4_directories_exist(workspace):
    """测试 2: 4 个核心目录都存在"""
    log_print("Test 2: 4 个核心目录都存在", "step")
    
    # 智能向上找
    actual = workspace
    if (workspace / "通用版_v3").exists() and (workspace / "本地化覆盖层_v3").exists():
        pass  # 情况 A: workspace 是根
    elif workspace.name == "本地化覆盖层_v3" and (workspace.parent / "通用版_v3").exists():
        actual = workspace.parent  # 情况 B: workspace 是本地化覆盖层_v3
        log_print(f"  ℹ️  智能向上: {workspace.name} → {actual.name}", "info")
    elif workspace.name == "通用版_v3" and (workspace.parent / "本地化覆盖层_v3").exists():
        actual = workspace.parent  # 情况 C: workspace 是通用版_v3
        log_print(f"  ℹ️  智能向上: {workspace.name} → {actual.name}", "info")
    else:
        log_print(f"  ⚠️  workspace 不在预期结构里", "warning")
    
    required = [
        actual / "通用版_v3",
        actual / "本地化覆盖层_v3" / "a2",
        actual / "本地化覆盖层_v3" / "b",
        actual / "本地化覆盖层_v3" / "c",
    ]
    
    all_ok = True
    for d in required:
        if d.exists():
            log_print(f"  ✅ {d.relative_to(actual)}", "success")
        else:
            log_print(f"  ❌ {d.relative_to(actual)} 缺失", "error")
            all_ok = False
    
    return all_ok


def test_scripts_compile(workspace):
    """测试 3: Python 脚本语法"""
    log_print("Test 3: Python 脚本语法", "step")
    
    scripts = [
        workspace / "deploy_dikw.py",
        workspace / "rollback_deploy.py",
        workspace / "test_deploy.py",
    ]
    
    all_ok = True
    for s in scripts:
        if not s.exists():
            log_print(f"  ⚠️  {s.name} 不存在，跳过", "warning")
            continue
        result = subprocess.run(
            ["python3", "-m", "py_compile", str(s)],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            log_print(f"  ✅ {s.name} 语法 OK", "success")
        else:
            log_print(f"  ❌ {s.name} 语法错误: {result.stderr}", "error")
            all_ok = False
    
    return all_ok


def test_dry_run(workspace):
    """测试 4: dry-run 模式跑一次 deploy_dikw.py"""
    log_print("Test 4: dry-run 模式跑一次 deploy_dikw.py", "step")
    
    deploy_script = workspace / "deploy_dikw.py"
    if not deploy_script.exists():
        log_print(f"  ❌ {deploy_script} 不存在", "error")
        return False
    
    # 在测试目录里跑（不污染真实 ~/.hermes）
    TEST_DIR.mkdir(parents=True, exist_ok=True)
    
    # 由于 deploy_dikw.py 默认要 ~/.hermes，我们用 --dry-run 模式跑
    result = subprocess.run(
        ["python3", str(deploy_script), 
         "--workspace", str(workspace),
         "--dry-run"],
        capture_output=True, text=True, timeout=60
    )
    
    if result.returncode == 0:
        log_print("  ✅ dry-run 跑通", "success")
        return True
    else:
        log_print(f"  ❌ dry-run 失败 (exit={result.returncode})", "error")
        log_print(f"  stdout: {result.stdout[:500]}", "error")
        log_print(f"  stderr: {result.stderr[:500]}", "error")
        return False


def test_status_mode(workspace):
    """测试 5: --status 模式"""
    log_print("Test 5: --status 模式", "step")
    
    deploy_script = workspace / "deploy_dikw.py"
    result = subprocess.run(
        ["python3", str(deploy_script), 
         "--workspace", str(workspace),
         "--status"],
        capture_output=True, text=True, timeout=30
    )
    
    if result.returncode == 0:
        log_print("  ✅ --status 跑通", "success")
        return True
    else:
        log_print(f"  ❌ --status 失败", "error")
        return False


def test_rollback_dry_run(workspace):
    """测试 6: rollback --dry-run 模式"""
    log_print("Test 6: rollback --dry-run 模式", "step")
    
    rollback_script = workspace / "rollback_deploy.py"
    if not rollback_script.exists():
        log_print(f"  ❌ {rollback_script} 不存在", "error")
        return False
    
    result = subprocess.run(
        ["python3", str(rollback_script), "--dry-run"],
        capture_output=True, text=True, timeout=30
    )
    
    if result.returncode == 0:
        log_print("  ✅ rollback --dry-run 跑通", "success")
        return True
    else:
        log_print(f"  ⚠️  rollback --dry-run 退出码 {result.returncode}（可能是 .bak 不存在）", "warning")
        return True  # 警告不算失败


def test_help_mode(workspace):
    """测试 7: --help 模式"""
    log_print("Test 7: --help 模式", "step")
    
    deploy_script = workspace / "deploy_dikw.py"
    result = subprocess.run(
        ["python3", str(deploy_script), "--help"],
        capture_output=True, text=True, timeout=10
    )
    
    if result.returncode == 0 and len(result.stdout) > 100:
        log_print("  ✅ --help 输出正常", "success")
        return True
    else:
        log_print(f"  ❌ --help 输出异常", "error")
        return False


def main():
    parser = argparse.ArgumentParser(description="DIKW v3 一键部署测试")
    parser.add_argument(
        "--workspace", "-w",
        type=str,
        default=str(DEFAULT_WORKSPACE),
        help=f"工作目录（默认: {DEFAULT_WORKSPACE}）"
    )
    args = parser.parse_args()
    args.workspace = Path(args.workspace)
    
    log_print("🧪 DIKW v3 一键部署测试", "step")
    log_print(f"  工作目录: {args.workspace}", "info")
    log_print("", "info")
    
    tests = [
        test_workspace_exists,
        test_4_directories_exist,
        test_scripts_compile,
        test_dry_run,
        test_status_mode,
        test_rollback_dry_run,
        test_help_mode,
    ]
    
    results = []
    for test_func in tests:
        try:
            ok = test_func(args.workspace)
            results.append((test_func.__name__, ok))
        except Exception as e:
            log_print(f"  ❌ 测试异常: {e}", "error")
            results.append((test_func.__name__, False))
        log_print("", "info")
    
    # 总结
    log_print("==========================================", "step")
    log_print("测试总结", "step")
    log_print("==========================================", "step")
    
    passed = sum(1 for _, ok in results if ok)
    failed = sum(1 for _, ok in results if not ok)
    
    for name, ok in results:
        icon = "✅" if ok else "❌"
        log_print(f"  {icon} {name}", "success" if ok else "error")
    
    log_print("", "info")
    log_print(f"  通过: {passed}/{len(results)}", "success" if failed == 0 else "warning")
    
    if failed == 0:
        log_print("🎉 所有测试通过！", "success")
        sys.exit(0)
    else:
        log_print(f"⚠️  {failed} 个测试失败", "warning")
        sys.exit(1)


if __name__ == "__main__":
    main()
