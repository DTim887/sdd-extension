# 变更日志

本项目所有值得关注的变更都会记录在这个文件里。

## [0.7.4] - 2026-08-31

### 变更

- `before_specify` 这个 hook 从 `optional: true` 改成 `optional: false`
  ——`/speckit-specify` 生成前的 JIRA 门禁检查不再需要用户每次同意，
  强制执行。其余 17 个生命周期事件维持 `optional: true` 不变。

## [0.7.3] - 2026-08-31

### 变更

- `requirement-self-check` 第 5 步写回 JIRA 前不再需要用户确认——
  整理好的需求会直接写回 ticket description。

## [0.7.2] - 2026-08-31

### 修复

- 修复 `requirement-self-check` 第 1 步的死锁：它读取 ticket 用的是
  `read-jira-ticket.sh`，而这个脚本要求 ticket 必须已经带
  `[SPECKIT:CLARIFIED]` 标记——但这个标记恰恰只有
  `requirement-self-check` 自己才能打上，导致一张从没做过自检的 ticket
  永远无法通过第一步，命令对它本该处理的对象反而完全用不了。给
  `read-jira-ticket.sh` 加了一个仅供内部使用的
  `--skip-clarified-check` 参数，只跳过"必须已有 CLARIFIED"这一条，
  `[SPECKIT:PENDING-REVIEW]` 拦截不受影响，并接入到
  `requirement-self-check` 第 1 步的调用里。

## [0.7.1] - 2026-08-31

### 修复

- 修复 `read-jira-ticket.sh` 需求质量门禁提示文案里 `$TICKET_KEY` 后面
  直接紧跟中文句号"。"、中间没有任何分隔符或花括号的写法——在 macOS
  自带的 bash 3.2（配合 UTF-8 locale）下，这种写法会触发 bash 对多
  字节字符解析的已知缺陷，把句号的首字节误吞进变量名，导致 `set -u`
  下报 `TICKET_KEY�: unbound variable`，命令因此在还没真正校验门禁
  之前就整体硬阻断。现在改为 `${TICKET_KEY}` 显式用花括号界定变量名
  边界，规避这个解析歧义。

## [0.7.0] - 2026-08-31

### 新增

- 新增 `speckit.de-speckit-extension.requirement-self-check`：对一个
  JIRA ticket 做需求质量自检。读取现有 description，以 5W2H
  （Who/What/Why/Where/When/How/How much）作为内部判断依据，用封闭式
  选择题（每轮最多 3 个选项）一轮一轮追问，直到 AI 判断信息足够写
  spec、或用户主动结束为止；若判定涉及新 UI 开发，强制要求提供 Figma
  设计稿链接，且这一条不接受用户中途喊停跳过。整理后的需求以**追加**
  （而非覆盖）方式写回 ticket description，保留原文，打上
  `[SPECKIT:CLARIFIED]`（永久）和 `[SPECKIT:PENDING-REVIEW]`（待 PM
  review 通过后手动删除）两个标记。只做手动调用，不挂载任何生命周期
  hook。
- 新增 `write-jira-ticket.sh`：`requirement-self-check` 的写回脚本。
  在 ADF JSON 层面往原有 `content` 数组追加新节点，不把原文拍平重建，
  避免破坏已有格式；支持 `--incomplete`（用户喊停时插入简短免责声明）
  和 `--dry-run`（只打印待写入的 ADF payload，不真正调用 PUT）。
- `read-jira-ticket.sh` 新增强制的需求质量校验：description 里缺少
  `[SPECKIT:CLARIFIED]` 标记，或仍带有 `[SPECKIT:PENDING-REVIEW]`
  标记，一律硬阻断——这条校验对手动调用和 hook 调用一视同仁，覆盖全部
  18 个共用这个脚本的生命周期事件，且不受除
  `jira_gate.<event>.enabled` 之外的任何配置控制。

## [0.6.0] - 2026-08-27

### 新增

- 新增 `speckit.de-speckit-extension.generate-manual-tests`：分析当前
  feature 已完成的实现代码，反推可观察的行为，生成一份人工可执行的
  手动测试用例清单，写入 `specs/<slug>/manual-test-cases.md`。只做
  手动调用，**不挂载**任何生命周期 hook——不会在 `speckit-implement`
  执行过程中自动触发，需要 implement 完成后自己调用。**忽略任何输入
  参数**，不提供按 feature 名手动指定的方式，恒定读取
  `.specify/feature.json`（经核心 `check-prerequisites.sh` 解析）
  确定的当前 feature。定位和 `speckit-checklist`（校验需求写得好
  不好）互补：这个命令校验的是"实现是否符合预期"，依据是已完成的
  代码而不是 spec 的验收场景直转。
- 要求 `tasks.md` 里的任务**全部**标记为 `[X]` 才会生成——只要还有一条
  `[ ]` 未完成任务，就判定 implement 尚未完成，整体硬阻断，不做部分/
  增量生成。涉及的文件统一改用 `tasks.md` 里各任务列出的精确文件路径
  作为唯一权威来源，不依赖 `git diff`（目标项目不一定是 git 仓库）；
  feature 目录定位复用核心的
  `check-prerequisites.sh --json --require-tasks`，和
  `speckit-implement` 走同一套定位逻辑，未新增任何脚本。

## [0.5.0] - 2026-08-24

### 变更

- `speckit.de-speckit-extension.read-jira-ticket` 挂载的全部 18 个
  生命周期事件，`optional` 从 `false` 改回默认值 `true`：核心引擎每次
  触发都会先给用户一条 prompt（"读取 JIRA 门禁检查 `<phase>` 生成
  前/后"），问要不要运行这个检查，用户同意后才会真正调用；命令是否
  真正生效由 `jira_gate.<event>.enabled` 决定。
- 修正 `jira_gate.<event>.enabled` 的语义，对齐官方 `git` 扩展
  `auto_commit.<event>.enabled` 的实际用法：`enabled: false` 现在是
  **完全不生效**（哪怕输入里恰好有合法 ticket key 也不处理），不再是
  之前那个"没开但找到了也会用"的尽力而为中间态。
- "读 config、判断是否阻断"这套逻辑从命令文件的 Steps 搬进了
  `scripts/bash/read-jira-ticket.sh` 本身：脚本新增
  `read-jira-ticket.sh <event_name> [<ticket_key>]` 这个 hook 模式，
  用纯 `grep`/`sed` 按行解析 YAML（不引入 `yq`/`jq` 依赖，跟
  `auto-commit.sh` 的做法一致），命令文件里不用再重复这套判断。
- 命令文件正文大幅精简（143 行 → 72 行，参考
  `speckit.git.commit.md` 的写法）：去掉写死的"事件 → 核心命令 →
  token"推导表格和 before/after 分别展开的说明，统一成"确定事件名 →
  在相关输入里找 ticket → 调脚本 → 按退出码/输出决定阻断、放行还是
  把结果交给下一步"。

## [0.4.0] - 2026-08-24

### 变更

- 把 `speckit.de-speckit-extension.read-jira-ticket` 从只挂在
  `before_specify` 上，扩展成一个真正通用的 JIRA 门槛：命令文件内部
  不再用写死的"事件 → 核心命令 → token"表格，改成从事件名（去掉
  `before_`/`after_` 前缀）直接推导对应的核心命令和
  `__SPECKIT_COMMAND_*__` token，因此可以挂载在 spec-kit 任意
  `before_*`/`after_*` 事件上，不需要为新事件改这个文件。
- `extension.yml` 相应地把它挂到了全部 18 个核心生命周期事件上（9 个
  阶段 × before/after：constitution、specify、clarify、plan、tasks、
  implement、checklist、analyze、taskstoissues）。`before_X` 在 `X`
  执行前拦截并注入 ticket description；`after_X` 时 `X` 已执行完，
  改为把 description 交付给后续步骤（同事件下一个 hook，或用户接下来
  要跑的下一个生命周期命令）作为上下文，找不到 ticket 时阻断的是
  "下一步"而不是已完成的 `X`。
- 新增 `config-template.yml` 里的 `jira_gate.<event>.enabled` 开关：
  每个事件可以单独控制"找不到 ticket 时是否阻断"，模式参考官方
  `git` 扩展的 `auto_commit` 配置。ticket 一旦被找到，其校验/拉取
  失败仍然一律硬阻断，不受这个开关影响。

## [0.3.1] - 2026-08-24

### 变更

- 新增项目规则（`CLAUDE.md`）：本仓库所有输出文档一律使用中文撰写，
  YAML 结构字段名、命令名、文件路径等技术标识符除外。
- 按这条规则，把 `README.md`、`CHANGELOG.md`、`extension.yml` /
  `config-template.yml` 里的注释和 `description` 类字段值，以及两个
  命令文件的正文，全部翻译成中文。

## [0.3.0] - 2026-08-21

### 新增

- 新增 `speckit.de-speckit-extension.figma-implement-design`：通过 Figma
  MCP 服务器，把 Figma 设计稿转换成与设计 1:1 还原的可用代码。

## [0.2.0] - 2026-08-19

### 变更

- 移除了通用的 `speckit.de-speckit-extension.hook` 脚手架命令（及其
  bash/PowerShell 脚本），原本它挂在所有 `before_*`/`after_*` 生命周期
  事件上。
- 新增 `speckit.de-speckit-extension.read-jira-ticket`：拉取 JIRA
  ticket（`SHDRP-<number>`，来自公司的 Jira Cloud 实例）的 description，
  并把 `/speckit.specify` 挂在一个合法 ticket 引用上作为门槛 ——
  强制执行（`optional: false`），失败时不做优雅降级。
- 把 `config-template.yml` 简化成一个 stub；随着按事件启用/禁用的旧
  脚手架被移除，现在已经没有可配置项了。

## [0.1.0] - 2026-08-16

### 新增

- 初始扩展脚手架：`extension.yml`、配置模板，以及挂在所有
  `before_*`/`after_*` 生命周期事件上的共享 hook 命令。
