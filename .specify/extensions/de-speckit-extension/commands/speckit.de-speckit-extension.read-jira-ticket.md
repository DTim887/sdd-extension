---
description: "读取一个 JIRA ticket（SHDRP-<number>）的 description，交给下一步作为输入；可挂载在 spec-kit 任意 before_*/after_* 生命周期事件上"
scripts:
  sh: ../../scripts/bash/read-jira-ticket.sh
---

# 读取 JIRA Ticket

从 `https://disneyexperiences.atlassian.net` 拉取某个 JIRA ticket 的
`description` 字段，渲染成纯文本，交给下一步作为输入。既可以手动直接
调用，也可以挂载在 spec-kit 任意 `before_*`/`after_*` 生命周期事件上，
作为该事件的 JIRA 门禁使用。

**需求质量门禁（不可配置、一旦上面的 JIRA 门禁生效就强制生效）**：ticket
的 description 里必须带有 `[SPECKIT:CLARIFIED]` 标记（说明已经跑过
`speckit.de-speckit-extension.requirement-self-check` 做过需求质量自检），
且不能再带有 `[SPECKIT:PENDING-REVIEW]` 标记（说明自检结果还没经 PM
review 确认）——两个条件任一不满足都会硬阻断。详见"优雅降级"一节。

唯一的例外：`speckit.de-speckit-extension.requirement-self-check` 自己
第 1 步内部会带 `--skip-clarified-check` 参数调用本脚本，跳过"必须已有
CLARIFIED"这一条（否则自检命令永远无法对任何新 ticket 完成第一步）；
PENDING-REVIEW 拦截不受影响。这个参数不对外暴露、不可配置，只在
`requirement-self-check` 内部使用。

## 用户输入

$ARGUMENTS

## 手动调用

```text
/speckit.de-speckit-extension.read-jira-ticket SHDRP-437322
```

`$ARGUMENTS` 必须是一个匹配 `^SHDRP-[0-9]+$` 的单一 ticket key。格式不对
就报错，不要调用脚本。

## 作为 Hook 调用

1. 从触发这次调用的 hook 上下文里确定事件名（如 `before_plan`）。
2. 在该事件相关的核心命令的自然语言输入里（`before_X` 看即将/刚触发的
   `/speckit.X` 调用；`after_X` 看它当初被调用时的输入），任意位置搜索
   是否存在 `SHDRP-[0-9]+`。
3. 运行脚本：`read-jira-ticket.sh <event_name> [<ticket_key>]`
   （见下方"执行"）。是否阻断、是否真正生效，由脚本内部读取
   `jira_gate.<event>.enabled` 配置决定，这里不用重复判断。
4. 按脚本的**退出码**处理（先看退出码，不要只看有没有输出）：
   - **非零退出**：**停止**，把脚本的 stderr 信息原样展示给用户。这
     包括找不到 ticket、ticket 不存在、认证/网络失败、**description
     为空**等所有失败情形——只要退出码非零，一律阻断，不放行。
   - **零退出**（只有 `jira_gate.<event>.enabled` 为 `false` 时才会
     出现，此时 stdout 必然为空）：门禁对这个事件未生效，正常继续，
     不做任何注入。
   - **零退出且 stdout 有内容**：把这段纯文本作为上下文，交给下一步
     （重新调用被门禁的命令，或作为后续步骤的输入）。

## 执行

- **Bash**：`.specify/extensions/de-speckit-extension/scripts/bash/read-jira-ticket.sh <TICKET-KEY>`
  （手动调用）或 `... read-jira-ticket.sh <event_name> [<TICKET-KEY>]`
  （hook 调用）

需要在环境变量里配置 `ATLASSIAN_EMAIL` 和 `ATLASSIAN_API_TOKEN`（这个
组织已经统一配好了）。如有需要，`ATLASSIAN_BASE_URL` 可以覆盖默认的
`https://disneyexperiences.atlassian.net`。

## 配置

`.specify/extensions/de-speckit-extension/de-speckit-extension-config.yml`
里的 `jira_gate.<event>.enabled`（缺省回退 `jira_gate.default`）控制这个
门禁在某个事件上是否生效：

```yaml
jira_gate:
  default: true
  before_plan:
    enabled: false   # 这个事件上完全不生效，即使输入里有 ticket key
```

## 优雅降级

- `jira_gate.<event>.enabled` 为 `false`：该事件上门禁完全不生效，
  脚本直接空跑——不去找 ticket，也不会校验，哪怕输入里恰好有一个
  格式合法的 ticket key 也不处理。这是唯一存在优雅降级的地方。
- `enabled` 为 `true` 时（只有这个分支才会真的去找、去校验 ticket）：
  - 输入里找不到 ticket：阻断，报错提示需要一个 `SHDRP-<digits>`
    格式的引用。
  - 找到了但校验/拉取失败（不存在、认证失败、网络错误、description
    为空等）：没有优雅降级，一律硬阻断——这条不会跟上面
    `enabled: false` 的情况同时发生，因为 `enabled: false` 时压根不会
    走到这一步。
  - 拉取成功、description 也不为空，但缺 `[SPECKIT:CLARIFIED]` 标记，
    或者还留着 `[SPECKIT:PENDING-REVIEW]` 标记：同样没有优雅降级，
    一律硬阻断。这条检查**不受任何配置开关控制**——只要走到了这一步
    （即 `jira_gate.<event>.enabled` 为 `true`），就一定会做这个校验。
