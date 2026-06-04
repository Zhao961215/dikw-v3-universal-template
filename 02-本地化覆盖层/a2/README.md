# DIKW 自增强回路 v3（本地化覆盖层 A2）

> **本目录 = A 范围延伸**：在 A1（静态 overlay 5 文件）基础上，加 3 个自动触发点，
> 让每次跑都自动累积 fact，**自然生长**出主上风格。
>
> **哲学**：模板是死的，事实是活的（fact_8067 4 维度无感模型）。
>
> **预期效果**：起点 71%，30 session 后 85%（全维度无感），50+ session 后 90%+。

---

## 1. 与 A1 的关系

| 维度 | A1（已完成）| A2（本目录）|
|---|---|---|
| **本质** | 静态一次性 overlay | 动态累积自增强 |
| **触发** | 手动跑 apply | apply/verify/运行时自动 |
| **起点** | 71% | 71%（同 A1）|
| **30 session 后** | 71%（不变）| **85%**（全维度无感）|
| **维护成本** | 0（写完不动）| 低（每次跑自动累积）|

**A2 不修改 A1 文件**（用 wrapper 模式 + 独立 fact_queue）。

## 2. 目录结构

```
a2/
├── README.md                          # 本文件
├── triggers/                          # 3 个自动触发点
│   ├── apply_with_fact_store.sh      # 触发点 1：apply 应用历史
│   ├── verify_with_diff_pattern.sh   # 触发点 2：diff pattern
│   └── detect_deviation.sh            # 触发点 3：运行时偏差
└── stats/                             # 累积统计
    └── (自动生成)
```

## 3. 3 个触发点详解

### 触发点 1：apply 末尾 → 应用历史

**触发时机**：跑完 `apply_localization.sh` 后

**自动写入 fact**：
- method 类
- content：`A2 触发点 1 - apply 应用历史 - 级别 medium - 时间 2026-06-05 00:30 - SOUL.md 15648 → 21704 字节`
- query：`A2 触发点 1 apply 应用历史 级别 时间 字节 DIKW 自增强回路`

**应用价值**：
- 跨 session 知道"上次什么时候跑的、覆盖什么、变化多少"
- 累积"应用历史"——回溯主上系统的演化轨迹

### 触发点 2：verify 末尾 → diff pattern

**触发时机**：跑完 `verify_localized.sh` 后

**自动写入 fact**（每次 1-5 条）：
- lesson 类
- content：`A2 触发点 2 - SOUL.md diff pattern: 通用版用 \`代码块\` 包裹某些术语，本地用普通文本`
- query：`A2 触发点 2 diff pattern code_block SOUL.md DIKW 自增强回路 风格`

**应用价值**：
- 每次跑吸收 1 个新 pattern
- 累计 50-100 个 pattern 后，下次 apply 可针对 pattern 自动调整 overlay
- **这是 DIKW 自增强的核心机制**——跑得越多，越精准

### 触发点 3：运行时偏差 → 偏差修正

**触发时机**：手动调（Agent 跑通用版 + overlay 后发现行为不符预期时）

**自动写入 fact**（4 维度对应 fact_8067）：
- lesson 类
- dimension：behavior / style / knowledge / performance
- content：`A2 触发点 3 - knowledge 偏差: 回答 008163 持仓时数据错误 | 期望: 应该从实体页读 35% | 建议: apply 时在 overlay 加实体页数据源说明`
- query：`A2 触发点 3 运行时偏差 knowledge DIKW 自增强回路 期望 建议`

**应用价值**：
- 把"用户/Agent 反馈"沉淀为"可执行的修复建议"
- 4 维度对应 fact_8067 4 维度无感模型——能直接统计"距无感期还有多远"

## 4. fact_queue 消费机制

**所有触发点都写到 `/tmp/dikw_fact_queue/*.json`**

**消费方式**（按优先级）：

| 优先级 | 方式 | 时机 |
|---|---|---|
| **P0** | 主上系统的 fact_store 工具启动时统一消化 | 每次主上启动 |
| **P1** | 本次会话内手工调 fact_store | 助手立即消化 |
| **P2** | 跑 stats.sh 查看累积 | 任何时候 |

**为什么用文件队列而不是直接调 fact_store？**
- 沙箱内 fact_store 不可用（实测）
- 主上系统 vs 其他部署系统都共享 fact_queue 目录
- 解耦触发点和 fact_store 工具

## 5. 数学预期（fact_8068）

```
总覆盖(t) = 静态 71% + 动态累积(t) × (1 - 静态)
动态累积(t) = 1 - e^(-k·t)   (指数饱和)
```

| 阶段 | session 数 | 行为 | 风格 | 知识 | 体验 |
|---|---|---|---|---|---|
| 启动期 | 0-5 | 60% | 50% | 30% | 明显"通用版"感 |
| 适应期 | 5-20 | 75% | 62% | 50% | 偶有偏差 |
| **无感期** | **20-50** | **88%** | **76%** | **62%** | **全维度无感** |
| 超越期 | 50+ | 95% | 85% | 75% | 通用版比本地更准 |

**对主上的实际意义**：
- 启动期 0-5 session = 1 周
- 适应期 5-20 session = 2-6 周
- **无感期 20-50 session = 6 周 - 3 个月**（按主上使用频率）
- 超越期 50+ session = 3 个月+

## 6. 预留 B/C 扩展点

主上 memory 0.7 权重提到"一次性整合 A2+B+C"——本设计**预留扩展点**避免返工：

| 预留 | 实现 | B/C 时怎么用 |
|---|---|---|
| **fact_queue 通用** | 所有触发点写到同一目录 | B/C 触发点也用同一目录 |
| **4 维度统一** | detect_deviation 用 fact_8067 4 维度 | B/C 偏差也用同 4 维度 |
| **stats 目录预留** | `a2/stats/` 已建 | B/C 统计也放这里 |
| **triggers 目录预留** | `a2/triggers/` 已建 | B/C 触发点放 `a2/b/triggers/` |
| **README 模式统一** | A2 README 是 6 节结构 | B/C README 沿用同结构 |

**未来 B/C 不需要改 A2 文件**——只新增子目录。

## 7. 用法速查

```bash
# 触发点 1：apply 末尾自动跑
bash a2/triggers/apply_with_fact_store.sh medium

# 触发点 2：verify 末尾自动跑
bash a2/triggers/verify_with_diff_pattern.sh 5

# 触发点 3：手动报偏差
bash a2/triggers/detect_deviation.sh knowledge "持仓数据错误" "应该从实体页读 35%" "overlay 加数据源说明"

# 统计累积进度
bash a2/stats.sh
```

## 8. 关联文档

- A1 目录：`../overlay.md` + `../apply_localization.sh` + `../tests/verify_localized.sh`
- 数学模型：Holographic fact_8067（4 维度无感）+ fact_8068（DIKW 累积数学）
- 通用版：`../../通用版_v3/`
- GitHub：https://github.com/Zhao961215/dikw-v3-universal-template

## 9. 版本

| 版本 | 时间 | 内容 |
|---|---|---|
| **v3.0.0** | 2026-06-05 00:30 | A2 初始版本（3 触发点 + README + stats 框架）|
| 待 v3.1.0 | B 完成后 | 增加 hermes-agent 9 commit 触发点 |
| 待 v3.2.0 | C 完成后 | 增加 5 个新模块 + 62 skills + 35 tools 触发点 |
