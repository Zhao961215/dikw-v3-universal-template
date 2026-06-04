# 贡献指南（Contributing Guide）

感谢你对 DIKW 记忆系统 v3 通用部署模板 感兴趣！

## 🐛 报告 Bug

在 GitHub Issues 提交 bug 报告，使用 `.github/ISSUE_TEMPLATE/bug_report.md` 模板。

## 💡 提议功能

在 GitHub Issues 提交 feature request，使用 `.github/ISSUE_TEMPLATE/feature_request.md` 模板。

## 🔧 提交 Pull Request

1. Fork 这个仓库
2. 创建你的 feature 分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的改动 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

使用 `.github/PULL_REQUEST_TEMPLATE.md` 模板。

## 📝 文档风格

- 中文优先（主上系统是中文用户）
- 保持简洁（避免冗长）
- 用 Markdown 标题层级
- 代码块标注语言

## 🧪 测试

提交前必跑：

```bash
# 1. 单元测试
python3 04-一键部署/test_deploy.py
# 期望: 通过 7/7

# 2. dry-run 部署测试
python3 04-一键部署/deploy_dikw.py --workspace . --dry-run
# 期望: 5 步全部 success

# 3. 安全审计
grep -r "用户223475\|sk-I9l\|192.168.3.170" . --include="*.py" --include="*.sh" --include="*.md"
# 期望: 无命中
```

## 📋 11 步信息流检查清单

任何 PR 必须自查：

- [ ] 1. 指令清晰（主上要做什么？）
- [ ] 2. Agent 接收完整
- [ ] 3. 大脑先 fact_store 查记忆
- [ ] 4. 图书馆 5 层不跳步（踩坑 → 知识库 → 近期对话 → 缓存点 → 网络）
- [ ] 5. 工具决策明确（5 步：扫描 skills → 选对工具 → 查可用性 → 批量优先 → 安全验证）
- [ ] 6. 处理按顺序
- [ ] 7. 反馈到主上
- [ ] 8. 迭代回 fact_store

## 📄 License

提交 PR 即表示你同意你的代码按 MIT License 发布。

## 🛡️ 安全

**禁止**：
- ❌ 硬编码任何 API key / 邮箱 / 私有 IP
- ❌ 提交任何含个人信息的文件
- ❌ 提交 ~/.hermes/ 下的任何专有数据
- ❌ 任何违反 P0 安全底线的操作

**必须**：
- ✅ 提交前跑审计 6 步
- ✅ 在 PR 描述里说明"未引入敏感信息"

## 📞 联系方式

- GitHub Issues: https://github.com/Zhao961215/dikw-v3-universal-template/issues
- GitHub Discussions: https://github.com/Zhao961215/dikw-v3-universal-template/discussions

谢谢你的贡献！🎉
