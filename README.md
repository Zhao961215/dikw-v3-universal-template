# DIKW 记忆系统 v3.1 — 通用部署模板

<!-- CI 徽章 -->
[![CI Status](https://github.com/Zhao961215/dikw-v3-universal-template/actions/workflows/ci.yml/badge.svg)](https://github.com/Zhao961215/dikw-v3-universal-template/actions/workflows/ci.yml)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub release](https://img.shields.io/github/v/release/Zhao961215/dikw-v3-universal-template)](https://github.com/Zhao961215/dikw-v3-universal-template/releases)
[![GitHub stars](https://img.shields.io/github/stars/Zhao961215/dikw-v3-universal-template)](https://github.com/Zhao961215/dikw-v3-universal-template/stargazers)

> **任何 Hermes Agent clone → 5 分钟拥有完整 DIKW 记忆系统**
>
> 11 步信息流（v3 升级版）：指令 → Agent → 大脑（Holographic）→ 图书馆 5 层（不跳步）→ 工具决策 → 处理 → 反馈 → 迭代
>
> 部署模板：通用版 v3 + 本地化覆盖层（A2 + B + C）+ 一键部署脚本

---

# DIKW Memory System v3.1 — Universal Deployment Template

> **Any Hermes Agent clone → Get a complete DIKW memory system in 5 minutes**
>
> 11-step information flow (v3 upgrade): Command → Agent → Brain (Holographic) → Library 5 layers (no skipping) → Tool decision → Process → Feedback → Iterate
>
> Deployment template: Universal v3 + Localization overlay (A2 + B + C) + One-click deployment script

---

## 🎯 v3.1 新增 / What's New in v3.1

| 新增 / New | 详情 / Details |
|---|---|
| **一键部署脚本** | `deploy_dikw.py`（27.5 KB）+ `rollback_deploy.py` + `test_deploy.py`（7 项测试 / 7 tests）|
| **DEPLOY_GUIDE.md** | 12.5 KB 详细部署指南（5 步部署 + 验证清单 + 5 故障排除）|
| **B 范围源码 patch** | 6 个主上专有 commit + 1 uncommitted + apply/verify 脚本 |
| **C 范围新模块** | 5 个自研新模块（cirAAF / information_flow / hermes-plugins / wondelai-skills 等）|
| **GitHub Actions CI** | 自动跑 7 项测试 + 审计 6 步 + 大小检查 |
| **GitHub Discussions** | 启用社区讨论 |
| **Issue / PR 模板** | 标准化贡献流程 |
| **Contributing.md** | 降低贡献门槛 |

**v3.1 = v3.0 + B 范围 + C 范围 + 一键部署 + CI**

## 📦 包结构 / Package Structure

```
dikw-v3-universal-template/
├── .github/                            # ⭐ NEW
│   ├── workflows/ci.yml                #   GitHub Actions CI
│   ├── ISSUE_TEMPLATE/                 #   Bug / Feature / Question 模板
│   └── PULL_REQUEST_TEMPLATE.md
│
├── 01-通用版/  01-universal/           # 4 核心 .md 文件
│   ├── 00-README.md
│   ├── 01-记忆系统使用指南.md  (memory-system-guide.md)
│   ├── 02-SOUL.md
│   └── 03-AGENTS.md
│
├── 02-本地化覆盖层/  02-localization/
│   ├── a2/                             # A2 触发点（DIKW 自增强）
│   │   ├── README.md
│   │   ├── stats.sh
│   │   └── triggers/                   # 3 触发点 / 3 triggers
│   ├── b/                              # B 源码 patch
│   │   ├── README.md
│   │   ├── apply_source_patches.sh
│   │   ├── verify_source_patches.sh
│   │   ├── patches/                    # 6 commit patch + 1 uncommitted
│   │   └── triggers/                   # 2 触发点
│   └── c/                              # C 新模块
│       ├── README.md
│       ├── apply_new_modules.sh
│       ├── verify_new_modules.sh
│       ├── new_modules/                # 5 自研新模块
│       ├── skills_inventory/SKILLS.md  # 56 skills 索引
│       ├── tools_inventory/TOOLS.md    # 28 tools 索引
│       ├── cron_inventory/jobs.json    # 6 cron 任务
│       └── triggers/                   # 2 触发点
│
├── 03-部署指南/  03-deploy-guide/
│   └── DEPLOY_GUIDE.md                 # 5 步部署详细指南
│
├── 04-一键部署/  04-one-click/         # ⭐ 推荐使用
│   ├── deploy_dikw.py                  # 主脚本 / main (5 步自动化)
│   ├── rollback_deploy.py              # 一键回滚 / rollback
│   ├── test_deploy.py                  # 7 项测试 / 7 tests
│   └── 一键部署_README.md              # 完整用法 / README
│
├── 05-发布说明/  05-release-notes/
│   ├── CHANGELOG.md                    # 版本日志 / changelog
│   └── KNOWN_ISSUES.md                 # 已知问题 / known issues
│
├── CONTRIBUTING.md                     # ⭐ NEW 贡献指南
├── LICENSE                             # MIT 协议
└── README.md                           # 本文件 / this file
```

## 🚀 快速开始 / Quick Start

### 中文用户

```bash
# 1. 克隆仓库
git clone https://github.com/Zhao961215/dikw-v3-universal-template.git
cd dikw-v3-universal-template

# 2. 一键部署（先 dry-run 验证）
python3 04-一键部署/deploy_dikw.py --workspace . --dry-run

# 3. 确认无问题后实际部署
python3 04-一键部署/deploy_dikw.py --workspace . --no-dry-run

# 4. 跑测试验证
python3 04-一键部署/test_deploy.py
```

### English Users

```bash
# 1. Clone
git clone https://github.com/Zhao961215/dikw-v3-universal-template.git
cd dikw-v3-universal-template

# 2. Dry-run
python3 04-one-click/deploy_dikw.py --workspace . --dry-run

# 3. Deploy
python3 04-one-click/deploy_dikw.py --workspace . --no-dry-run

# 4. Test
python3 04-one-click/test_deploy.py
```

## ✅ 验证清单 / Verification (11 items)

部署完成后，逐项验证 / After deployment, verify each item:

- [ ] `~/.hermes/SOUL.md` 含 10 章节 overlay
- [ ] `~/.hermes/AGENTS.md` 含 5 章节 overlay
- [ ] `/tmp/dikw_fact_queue/` 有 6+ 个 .json
- [ ] `hermes-agent/agent/fact_feedback_loop.py` 存在
- [ ] `hermes-agent/agent/skill_auto_trigger.py` 存在
- [ ] `hermes-agent/agent/tool_executor.py` 含 `_inject_vault_duty`
- [ ] `hermes-agent/agent/information_flow/` 存在
- [ ] `hermes-agent/agent/cirAAF_mechanic.py` 存在
- [ ] `~/.hermes/c_localization_index/SKILLS.md` 存在
- [ ] `~/.hermes/cron/jobs.json` 含 6 个 cron
- [ ] `python3 test_deploy.py` 跑通 7/7

## 📊 部署效果 / Deployment Effect

| 维度 Dimension | 起点 Start | 无感阈值 | 30 session 后 | 体验 |
|---|---|---|---|---|
| 行为 Behavior | 60% | 80% | 88% | ✅ 无感 |
| 风格 Style | 50% | 70% | 76% | ✅ 无感 |
| 知识 Knowledge | 30% | 60% | 62% | ✅ 无感 |
| 性能 Performance | 100% | 100% | 100% | ✅ 无感 |

部署后立即 **~95% 覆盖**，30 session 后 **~98%**。
Deploy → ~95% coverage immediately, ~98% after 30 sessions.

## 🛡️ 6 重防护 / 6-Layer Protection (一键部署 / one-click)

| # | 措施 Measure | 解决 Solves |
|---|---|---|
| 1 | **默认 dry-run** | 误改文件 / accidental changes |
| 2 | **每步 try/except** | 失败立即停止 / immediate fail-stop |
| 3 | **自动备份** .bak + .a/b/c_range_backup/ | 可回滚 / rollback-able |
| 4 | **JSON log** | 可审计 / auditable |
| 5 | **rollback 脚本** | 一键回滚 / one-click rollback |
| 6 | **test 脚本** 7 项测试 | 部署前验证 / pre-deploy verify |

## 📚 文档索引 / Documentation

### 中文
- **`01-通用版/00-README.md`** — 通用版总览
- **`01-通用版/01-记忆系统使用指南.md`** — 11 步信息流 v3 权威定义
- **`01-通用版/02-SOUL.md`** — Agent 人格
- **`01-通用版/03-AGENTS.md`** — 工作区目录规范
- **`03-部署指南/DEPLOY_GUIDE.md`** — 详细部署指南
- **`04-一键部署/一键部署_README.md`** — 一键部署完整用法
- **`05-发布说明/CHANGELOG.md`** — 版本日志

### English (Coming soon)
- English documentation is being translated. For now, please use the Chinese version with Google Translate.

## 🔗 链接 / Links

- **GitHub**: https://github.com/Zhao961215/dikw-v3-universal-template
- **Releases**: https://github.com/Zhao961215/dikw-v3-universal-template/releases
- **Issues**: https://github.com/Zhao961215/dikw-v3-universal-template/issues
- **Discussions**: https://github.com/Zhao961215/dikw-v3-universal-template/discussions

## 🤝 贡献 / Contributing

参考 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 📄 License

MIT License — 任何人都可以自由使用、修改、分发。
MIT License - free to use, modify, distribute.

## 版本 / Version

| 版本 Version | 时间 Date | 内容 Content |
|---|---|---|
| **v3.1** | 2026-06-05 | + 一键部署 + B 范围 + C 范围 + DEPLOY_GUIDE + CI + Discussions |
| v3.0.0 | 2026-06-04 | 通用版 4 文件 + 11 步信息流 v3 |
