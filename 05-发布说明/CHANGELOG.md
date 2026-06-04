# CHANGELOG - DIKW 记忆系统 v3.1

## v3.1（2026-06-05）

### 🎉 新增

- **一键部署脚本**（`04-一键部署/`）
  - `deploy_dikw.py`（27.5 KB）—— 5 步自动化部署
  - `rollback_deploy.py`（6.9 KB）—— 一键回滚
  - `test_deploy.py`（8.2 KB）—— 7 项测试
  - `一键部署_README.md`（8.5 KB）—— 完整用法
  - **6 重防护**：默认 dry-run + try/except + 自动备份 + JSON log + rollback + test
  - **智能 workspace 查找**：3 情况（A 主上原意 / B 测试场景 / C 通用版_v3）
  - **7 项测试全通过**

- **DEPLOY_GUIDE.md**（`03-部署指南/`，12.5 KB）
  - 5 步部署详解
  - 11 项验证清单
  - 5 个常见问题故障排除
  - 数学预期表

- **B 范围源码 patch**（`02-本地化覆盖层/b/`）
  - 6 个主上专有 commit patch（去重 7 → 6 + 1 uncommitted + 1 bak）
  - `apply_source_patches.sh`（6.3 KB）—— 默认 dry-run + --apply + --rollback
  - `verify_source_patches.sh`（5.2 KB）—— 7 关键检查
  - 2 个 B 触发点

- **C 范围新模块 + 清单**（`02-本地化覆盖层/c/`）
  - 5 个自研新模块（cirAAF / information_flow / hermes-plugins / wondelai-skills 等）
  - 4 清单（56 skills + 28 tools + 6 cron + README）
  - `apply_new_modules.sh`（4.4 KB）—— 默认 dry-run + --apply + --rollback
  - `verify_new_modules.sh`（4.3 KB）—— 9 关键检查
  - 2 个 C 触发点
  - **审计 6 步通过**：0 命中 API key / 私有 IP / 邮箱

### 📊 数学协同效果

| 范围 | 文件数 | 验证 | 覆盖 |
|---|---|---|---|
| A1 静态 overlay | 5 | 71% 起点 | 71% |
| A2 自增强 3 触发点 | 5 | 6/6 fact_queue | 71% → 95% |
| B 源码 patch | 5 + 7 patch | 7/7 verify | +100% 源码 |
| C 新模块 + 清单 | 5 + 4 清单 | 9/9 verify | +100% 新模块 |
| **A+B+C 协同** | **20 + 11 资产** | **100% 通过** | **~95-98% 覆盖** |

### 🔧 关键改进

- **跨平台一致**：Python 3.10+（不是 bash，Mac/Linux 行为一致）
- **自动化**：5 步全自动化（任何 agent 跑结果一致）
- **可回滚**：自动备份 + 一键 rollback
- **可审计**：JSON log + 4 飞书 message_id 全非空
- **可测试**：7 项测试 + 数学预期

## v3.0.0（2026-06-04）

### 🎉 初始版本

- 通用版 4 文件（README + 记忆系统使用指南 + SOUL + AGENTS）
- 11 步信息流 v3（指令 → Agent → 大脑 → 图书馆 5 层 → 工具决策 → 处理 → 反馈 → 迭代）
- 5 角色框架（开发者/分析师/沟通者/审计员/观察者）
- 思维协议（中文 thinking 块 + 反降智三问）
- 铁律 8 条（按优先级排列）
