# DIKW v3 一键自动化部署（Python）

> **本目录 = 一键部署脚本**
> 把 4 件套（通用版 v3 + A2 + B + C）按 DEPLOY_GUIDE.md 5 步**自动**部署完毕。
> **任何 agent 跑都得到同样结果**（幂等性 + 默认 dry-run + 自动 rollback）。

---

## 🎯 解决什么问题

**主上痛点**：
- 不同 agent 能力不一样 → 执行效果不稳定
- 不同 shell 行为不一样 → 跨平台不兼容
- 手动 5 步容易漏 → 没有审计 log

**本脚本的优势**：
- ✅ **Python 3**（不是 shell，跨平台一致）
- ✅ **默认 dry-run**（必须 `--no-dry-run` 才实际改）
- ✅ **每步 try/except**（失败立即停止 + 提示 rollback）
- ✅ **JSON log**（可审计）
- ✅ **幂等性**（多次跑结果一致）
- ✅ **回滚支持**（一键 rollback）
- ✅ **测试脚本**（test_deploy.py 7 项测试）

---

## 📦 4 个脚本

| 脚本 | 大小 | 用途 |
|---|---|---|
| `deploy_dikw.py` | 25.9 KB | **主脚本**：5 步自动化部署 |
| `rollback_deploy.py` | 6.9 KB | 回滚（用最近的 .bak 恢复）|
| `test_deploy.py` | 7.4 KB | 7 项测试（验证 deploy/rollback 可用）|
| `DEPLOY_GUIDE.md` | 12.5 KB | 详细部署指南（给人看）|

---

## 🚀 快速开始

### 第一次使用（先 dry-run 看效果）

```bash
# 1. 准备 4 个目录（4 件套）
ls /path/to/your_workspace/
#   通用版_v3/
#   本地化覆盖层_v3/

# 2. dry-run 模式（不实际改任何东西）
python3 /path/to/deploy_dikw.py \
  --workspace /path/to/your_workspace \
  --dry-run

# 期望：5 步 dry-run 全部成功
```

### 实际部署

```bash
python3 /path/to/deploy_dikw.py \
  --workspace /path/to/your_workspace \
  --no-dry-run
```

### 自定义 hermes-agent 路径

```bash
python3 /path/to/deploy_dikw.py \
  --workspace /path/to/your_workspace \
  --hermes-src /custom/path/hermes-agent \
  --no-dry-run
```

### 只跑某些 step

```bash
# 只跑 Step 1 + 2（A1 + A2）
python3 /path/to/deploy_dikw.py \
  --workspace /path/to/your_workspace \
  --only-step 1,2 \
  --no-dry-run
```

### 跳过某些 step

```bash
# 跳过 Step 3 + 4（B + C）
python3 /path/to/deploy_dikw.py \
  --workspace /path/to/your_workspace \
  --skip-step 3,4 \
  --no-dry-run
```

### 查看状态

```bash
python3 /path/to/deploy_dikw.py \
  --workspace /path/to/your_workspace \
  --status
```

### 回滚

```bash
python3 /path/to/rollback_deploy.py
```

### 跑测试

```bash
python3 /path/to/test_deploy.py
```

---

## 📊 5 步部署详解

| Step | 任务 | 关键操作 | 风险 | dry-run 时长 | 实际时长 |
|---|---|---|---|---|---|
| 1 | A1（静态 overlay）| 复制 4 .md + 跑 apply_localization.sh | 低 | < 5s | < 10s |
| 2 | A2（3 触发点）| 复制 a2/ + 跑 3 触发点 + stats | 低 | < 5s | < 10s |
| 3 | B（源码 patch）| dry-run apply + --apply + verify | **中** | < 5s | < 30s |
| 4 | C（新模块 + 清单）| 复制 5 新模块 + 4 清单 + verify | **中** | < 5s | < 60s |
| 5 | 启动 DIKW 自增强 | 跑 stats.sh + 验证 fact_queue | 低 | < 5s | < 5s |
| | | | | | |
| **总计** | | | | **< 25s** | **~2 分钟** |

---

## 🛡️ 安全设计（6 重防护）

| # | 措施 | 描述 |
|---|---|---|
| 1 | **默认 dry-run** | 不传 `--no-dry-run` 绝不实际改 |
| 2 | **每步 try/except** | 失败立即停止 + 详细错误信息 |
| 3 | **自动备份** | 每个文件 .bak-时间戳 + 3 个备份目录 |
| 4 | **JSON log** | `deploy_logs/deploy_YYYYMMDD_HHMMSS.json` |
| 5 | **rollback 脚本** | 一键回滚（用最近的 .bak）|
| 6 | **测试脚本** | 7 项测试验证 deploy/rollback 可用 |

---

## 📁 部署后文件结构

```
~/.hermes/
├── 00-README.md                                    (新增, A1)
├── 02-SOUL.md                                      (新增, A1)
├── 03-AGENTS.md                                    (新增, A1)
├── data/knowledge/vault/00-系统文档/
│   ├── 01-记忆系统使用指南.md                       (新增, A1)
│   └── 本地化覆盖层_v3/
│       └── a2/                                     (新增, A2)
├── c_localization_index/                           (新增, C)
│   ├── SKILLS.md
│   └── TOOLS.md
└── cron/
    └── jobs.json                                   (新增, C)

hermes-agent/
├── agent/
│   ├── cirAAF_mechanic.py                          (新增, C)
│   ├── cirAAF_mechanic.sh                          (新增, C)
│   ├── information_flow/                           (新增, C)
│   ├── fact_feedback_loop.py                       (新增, B)
│   ├── skill_auto_trigger.py                       (新增, B)
│   └── tool_executor.py                            (修改, B)
├── hermes-plugins/                                 (新增, C)
└── wondelai-skills/                                (新增, C)
```

---

## 📊 log 文件格式（JSON）

```json
[
  {
    "timestamp": "2026-06-05T01:30:00",
    "step": "Step 1.1: 复制 00-README.md",
    "status": "success",
    "details": "→ /home/zhao/.hermes/00-README.md (备份: /home/zhao/.hermes/00-README.md.bak-20260605_013000)",
    "dry_run": false
  },
  {
    "timestamp": "2026-06-05T01:30:01",
    "step": "Step 1.2: apply_localization",
    "status": "success",
    "details": "10 章节 overlay 已应用",
    "dry_run": false
  },
  ...
]
```

位置：`{workspace}/deploy_logs/deploy_YYYYMMDD_HHMMSS.json`

---

## 🧪 测试覆盖

test_deploy.py 跑 7 项测试：

1. ✅ 工作目录存在
2. ✅ 4 个核心目录都存在
3. ✅ Python 脚本语法
4. ✅ dry-run 模式跑通
5. ✅ --status 模式跑通
6. ✅ rollback --dry-run 跑通
7. ✅ --help 输出正常

跑测试：
```bash
python3 /path/to/test_deploy.py
```

期望：`通过: 7/7`

---

## 🚨 故障排除

### Q1: deploy_dikw.py 报告"Python 版本不兼容"

**症状**：`SyntaxError` 或 `ImportError`

**修复**：
```bash
python3 --version  # 需要 3.10+
# 如果 < 3.10，升级 Python 或用 python3.10+
```

### Q2: deploy_dikw.py 报告"通用版目录不存在"

**症状**：`FileNotFoundError: 通用版_v3 不存在`

**修复**：
```bash
# 检查 --workspace 路径
ls /path/to/your_workspace/通用版_v3/
# 必须有 00-README.md / 01-记忆系统使用指南.md / 02-SOUL.md / 03-AGENTS.md 4 个文件
```

### Q3: deploy_dikw.py 报告"hermes-agent 不存在"

**症状**：`FileNotFoundError: hermes-agent 源码目录不存在`

**修复**：
```bash
# 1. 检查 hermes-agent 路径
ls ~/.hermes/hermes-agent/

# 2. 如果不存在，用 --hermes-src 指定
python3 deploy_dikw.py --hermes-src /custom/path/hermes-agent
```

### Q4: 部署后 fact_queue 是空的

**症状**：`stats.sh` 报告 0 条

**修复**：
```bash
# 跑 A2 触发点
bash ~/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/a2/triggers/apply_with_fact_store.sh medium
bash ~/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/a2/triggers/verify_with_diff_pattern.sh 5
bash ~/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/a2/triggers/detect_deviation.sh knowledge "示例" "示例" "示例"

# 重新跑 stats
bash ~/.hermes/data/knowledge/vault/00-系统文档/本地化覆盖层_v3/a2/stats.sh
```

### Q5: rollback 找不到 .bak

**症状**：`无 .bak 文件，无法自动回滚`

**修复**：
```bash
# 1. 检查 .bak 文件
find ~/.hermes -name "*.bak-*" 2>/dev/null

# 2. 如果没有，可能是 deploy 没备份就改了
#    这种情况下，git checkout 是唯一办法
cd /path/to/hermes-agent
git status  # 找改动文件
git checkout <file>  # 恢复
```

---

## 📊 部署后预期效果

| 时间 | 阶段 | 体验 | 覆盖 |
|---|---|---|---|
| 0 session | 启动期 | 明显"通用版"感 | ~75% |
| 5 session | 适应期 | 偶有偏差 | ~85% |
| **20-50 session** | **无感期** | **感觉不到差异** | **~95%** |
| 50+ session | 超越期 | 比本地更准 | ~98% |

---

## 📚 关联文档

- DEPLOY_GUIDE.md：详细部署指南（给人看）
- A1/A2/B/C README：各范围详细说明
- 通用版 00-README.md：通用版总览
- GitHub：https://github.com/Zhao961215/dikw-v3-universal-template

---

## 版本

| 版本 | 时间 | 内容 |
|---|---|---|
| **v1.0.0** | 2026-06-05 01:30 | 4 脚本（deploy/rollback/test + README）+ 7 项测试 + 6 重防护 |
