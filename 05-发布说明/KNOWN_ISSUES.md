# KNOWN ISSUES - DIKW 记忆系统 v3.1

## 当前已知问题（v3.1）

### 1. C 范围 5 个新模块实际文件未包含在 GitHub 包

**问题**：5 个新模块（cirAAF / information_flow / hermes-plugins / wondelai-skills）实际文件 7.17 MB 太大，没进 GitHub 包。

**临时方案**：包内只放**清单**（README 索引），用户需自己 clone 实际模块。

**解决计划**（v3.2）：提供独立的"完整新模块"包（zip 下载），与 GitHub 仓库解耦。

### 2. B 范围 patch 在"已 patch"状态下 dry-run 报 0/6 通过

**问题**：本地已经是 patch 过的状态，跑 `git apply` 时所有 patch 都"已应用"，所以 0 个能 apply。

**解释**：这不是 bug——`git format-patch` 抽的是 commit diff，期望从干净 base 应用。在已 patch 状态跑是预期的。

**用户需知**：B 范围只对**干净 origin/main** 状态有效。

### 3. Python 3.10+ 硬要求

**问题**：deploy_dikw.py 用到了 `subprocess.run(timeout=)` + 现代 pathlib API，**不**支持 Python 3.9 及以下。

**解决**：如 Python 版本过低，升级到 3.10+。

### 4. fact_queue 解耦设计

**问题**：沙箱内 `hermes_tools.fact_store` 不可用，所以触发点用文件队列 `/tmp/dikw_fact_queue/`。

**用户需知**：fact_queue 需主上系统的 fact_store 工具消费。**不**消费也没关系（只是 Holographic 不累积，但本地脚本能用）。

## 历史问题（v3.0）

### ~~v3.0 release 没有专属 assets~~（已修复）

v3.0 release 0 个专属 assets。v3.1 release 会包含专属 zip/docx。

## 报告问题

在 GitHub Issues 报告新问题：
https://github.com/Zhao961215/dikw-v3-universal-template/issues
