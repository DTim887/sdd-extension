# 项目规则

## 文档语言

本仓库所有输出的文档一律使用中文撰写，包括但不限于：

- `README.md`、`CHANGELOG.md`
- `commands/*.md` 命令文件的正文说明（Overview、Steps、Graceful Degradation 等章节）
- `extension.yml`、`config-template.yml` 中的注释
- 新增/修改文档时的说明性文字

以下内容不受此规则约束，仍需保持英文或原样，因为它们是 spec-kit 的技术规范或外部标识符，翻译会破坏功能：

- YAML 结构字段名（如 `schema_version`、`provides`、`hooks`、`description:` 这些 key 本身）
- 命令名/文件名（如 `speckit.de-speckit-extension.read-jira-ticket`）
- 代码、脚本内容、shell 命令
- Markdown frontmatter 的字段名（`description`、`tools`、`scripts` 等 key），但字段的**值**（如 `description` 后面的文字说明）应使用中文
