# 自研新模块 + skills/tools/cron 本地化（C 范围）

> **本目录 = C 范围**：在 A1（静态 overlay）+ A2（3 触发点）+ B（源码层 patch）基础上，
> 加自研新模块 + skills/tools/cron 本地化清单。
>
> **范围**：**5 个新模块**（7.17 MB）+ **56 skills 清单** + **28 tools 清单** + **6 cron**。
>
> **安全设计**：默认 dry-run，skills/tools/cron **只抽清单不抽实际文件**（避免 8+ MB）。

---

## 1. 与 A1/A2/B 的关系

| 维度 | A1 | A2 | B | C（本目录）|
|---|---|---|---|---|
| **本质** | 静态 overlay | 动态自增强 | 源码 patch | 新模块 + 清单 |
| **范围** | 4 .md 文件 | 5 触发点 | 6 commit + 1 uncommitted | 5 新模块 + 4 清单 |
| **100% 还原** | ❌ 71% | ❌ 71-95% | ✅ 100%（应用 patch）| ✅ 100%（应用新模块）|
| **风险** | 低 | 低 | 中-高 | 中 |

**C 的本质**：A 范围补"文档层"，B 范围补"源码层"，C 范围补"自研模块 + 系统配置"。

## 2. 严格边界（**关键**）

| ✅ 属于 C | ❌ 不属于 C |
|---|---|
| 5 个新模块（未跟踪目录）| A 范围 4 .md |
| 56 skills 清单（不抽实际文件）| B 范围 6 commit patch |
| 28 tools 清单（不抽实际文件）| 通用版 4 文件 |
| 6 cron（jobs.json 53 KB）| MEMORY.md / USER.md / config.yaml |

**为什么不抽 skills/tools 实际文件**：
- 56 skills + 28 tools = 几 MB（占 70%）
- skills 大多是**主上自研**（其他 Agent 不一定需要）
- 实际**清单**就够——按需 git clone 或手动同步

## 3. 5 个新模块详解

| # | 名称 | 大小 | 文件数 | 作用 |
|---|---|---|---|---|
| 1 | `cirAAF_mechanic.py` | 45.5 KB | 1 | CIRAAF 大脑整理引擎 v2.3（Layer 1 锚 + Layer 2 子聚类）|
| 2 | `cirAAF_mechanic.sh` | 2.1 KB | 1 | CIRAAF 启动脚本（cron 调用）|
| 3 | `information_flow/` | 114.2 KB | 9 | 11 步信息流 v3 升级版（HRR + CJK 2-gram + _finalize 闭环）|
| 4 | `hermes-plugins/` | 439.6 KB | 102 | Hermes 插件集（holographic / memory / feishu 等）|
| 5 | `wondelai-skills/` | 6.67 MB | 375 | 外部 skills（domin / business / 投资 / 等）|
| **合计** | | **7.17 MB** | **488** | |

**审计 6 步结果**（事实）：
- ✅ **0 命中**用户223475 / sk-I9l / fda9d40e（API key 前缀）
- ✅ **0 命中**192.168.3.170（主上 NAS IP）
- ✅ 注释里的"主上原话"是引用说明，**不是**硬编码
- ✅ 全部清洁，可以打包

## 4. 4 清单详解

| 清单 | 路径 | 大小 | 用途 |
|---|---|---|---|
| **SKILLS.md** | `c/skills_inventory/` | ~5 KB | 56 个 skills 索引（按目录名 + 大小）|
| **TOOLS.md** | `c/tools_inventory/` | ~2 KB | 28 个 .py 工具索引 |
| **jobs.json** | `c/cron_inventory/` | 53 KB | 6 个 cron 任务完整定义 |
| **新模块目录** | `c/new_modules/` | 7.17 MB | 5 个新模块实际文件 |

**SKILLS.md 示例**：
```
1. research  (36.5 KB)
2. path-compliance  (17.3 KB)
3. etf-weighted-pe-calc  (9.1 KB)
...
56. (最后一个)
```

## 5. 目录结构

```
c/
├── README.md                          # 本文件
├── new_modules/                       # 5 个新模块（7.17 MB）
│   ├── cirAAF_mechanic.py
│   ├── cirAAF_mechanic.sh
│   ├── information_flow/
│   ├── hermes-plugins/
│   └── wondelai-skills/
├── skills_inventory/
│   └── SKILLS.md                      # 56 skills 索引
├── tools_inventory/
│   └── TOOLS.md                       # 28 tools 索引
├── cron_inventory/
│   └── jobs.json                      # 6 cron 任务
├── apply_new_modules.sh               # C 范围应用脚本
├── verify_new_modules.sh              # C 范围验证脚本
└── triggers/                          # 2 个 C 触发点
    ├── apply_new_modules_with_fact_store.sh
    └── verify_new_modules_with_fact_store.sh
```

## 6. 用法

```bash
# 默认 dry-run
bash c/apply_new_modules.sh

# 实际应用
bash c/apply_new_modules.sh --apply

# 验证
bash c/verify_new_modules.sh

# 回滚（用最近的 .c_range_backup/）
bash c/apply_new_modules.sh --rollback
```

## 7. 安全设计（按 P0 + 主上硬底线）

| 措施 | 描述 |
|---|---|
| **默认 dry-run** | 不传 `--apply` **绝不**改文件 |
| **自动备份** | `--apply` 自动 `.c_range_backup/$TIMESTAMP/` |
| **回滚支持** | `--rollback` 用最近备份恢复 |
| **清单 + 模块分离** | skills/tools 只抽清单（避免 8+ MB）|
| **触发点事实队列** | apply/verify 自动 fact_store |

## 8. 数学预期（A2 + B + C 完整协同）

| 阶段 | session | A 静态 | A2 自增强 | B 源码 | C 新模块 | 总覆盖 |
|---|---|---|---|---|---|---|
| 启动期 | 0-5 | 71% | + 累积 | ✅ 已应用 | ✅ 已应用 | **~90%** |
| 适应期 | 5-20 | 71% | + 累积 | ✅ | ✅ | **~93%** |
| **无感期** | **20-50** | **71%** | **+ 累积** | **✅** | **✅** | **~95%** |
| 超越期 | 50+ | 71% | + 累积 | ✅ | ✅ | **~98%** |

**A2 + B + C 完整版 100% 还原本地**（除少量专有数据 MEMORY.md/USER.md）。

## 9. 预留 D 扩展点（**可选**）

| 预留 | 实现 | D 时怎么用 |
|---|---|---|
| 触发点 3 模式 | 暂无运行时偏差触发点 | D 触发点 3 用同 4 维度 |
| fact_queue 通用 | 同一目录 | D 触发点写到同一目录 |
| 验证脚本模式 | 7 关键检查 + 5 关键检查 | D 验证脚本用同模式 |
| 4 维度统一 | 暂无 | D 用同 4 维度 |

**未来 D 不改 C 文件**——只新增 `d/` 子目录。

## 10. 关联文档

- A1 目录：`../overlay.md` + `../apply_localization.sh`
- A2 目录：`../a2/`
- B 目录：`../b/`
- 通用版：`../../通用版_v3/`
- GitHub：https://github.com/Zhao961215/dikw-v3-universal-template

## 11. 版本

| 版本 | 时间 | 内容 |
|---|---|---|
| **v3.0.0** | 2026-06-05 01:30 | C 初始版本（5 新模块 + 4 清单 + apply/verify + 2 触发点）|
| 待 v3.1.0 | D 完成后（如有）| 增加 cron 6 任务实际配置同步 |
