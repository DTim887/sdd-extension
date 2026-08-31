# de-speckit-extension

DE 的组织级 Spec Kit 扩展。它的存在是为了让 DE 特有的约定和治理检查
能够随标准 spec-kit 工作流自动运行，不需要每个团队自己在项目里重新定义
一遍。

一个 [Spec Kit](https://github.com/github/spec-kit) 扩展。

## 命令

| 命令 | 说明 |
|------|------|
| `speckit.de-speckit-extension.read-jira-ticket` | 读取一个 JIRA ticket（`SHDRP-<number>`）的 description，交给下一步作为输入；可挂载在 spec-kit 任意 `before_*`/`after_*` 生命周期事件上 |
| `speckit.de-speckit-extension.figma-implement-design` | 通过 Figma MCP 服务器，把 Figma 设计稿转换成与设计 1:1 还原的可用代码 |
| `speckit.de-speckit-extension.generate-manual-tests` | 分析当前 feature 已完成的实现代码，生成一份可供人工执行的手动测试用例清单，落地到 `specs/<slug>/manual-test-cases.md`；只做手动调用、不挂载生命周期 hook，且忽略任何输入参数，恒定只处理 `.specify/feature.json` 记录的当前 feature |
| `speckit.de-speckit-extension.requirement-self-check` | 对一个 JIRA ticket（`SHDRP-<number>`）做需求质量自检：基于 5W2H 标准用封闭式选择题一轮一轮追问，直到信息足够或用户主动结束，再把澄清结果追加写回 ticket description；只做手动调用、不挂载生命周期 hook |

## Hooks

`speckit.de-speckit-extension.read-jira-ticket` 是一个**通用命令**，挂在
全部 18 个核心生命周期事件上（9 个阶段 × `before_`/`after_`：
constitution、specify、clarify、plan、tasks、implement、checklist、
analyze、taskstoissues）。每个事件都是 `optional: true`（默认，见
`extension.yml`）——核心引擎每次触发都会先给用户一条 prompt，问要不要
运行这个 JIRA 检查，用户同意后 agent 才会调用。

这个命令一旦被调用，是否真正生效由项目的
`de-speckit-extension-config.yml` 里 `jira_gate.<event>.enabled` 决定：

- `enabled: true`：门禁生效——在相关输入里找 `SHDRP-<number>`，找到
  就拉取 description 交给下一步，找不到就阻断。
- `enabled: false`：门禁完全不生效，直接放行，即使输入里恰好有合法
  ticket key 也不处理。

一旦按 `enabled: true` 找到了 ticket，它本身校验失败（不存在、认证
失败、description 为空等）就一律硬阻断，不再看这个开关。完整行为见
对应命令文件。

## 需求质量门禁

`read-jira-ticket.sh` 在拉取到非空 description 后，还会强制校验两个
标记（这一层校验**不受** `jira_gate.<event>.enabled` 之外的任何配置
控制——只要该事件的 JIRA 门禁本身是 `enabled: true`，这条校验就一定
生效，没有单独的开关）：

- 缺少 `[SPECKIT:CLARIFIED]` 标记（说明这张 ticket 从没跑过需求质量
  自检）：硬阻断，提示先运行
  `speckit.de-speckit-extension.requirement-self-check`。
- 仍带有 `[SPECKIT:PENDING-REVIEW]` 标记（说明自检结果还没经 PM
  review 确认）：硬阻断，提示先完成 review、删除原始描述和该标记。

两个标记都由 `speckit.de-speckit-extension.requirement-self-check` 及
其配套的 `write-jira-ticket.sh` 写入——该命令读取现有 description，用
5W2H 标准通过封闭式选择题一轮一轮追问用户，直到信息足够或用户主动
结束，再把整理好的需求**追加**（不覆盖原文）写回 ticket，同时打上
`[SPECKIT:CLARIFIED]` 和 `[SPECKIT:PENDING-REVIEW]` 两个标记。后者需要
人工 review：PM 确认追加内容准确后，手动删除原始描述和
`[SPECKIT:PENDING-REVIEW]` 这一行，ticket 才算真正"放行"。

若判定需求涉及新 UI 开发，`requirement-self-check` 还会强制要求提供
一个 Figma 设计稿链接——这一条不接受用户中途喊停跳过，缺链接时自检
流程本身就会终止，不会写回 JIRA。

## 配置

`config-template.yml` 里的 `jira_gate` 控制上述 18 个事件各自是否生效，
默认全部为 `true`。项目可以按需在
`.specify/extensions/de-speckit-extension/de-speckit-extension-config.yml`
里把某个事件改成 `false`，让门禁在该事件上完全不生效。

## 安装

内部扩展 —— 直接从我们内部 Git host 上的 release 归档安装（没有在官方
Spec Kit catalog 上架）：

```bash
specify extension add de-speckit-extension \
  --from https://github.com/DTim887/de-speckit-extension/archive/refs/tags/v0.7.4.zip
```

针对本仓库的本地检出做本地开发：

```bash
specify extension add de-speckit-extension --dev /path/to/de-speckit-extension
```

## 禁用

```bash
specify extension disable de-speckit-extension
specify extension enable de-speckit-extension
```

## 优雅降级

- `jira_gate.<event>.enabled` 为 `false`：门禁在该事件上完全不生效——
  不去找 ticket，也不会校验，哪怕输入里恰好有合法 ticket key 也不
  处理。这是唯一存在优雅降级的地方。
- `enabled` 为 `true` 时（只有这个分支才会真的去找、去校验 ticket）：
  找不到就阻断；找到了但校验/拉取失败（不存在、认证失败、网络错误、
  description 为空等）就没有优雅降级，一律硬阻断——这条不会跟
  `enabled: false` 的情况同时发生。详见对应命令文件里的"优雅降级"
  章节。
- 需求质量门禁（`[SPECKIT:CLARIFIED]` / `[SPECKIT:PENDING-REVIEW]`
  标记校验）同样没有优雅降级——只要走到了校验这一步，缺标记或标记
  未清就一律硬阻断。`requirement-self-check` 里"涉及新 UI 但没有
  Figma 链接"也是同样的硬阻断，不接受喊停跳过。

## 发布新版本

1. 在 `extension.yml` 里升级 `version`（遵循 semver），并在
   `CHANGELOG.md` 里加一条记录。
2. 打 tag 并推送：`git tag vX.Y.Z && git push --tags`。
3. 给这个 tag 创建一个 release —— `specify extension add ... --from <url>`
   指向的就是这个 release 归档的 zip URL。
