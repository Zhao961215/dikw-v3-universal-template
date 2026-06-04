# 源码层本地化 v3（B 范围）

> **本目录 = B 范围**：在 A1（静态 overlay）+ A2（3 触发点）基础上，加源码层 patch 应用。
> 
> **范围严格**：**只打包 6 个主上专有 commit + 1 个 uncommitted 修改**。
> 上游 merge（v0.15.2 / packaging / knowledge-usage）**不打包**。
> 
> **安全设计**：默认 dry-run（不实际改文件），`--apply` 才改。

---

## 1. 与 A1/A2 的关系

| 维度 | A1（已完成）| A2（已完成）| B（本目录）|
|---|---|---|---|
| **本质** | 静态一次性 overlay | 动态累积自增强 | 源码层 patch |
| **触发** | 手动跑 apply | apply/verify/运行时自动 | 手动 apply（带 dry-run）|
| **起点** | 71% | 71% | 71% + 源码层 |
| **100% 还原本地** | ❌ | ❌ | ✅（应用 patch 后）|
| **风险** | 低 | 低 | **中-高**（动源码）|

**B 的本质**：A 范围覆盖"文档层"（71%），B 范围覆盖"源码层"（补到 100%）。

## 2. 严格边界（**关键**）

| ✅ 属于 B | ❌ 属于 C（留待主上确认）|
|---|---|
| 6 个主上专有 commit diff | 5 个新模块（未跟踪目录）|
| 1 个 uncommitted 修改（send_message_tool.py）| 5 个新模块的所有 .py 文件 |
| 1 个 bak 文件（参考用）| |
| 上游 merge commit（v0.15.2 等）| ❌ **不打包**（不是主上专有）|

**为什么不打上游 merge commit**：
- 上游 commit 已在 origin/main 上（其他 Agent clone 通用版时**自动**有）
- 重复打包 = 浪费空间
- 上游 commit **不是**主上专有 = 不应属于 B 范围

## 3. 目录结构

```
b/
├── README.md                          # 本文件
├── patches/                           # 7 个 patch 文件
│   ├── 00-tools-send_message_tool.py.bak-20260603    (77,971 字节，参考)
│   ├── 00-uncommitted-tools-send_message_tool.py.diff   (838 字节)
│   ├── 01-f42e8b986.patch             (4,194 字节，vision 1210 retry)
│   ├── 02-f46cdc7ef.patch             (34,926 字节，xiaoming-custom-patches: holographic-cjk 等 6 个)
│   ├── 03-a79a94581.patch             (6,812 字节，auto-trigger skills)
│   ├── 04-b6fd149d2.patch             (15,469 字节，fact_feedback_loop)
│   └── 05-cafff3c4b.patch             (4,170 字节，inject DIKW vault-write duty)
├── apply_source_patches.sh            # B 范围应用脚本
├── verify_source_patches.sh           # B 范围验证脚本
└── triggers/                          # 2 个 B 触发点
    ├── apply_source_patches_with_fact_store.sh
    └── verify_source_patches_with_fact_store.sh
```

## 4. 6 个主上专有 commit 详解

| # | hash | 内容 | 影响 |
|---|---|---|---|
| 1 | `f42e8b98` | fix(vision): auto-retry without temperature/max_tokens/timeout on upstream 1210 | vision 工具 1210 错误自动重试 |
| 2 | `f46cdc7e` | xiaoming-custom-patches: holographic-cjk, adaptive-threshold, feishu-card, siliconflow-stt, vision-1210-retry, voice-log | **6 个本地化**（holographic CJK 分词 + 压缩阈值自适应 + 飞书卡片 + 语音 STT/TTS 等）|
| 3 | `a79a9458` | feat: auto-trigger skills by keyword match in user message | skill 自动触发（按 keywords 匹配）|
| 4 | `b6fd149` | feat: add fact_feedback_loop.py — auto calibrate Holographic trust scores | fact 信任分自动校准 cron |
| 5 | `cafff3c4` | source: inject DIKW vault-write duty after every write_file to vault path | DIKW vault-write 强制提炼钩子 |

**5 个 commit + 1 个 uncommitted = 6 个独立 patch 文件**（03 merge commit 重复 02，已去重）

## 5. 用法

```bash
# 默认：dry-run 模式（**不实际改**）
bash b/apply_source_patches.sh

# 实际应用（明确同意）
bash b/apply_source_patches.sh --apply

# 自定义源码目录
bash b/apply_source_patches.sh --src /path/to/hermes-agent

# 验证
bash b/verify_source_patches.sh

# 回滚（用最近的 .b_range_backup/）
bash b/apply_source_patches.sh --rollback
```

## 6. 安全设计（按 P0 + 主上硬底线）

| 措施 | 描述 |
|---|---|
| **默认 dry-run** | 不传 `--apply` **绝不**改文件 |
| **自动备份** | `--apply` 模式自动 .b_range_backup/$TIMESTAMP/ |
| **回滚支持** | `--rollback` 用最近备份恢复 |
| **触发点事实队列** | apply/verify 自动 fact_store 到 /tmp/dikw_fact_queue/ |
| **失败不静默** | patch 应用失败立即提示 + 建议回滚 |

## 7. 数学预期（与 A2 协同）

| 阶段 | session 数 | A 静态 + B 应用后 | 体验 |
|---|---|---|---|
| 启动期 | 0-5 | 71% + 源码层 | 文档层 71% + 源码层 100% |
| 适应期 | 5-20 | 78% + 源码层 | 行为/风格继续累积 |
| **无感期** | **20-50** | **85% + 源码层** | **全维度无感（含源码层）** |
| 超越期 | 50+ | 90%+ + 源码层 | 通用版比本地更准 |

**B 应用后的源码层效果**：
- ✅ Holographic CJK 2-gram（中文检索精准）
- ✅ fact_feedback_loop（信任分自动校准）
- ✅ auto-trigger skills（skill 自动触发）
- ✅ DIKW vault-write duty（写完 vault 自动提炼）
- ✅ adaptive-threshold（压缩阈值自适应）
- ✅ feishu-card 增强（飞书卡片消息）
- ✅ siliconflow-stt（语音 STT 走 SiliconFlow）
- ✅ vision 1210 retry（vision 工具自动重试）

## 8. 预留 C 扩展点

| 预留 | 实现 | C 时怎么用 |
|---|---|---|
| 触发点 2 触发点模式 | 2 个 B 触发点 | C 触发点也用同模式 |
| fact_queue 通用 | 同一目录 | C 触发点写到同一目录 |
| 4 维度统一 | 暂无 B 触发点 3（运行时偏差）| C 触发点 3 用同 4 维度 |
| 验证脚本模式 | 7 关键检查 | C 验证脚本用同模式 |

**未来 C 不改 B 文件**——只新增 `c/` 子目录。

## 9. 关联文档

- A1 目录：`../overlay.md` + `../apply_localization.sh`
- A2 目录：`../a2/`（3 触发点 + stats + README）
- 通用版：`../../通用版_v3/`
- GitHub：https://github.com/Zhao961215/dikw-v3-universal-template

## 10. 版本

| 版本 | 时间 | 内容 |
|---|---|---|
| **v3.0.0** | 2026-06-05 01:00 | B 初始版本（6 commit + 1 uncommitted + apply/verify 脚本 + 2 触发点）|
| 待 v3.1.0 | C 完成后 | 增加 5 个新模块 + 62 skills + 35 tools 抽取 |
