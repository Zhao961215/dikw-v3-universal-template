# DIKW 记忆系统 v3.1 — 通用部署模板

> **任何 Hermes Agent clone 替换占位符 → 5 分钟拥有完整 DIKW 记忆系统**
> 
> 11 步信息流（v3 升级版）：指令 → Agent → 大脑（Holographic）→ 图书馆 5 层（不跳步）→ 工具决策 → 处理 → 反馈 → 迭代
> 
> 部署模板：通用版 v3 + 本地化覆盖层（A2 + B + C）+ 一键部署脚本

## 🎯 v3.1 新增内容

相比 v3.0.0：

| 新增 | 详情 |
|---|---|
| **一键部署脚本** | `deploy_dikw.py`（27.5 KB）+ `rollback_deploy.py` + `test_deploy.py`（7 项测试）|
| **DEPLOY_GUIDE.md** | 12.5 KB 详细部署指南（5 步部署 + 验证清单 + 5 故障排除）|
| **B 范围源码 patch** | 6 个主上专有 commit + 1 uncommitted + apply/verify 脚本 |
| **C 范围新模块** | 5 个自研新模块（cirAAF / information_flow / hermes-plugins / wondelai-skills 等）|

**v3.1 = v3.0 + B 范围 + C 范围 + 一键部署**

## 📦 包结构

```
dikw-v3-universal-template/
├── 01-通用版/                              # 4 个核心 .md 文件
│   ├── 00-README.md
│   ├── 01-记忆系统使用指南.md              # 11 步信息流 v3
│   ├── 02-SOUL.md                          # Agent 人格定义
│   └── 03-AGENTS.md                        # 工作区目录规范
│
├── 02-本地化覆盖层/                        # 个性化定制（按需使用）
│   ├── a2/                                 # A2 触发点（DIKW 自增强）
│   │   ├── README.md
│   │   ├── stats.sh
│   │   └── triggers/                       # 3 触发点
│   ├── b/                                  # B 源码 patch
│   │   ├── README.md
│   │   ├── apply_source_patches.sh
│   │   ├── verify_source_patches.sh
│   │   ├── patches/                        # 6 commit patch + 1 uncommitted
│   │   └── triggers/                       # 2 触发点
│   └── c/                                  # C 新模块
│       ├── README.md
│       ├── apply_new_modules.sh
│       ├── verify_new_modules.sh
│       ├── new_modules/                    # 5 自研新模块（见清单）
│       ├── skills_inventory/SKILLS.md      # 56 skills 索引
│       ├── tools_inventory/TOOLS.md        # 28 tools 索引
│       ├── cron_inventory/jobs.json        # 6 cron 任务
│       └── triggers/                       # 2 触发点
│
├── 03-部署指南/
│   └── DEPLOY_GUIDE.md                     # 5 步部署详细指南
│
├── 04-一键部署/                            # ⭐ 推荐使用
│   ├── deploy_dikw.py                      # 主脚本（5 步自动化）
│   ├── rollback_deploy.py                  # 一键回滚
│   ├── test_deploy.py                      # 7 项测试
│   └── 一键部署_README.md                  # 完整用法
│
├── 05-发布说明/
│   ├── CHANGELOG.md                        # 版本日志
│   └── KNOWN_ISSUES.md                     # 已知问题
│
├── LICENSE                                 # MIT 协议
└── README.md                               # 本文件
```

## 🚀 快速开始（推荐）

### 1. 一键部署（最简单）

```bash
# 克隆仓库
git clone https://github.com/Zhao961215/dikw-v3-universal-template.git
cd dikw-v3-universal-template

# 一键部署（先 dry-run 验证）
python3 04-一键部署/deploy_dikw.py --workspace . --dry-run

# 确认无问题后实际部署
python3 04-一键部署/deploy_dikw.py --workspace . --no-dry-run

# 跑测试验证
python3 04-一键部署/test_deploy.py
```

### 2. 手动部署

参考 `03-部署指南/DEPLOY_GUIDE.md`（5 步 + 验证清单 + 故障排除）。

## ✅ 验证清单（11 项）

部署完成后，逐项验证：

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

## 📊 部署效果（数学预期）

| 维度 | 起点 | 无感阈值 | 30 session 后 | 体验 |
|---|---|---|---|---|
| 行为 | 60% | 80% | 88% | ✅ 无感 |
| 风格 | 50% | 70% | 76% | ✅ 无感 |
| 知识 | 30% | 60% | 62% | ✅ 无感 |
| 性能 | 100% | 100% | 100% | ✅ 无感 |

部署后立即 **~95% 覆盖**（A 静态 71% + B 100% 源码 + C 100% 新模块），30 session 后 **~98%**。

## 🛡️ 6 重防护（一键部署）

| # | 措施 | 解决什么 |
|---|---|---|
| 1 | **默认 dry-run** | 误改文件 |
| 2 | **每步 try/except** | 失败立即停止 |
| 3 | **自动备份**（.bak + .a/b/c_range_backup/）| 可回滚 |
| 4 | **JSON log** | 可审计 |
| 5 | **rollback 脚本** | 一键回滚 |
| 6 | **test 脚本**（7 项测试）| 部署前验证 |

## 📚 文档索引

- **`01-通用版/00-README.md`** — 通用版总览
- **`01-通用版/01-记忆系统使用指南.md`** — 11 步信息流 v3 权威定义
- **`01-通用版/02-SOUL.md`** — Agent 人格（5 角色框架 + 思维协议 + 铁律）
- **`01-通用版/03-AGENTS.md`** — 工作区目录规范
- **`03-部署指南/DEPLOY_GUIDE.md`** — 详细部署指南
- **`04-一键部署/一键部署_README.md`** — 一键部署完整用法
- **`05-发布说明/CHANGELOG.md`** — 版本日志
- **`05-发布说明/KNOWN_ISSUES.md`** — 已知问题

## 🔗 链接

- **GitHub**: https://github.com/Zhao961215/dikw-v3-universal-template
- **Issues**: https://github.com/Zhao961215/dikw-v3-universal-template/issues
- **Releases**: https://github.com/Zhao961215/dikw-v3-universal-template/releases

## 📄 License

MIT License — 任何人都可以自由使用、修改、分发。

## 版本

| 版本 | 时间 | 内容 |
|---|---|---|
| **v3.1** | 2026-06-05 | + 一键部署 + B 范围 + C 范围 + DEPLOY_GUIDE |
| v3.0.0 | 2026-06-04 | 通用版 4 文件 + 11 步信息流 v3 |
