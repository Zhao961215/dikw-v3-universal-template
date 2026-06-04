# DIKW v3 + A2 + B + C 部署指南

> **本指南 = 拿到 4 件套后的完整部署流程**
> 适用对象：拿到 4 个目录的 Agent 维护者 / 想在另一台机器上复刻主上系统的用户
> 预计耗时：**~20 分钟**（按主上"轻量化"偏好设计）

---

## 📦 你拿到的 4 个目录

| 目录 | 用途 | 大小 |
|---|---|---|
| `通用版_v3/` | 4 个 .md 文件（README + SOUL + AGENTS + 记忆系统指南）| ~56 KB |
| `本地化覆盖层_v3/a2/` | 3 触发点（apply/verify/diff 累积）| ~22 KB |
| `本地化覆盖层_v3/b/` | 6 主上专有 commit patch + apply/verify 脚本 | ~141 KB |
| `本地化覆盖层_v3/c/` | 5 自研新模块（7.17 MB）+ 4 清单 + apply/verify 脚本 | ~7.3 MB |

---

## 🎯 总览（**5 步部署**）

| 步骤 | 任务 | 风险 | 预计耗时 | 回滚支持 |
|---|---|---|---|---|
| **Step 1** | 应用 A1（静态 overlay）| 低 | 1 分钟 | ✅ 备份在 `.a_range_backup/` |
| **Step 2** | 应用 A2（3 触发点）| 低 | 1 分钟 | — |
| **Step 3** | 应用 B（源码 patch）| **中** | 5 分钟 | ✅ 备份在 `.b_range_backup/` |
| **Step 4** | 应用 C（新模块 + 清单）| **中** | 10 分钟 | ✅ 备份在 `.c_range_backup/` |
| **Step 5** | 启动 DIKW 自增强回路 | 低 | 自动 | — |
| | | | | |
| **总耗时** | | | **~20 分钟** | |

**预期结果**：**~95% 覆盖**（主上系统效果）。30 session 后达无感期。

---

## ✅ 部署前准备

### 必备

```bash
# 1. 检查环境
python3 --version    # 需要 3.10+
git --version        # 任何版本
df -h /              # 需要 50+ MB 可用空间

# 2. 准备 hermes-agent 仓库
#    必须在 origin/main 状态（patches/xiaoming **不**适用）
cd /path/to/hermes-agent
git checkout origin/main
git status            # 应该是 clean tree
```

### 目录结构

```
your_workspace/
├── 通用版_v3/                          # 来自主上的包
│   ├── 00-README.md
│   ├── 01-记忆系统使用指南.md
│   ├── 02-SOUL.md
│   └── 03-AGENTS.md
├── 本地化覆盖层_v3/                    # 来自主上的包
│   ├── a2/
│   ├── b/
│   └── c/
└── hermes-agent/                       # 已 checkout 到 origin/main
```

---

## Step 1: 应用 A1（静态 overlay）

**目标**：把通用版 4 文件复制到 `~/.hermes/`，应用 10 章节 overlay。

```bash
# 1. 复制 4 个 .md 文件
cp 通用版_v3/00-README.md ~/.hermes/
cp 通用版_v3/01-记忆系统使用指南.md ~/.hermes/data/knowledge/vault/00-系统文档/
cp 通用版_v3/02-SOUL.md ~/.hermes/
cp 通用版_v3/03-AGENTS.md ~/.hermes/

# 2. 应用 overlay
bash 本地化覆盖层_v3/apply_localization.sh medium

# 3. 验证
bash 本地化覆盖层_v3/tests/verify_localized.sh
# 期望：看到 "应用成功" 或具体的差异报告
```

**预期输出**：
- `~/.hermes/SOUL.md` 含 10 章节 overlay（包含"小明/主上"专有标识）
- `~/.hermes/AGENTS.md` 含 5 章节 overlay
- 4 触发点 10 章节全部成功追加

**回滚**（如需）：
```bash
ls -t ~/.hermes/.a_range_backup/ | head -1
# 找到最新的备份目录，手动 cp -r 恢复
```

---

## Step 2: 应用 A2（3 触发点）

**目标**：复制 a2/ 目录，让每次跑都自动 fact_store 累积。

```bash
# 1. 复制 a2/ 目录
cp -r 本地化覆盖层_v3/a2/ ~/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/

# 2. 跑 3 个触发点（dry-run 模式）
bash ~/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/a2/triggers/apply_with_fact_store.sh medium
bash ~/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/a2/triggers/verify_with_diff_pattern.sh 5
bash ~/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/a2/triggers/detect_deviation.sh knowledge "示例" "示例" "示例"

# 3. 跑统计
bash ~/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/a2/stats.sh
# 期望：看到 6 条 fact_queue + 4 维度统计 + 距无感期估算
```

**预期输出**：
- `/tmp/dikw_fact_queue/` 有 6+ 个 .json 文件
- stats.sh 报告距无感期还差 N session

---

## Step 3: 应用 B（源码 patch）

**目标**：把 6 个主上专有 commit + 1 uncommitted 应用到 hermes-agent 源码。

```bash
# 1. **默认 dry-run 模式**（先验证能不能应用）
HERMES_HOME=/path/to/hermes-agent \
  bash 本地化覆盖层_v3/b/apply_source_patches.sh

# 期望：6/6 通过（在干净 origin/main 上）

# 2. **实际应用**（明确同意）
HERMES_HOME=/path/to/hermes-agent \
  bash 本地化覆盖层_v3/b/apply_source_patches.sh --apply

# 3. 验证
HERMES_HOME=/path/to/hermes-agent \
  bash 本地化覆盖层_v3/b/verify_source_patches.sh
# 期望：7/7 通过
```

**预期输出**：
- `agent/fact_feedback_loop.py` 存在
- `agent/skill_auto_trigger.py` 存在
- `_inject_vault_duty` 函数在 `agent/tool_executor.py`
- Holographic CJK 2-gram 在 `plugins/memory/holographic/retrieval.py`
- `adaptive_threshold` 参数在 `agent/agent_init.py`
- `vision 1210 retry` 在 `tools/vision_tools.py`

**回滚**（如需）：
```bash
HERMES_HOME=/path/to/hermes-agent \
  bash 本地化覆盖层_v3/b/apply_source_patches.sh --rollback
```

⚠️ **风险提示**：B 范围会动 hermes-agent 源码。**强烈建议**先在测试机器跑通，再到生产机器。

---

## Step 4: 应用 C（新模块 + 清单）

**目标**：复制 5 个自研新模块 + 4 清单。

```bash
# 1. 复制 5 个新模块
cp 本地化覆盖层_v3/c/new_modules/cirAAF_mechanic.py /path/to/hermes-agent/agent/
cp 本地化覆盖层_v3/c/new_modules/cirAAF_mechanic.sh /path/to/hermes-agent/agent/
cp -r 本地化覆盖层_v3/c/new_modules/information_flow /path/to/hermes-agent/agent/
cp -r 本地化覆盖层_v3/c/new_modules/hermes-plugins /path/to/hermes-agent/agent/
cp -r 本地化覆盖层_v3/c/new_modules/wondelai-skills /path/to/hermes-agent/agent/

# 2. 复制清单（skills/tools/cron）
mkdir -p ~/.hermes/c_localization_index
cp 本地化覆盖层_v3/c/skills_inventory/SKILLS.md ~/.hermes/c_localization_index/
cp 本地化覆盖层_v3/c/tools_inventory/TOOLS.md ~/.hermes/c_localization_index/
cp 本地化覆盖层_v3/c/cron_inventory/jobs.json ~/.hermes/cron/

# 3. **或用 apply 脚本**
HERMES_HOME=/path/to/hermes-agent \
  bash 本地化覆盖层_v3/c/apply_new_modules.sh --dry-run
HERMES_HOME=/path/to/hermes-agent \
  bash 本地化覆盖层_v3/c/apply_new_modules.sh --apply

# 4. 验证
HERMES_HOME=/path/to/hermes-agent \
  bash 本地化覆盖层_v3/c/verify_new_modules.sh
# 期望：9/9 通过
```

**预期输出**：
- 5 个新模块在 `agent/` 或 `hermes-agent/` 根目录
- `~/.hermes/c_localization_index/SKILLS.md` + `TOOLS.md`
- `~/.hermes/cron/jobs.json` 含 6 个 cron 任务
- 9/9 验证通过

**回滚**（如需）：
```bash
HERMES_HOME=/path/to/hermes-agent \
  bash 本地化覆盖层_v3/c/apply_new_modules.sh --rollback
```

---

## Step 5: 启动 DIKW 自增强回路

**目标**：让 A2 触发点自动工作，30 session 后达无感期。

```bash
# 1. 确认 fact_queue 目录存在
ls -la /tmp/dikw_fact_queue/

# 2. **关键**：主上系统的 fact_store 工具启动时会自动消费 fact_queue
#    把 /tmp/dikw_fact_queue/*.json 写入 Holographic
#    （这是 Agent 主循环的一部分，不需要手动触发）

# 3. 跑 stats.sh 查看累积进度
bash ~/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/a2/stats.sh

# 4. 每次使用 Agent 后会自动累积
#    - 跑 apply → 触发点 1 写"应用历史"fact
#    - 跑 verify → 触发点 2 写"diff pattern"fact
#    - 发现行为偏差 → 触发点 3 写"运行时偏差"fact
```

**预期输出**：
- 每次使用 Agent 都自动 fact_store
- 30 session 后达到无感期（4 维度都过 60% 阈值）
- 50+ session 后可能超越本地

---

## ✅ 验证清单

部署完成后，**逐项验证**：

- [ ] **Step 1**：`~/.hermes/SOUL.md` 含 10 章节 overlay
- [ ] **Step 1**：`~/.hermes/AGENTS.md` 含 5 章节 overlay
- [ ] **Step 2**：`/tmp/dikw_fact_queue/` 有 6+ 个 .json
- [ ] **Step 2**：`stats.sh` 能跑通，输出 4 维度统计
- [ ] **Step 3**：`hermes-agent/agent/fact_feedback_loop.py` 存在
- [ ] **Step 3**：`hermes-agent/agent/skill_auto_trigger.py` 存在
- [ ] **Step 3**：`hermes-agent/agent/tool_executor.py` 含 `_inject_vault_duty`
- [ ] **Step 3**：`hermes-agent/agent/information_flow/` 存在
- [ ] **Step 4**：`hermes-agent/agent/cirAAF_mechanic.py` 存在
- [ ] **Step 4**：`~/.hermes/c_localization_index/SKILLS.md` 存在
- [ ] **Step 4**：`~/.hermes/cron/jobs.json` 含 6 个 cron

**全部 ✅ = 部署成功**

---

## 🚨 故障排除（5 个常见问题）

### Q1: apply_source_patches.sh 报告"patch 冲突"

**症状**：`[APPLY] ❌ 应用失败`

**原因**：
- hermes-agent 不是干净的 origin/main 状态
- 或者本地已经有部分 patch 被应用过

**修复**：
```bash
cd /path/to/hermes-agent
git status                # 应该有未提交修改
git diff > /tmp/my_uncommitted.patch
git checkout origin/main  # 切回干净 base
# 然后重新跑 apply --apply
```

### Q2: verify_source_patches.sh 报告"0/7 通过"

**症状**：7 个关键检查全失败

**原因**：B 范围 patch 没应用或应用不完整

**修复**：
```bash
# 重新应用 B 范围
HERMES_HOME=/path/to/hermes-agent \
  bash 本地化覆盖层_v3/b/apply_source_patches.sh --apply
```

### Q3: verify_new_modules.sh 报告 "agent.information_flow import 失败"

**症状**：`agent.information_flow` import 错误

**原因**：Python 路径不对，或缺依赖

**修复**：
```bash
# 检查 Python 路径
python3 -c "import sys; print(sys.path)"

# 确认 hermes-agent 在 sys.path
export PYTHONPATH="/path/to/hermes-agent:$PYTHONPATH"
python3 -c "from agent.information_flow import interface"
```

### Q4: stats.sh 报告 "fact_queue 为空"

**症状**：fact_queue 目录 0 条

**原因**：3 个触发点没跑过

**修复**：
```bash
# 跑 3 个触发点
bash ~/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/a2/triggers/apply_with_fact_store.sh
bash ~/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/a2/triggers/verify_with_diff_pattern.sh
bash ~/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/a2/triggers/detect_deviation.sh knowledge "示例" "示例" "示例"

# 重新跑 stats
bash ~/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/a2/stats.sh
```

### Q5: wondelai-skills 6.67 MB 太大

**症状**：wondelai-skills 复制太慢或占空间

**修复**：
```bash
# 跳过 wondelai-skills（可选）
# 只复制前 4 个新模块
cp 本地化覆盖层_v3/c/new_modules/cirAAF_mechanic.py /path/to/hermes-agent/agent/
cp 本地化覆盖层_v3/c/new_modules/cirAAF_mechanic.sh /path/to/hermes-agent/agent/
cp -r 本地化覆盖层_v3/c/new_modules/information_flow /path/to/hermes-agent/agent/
cp -r 本地化覆盖层_v3/c/new_modules/hermes-plugins /path/to/hermes-agent/agent/
# **不复制** wondelai-skills（如果不需要 375 个外部 skills）
```

---

## 📊 部署后预期效果

| 时间 | 阶段 | 体验 |
|---|---|---|
| 0 session | 启动期 | 明显"通用版"感 |
| 5 session | 适应期 | 偶有偏差 |
| **20-50 session** | **无感期** | **感觉不到差异** |
| 50+ session | 超越期 | 比本地更准（个性化累积）|

**数学预期**（基于 fact_8067 + fact_8068）：
- 部署后立即：**~95% 覆盖**（A 静态 71% + B 100% 源码 + C 100% 新模块）
- 30 session 后：**~98% 覆盖**（A2 自增强 +95%）
- 50+ session 后：**可能超越本地**（个性化累积）

---

## 🛡️ 安全说明

- **A1/A2 范围**：默认只追加 overlay，不破坏原文件
- **B 范围**：默认 dry-run，必须 `--apply` 才改
- **C 范围**：默认 dry-run，必须 `--apply` 才复制
- **回滚支持**：A1/B/C 都有自动备份目录
- **审计 6 步**：5 新模块 0 命中敏感词（API key/IP/邮箱）

---

## 📚 关联文档

- A1 README：`../apply_localization.sh` 头部
- A2 README：`本地化覆盖层_v3/a2/README.md`
- B README：`本地化覆盖层_v3/b/README.md`
- C README：`本地化覆盖层_v3/c/README.md`
- 通用版 README：`通用版_v3/00-README.md`

---

## 版本

| 版本 | 时间 | 内容 |
|---|---|---|
| **v1.0** | 2026-06-05 01:30 | 5 步部署 + 验证清单 + 5 故障排除 + 数学预期 |
