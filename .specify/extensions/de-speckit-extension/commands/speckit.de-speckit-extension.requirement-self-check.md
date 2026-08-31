---
description: "对一个 JIRA ticket（SHDRP-<number>）做需求质量自检：基于 5W2H 标准用封闭式选择题追问，直到信息足够或用户主动结束，然后把澄清结果追加写回 ticket description"
scripts:
  sh: ../../scripts/bash/write-jira-ticket.sh
---

# 需求质量自检

对着一个 JIRA ticket 做一轮交互式的需求质量自检：读取现有 description，
基于 5W2H 标准判断哪些信息缺了会导致后续 `/speckit-specify` 之类的命令
只能靠 AI 脑补，用封闭式选择题一轮一轮追问，直到信息足够或用户主动结束，
再把整理好的结果**追加**写回 ticket description（不覆盖原文），并打上
机器可识别的标记。

写回之后这张 ticket 依然处于"待 PM review"状态——`read-jira-ticket.sh`
（被全部 18 个 spec-kit 生命周期事件共用）会持续阻断它，直到 PM review
完、删除原始描述和待审标记为止。详见
`speckit.de-speckit-extension.read-jira-ticket` 命令文件里的"需求质量
门禁"说明。

## 用户输入

$ARGUMENTS

`$ARGUMENTS` 必须是一个匹配 `^SHDRP-[0-9]+$` 的单一 ticket key。格式不对
**立即终止**：报错，不调用 `read-jira-ticket.sh`/`write-jira-ticket.sh`
中的任何一个，不做猜测或重试。

## 命令边界

- 只做手动调用，不挂载任何 `before_*`/`after_*` 生命周期 hook——不会
  自动触发，需要用户对着一个具体 ticket 主动调用。
- 依赖已有的 `read-jira-ticket.sh`（读取现状）和新增的
  `write-jira-ticket.sh`（写回结果），不重复实现 JIRA 访问逻辑。
- 追问只用封闭式选择题，每轮最多 3 个选项；用户可以随时用类似
  "够了/别问了"的表达喊停。
- **例外（硬性、不可跳过）**：判定涉及新 UI 开发时，必须拿到一个 Figma
  设计稿链接才算合格，不受用户喊停影响——缺链接时整个流程硬性终止，
  不写回 JIRA。
- ticket key 格式校验失败，在命令本身、`read-jira-ticket.sh`、
  `write-jira-ticket.sh` 任意一层，都是立即终止，不做后续任何调用。

## 手动调用

```text
/speckit.de-speckit-extension.requirement-self-check SHDRP-437322
```

## 执行步骤

### 第 1 步：读取当前需求描述

调用：

```bash
.specify/extensions/de-speckit-extension/scripts/bash/read-jira-ticket.sh <TICKET-KEY> --skip-clarified-check
```

（手动模式）。**必须带 `--skip-clarified-check`**：这张 ticket 本来就
是要来做自检的，天然不会有 `[SPECKIT:CLARIFIED]` 标记，如果不加这个
参数，`read-jira-ticket.sh` 的门禁会把"没有 CLARIFIED 标记"当成硬阻断
条件，导致本命令永远无法对任何新 ticket 完成第一步（自己拦死自己）。
这个参数只跳过"必须已有 CLARIFIED"这一条，不影响下面的
PENDING-REVIEW 拦截。

非零退出：原样展示 stderr 并**终止**。这包括几种预期内的情形——ticket
不存在、认证/网络失败、description 为空，以及"这张 ticket 已经跑过
自检、还在待审状态"（此时脚本会报"仍留有 `[SPECKIT:PENDING-REVIEW]`
标记"）——一律停止，不重复处理已经在审的 ticket。

### 第 2 步：基于 5W2H 追问澄清

以 5W2H 作为内部判断依据（不是给用户看的死清单），对照第 1 步读到的
原始描述，判断哪些维度缺失、缺了会导致写 spec 时必须靠猜：

- **Who**：谁在用这个功能/涉及哪些角色
- **What**：要实现什么具体能力
- **Why**：解决什么问题、优先级/价值
- **Where**：在什么场景/渠道下用（Web/移动/内部系统等）
- **When**：触发时机、生命周期
- **How**：关键业务规则怎么运作
- **How much**：规模/量级相关的验收标准（如果适用）

追问规则：

- 一次只问一个问题，**封闭式选择题**，最多 3 个选项，挑当前最关键、
  缺了最影响范围判断的维度先问。
- 用户可以随时用类似"够了/别问了/就这样吧"的表达喊停。
- 持续到 AI 判断"不需要再猜"为止，或者用户喊停。
- 记录喊停时还有哪些维度没问完（用于第 4 步的免责声明），但**不**逐项
  列出这些缺口——只在最终文本里留一句简短提醒。

### 第 3 步：UI 场景强制校验 Figma 链接

判断这个需求是否涉及新 UI 开发（新页面、新组件、对现有界面的可见改动
等）。如果涉及：

- 必须拿到一个 Figma 设计稿链接。这一步用**开放式**问题直接问链接，
  不是封闭选择题。
- 这一条**不受第 2 步"用户喊停"影响**：哪怕用户已经喊停、其他维度都
  已经按免责声明处理，只要判定涉及新 UI 且始终没拿到链接，就**不进入
  第 5 步**，直接终止整个命令，提示用户"请先补充 Figma 设计稿链接后
  再重新运行本命令"，不写回 JIRA。
- 不涉及新 UI 的需求，跳过这一步。

### 第 4 步：整理澄清结果

把第 2、3 步的 Q&A 结果整理成结构化的纯文本，按空行分段：

- 首段简述整理后的需求要点。
- 涉及 UI 的话，把 Figma 链接作为独立一段列出。
- 如果第 2 步是用户主动喊停结束的，记下这个事实（供第 5 步传
  `--incomplete`），但不在正文里逐项列出未尽事项。

把整理好的文本写入一个临时文件（如
`/tmp/speckit-requirement-self-check-<TICKET-KEY>.txt`）。

### 第 5 步：写回 JIRA

把第 4 步整理出的文本直接写回 ticket，不需要额外的用户确认环节：

```bash
.specify/extensions/de-speckit-extension/scripts/bash/write-jira-ticket.sh <TICKET-KEY> <临时文件> [--incomplete]
```

（第 2 步是用户喊停结束时加 `--incomplete`）。非零退出：原样展示 stderr
并终止，不重试。

### 第 6 步：收尾报告

告知用户：

- ticket 已更新，追加了澄清后的需求内容；
- 这张 ticket 现在处于"待 PM review"状态，必须由人工 review、删除原始
  描述和 `[SPECKIT:PENDING-REVIEW]` 标记后，才能通过任何 spec-kit 命令
  的 JIRA 门禁（包括 `/speckit-specify`）。

## 执行

- **Bash**：
  - `.specify/extensions/de-speckit-extension/scripts/bash/read-jira-ticket.sh <TICKET-KEY> --skip-clarified-check`
  - `.specify/extensions/de-speckit-extension/scripts/bash/write-jira-ticket.sh <TICKET-KEY> <临时文件> [--incomplete]`

两个脚本都需要环境变量 `ATLASSIAN_EMAIL` 和 `ATLASSIAN_API_TOKEN`（这个
组织已经统一配好了）。如有需要，`ATLASSIAN_BASE_URL` 可以覆盖默认的
`https://disneyexperiences.atlassian.net`。

## 优雅降级

- ticket key 格式错误：没有优雅降级，命令本身立即终止，不调用任何脚本。
- 第 1 步 `read-jira-ticket.sh` 非零退出（不存在、认证/网络失败、
  description 为空、已在待审状态等）：没有优雅降级，原样展示 stderr
  并终止。
- 涉及新 UI 但拿不到 Figma 链接：没有优雅降级，硬性终止，不写回 JIRA。
- 第 5 步 `write-jira-ticket.sh` 非零退出：没有优雅降级，原样展示
  stderr 并终止——不做部分写入。
