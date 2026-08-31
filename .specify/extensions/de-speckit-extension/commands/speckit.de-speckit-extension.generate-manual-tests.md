---
description: "分析当前 feature（.specify/feature.json 记录的那一个）已完成的实现代码，生成一份可供人工执行的手动测试用例清单，落地到 specs/<slug>/manual-test-cases.md；建议在 speckit-implement 完成后手动调用"
---

# 生成手动测试用例

从已完成的实现代码（而不是从 spec 的验收场景直接转写）反推可观察的行为，生成一份人工可执行的手动测试用例清单，写入
`specs/<slug>/manual-test-cases.md`。定位是"验证实现是否符合预期"，和 `speckit-checklist`（"验证需求写得好不好"）互补但不重叠。

## 用户输入

$ARGUMENTS

本命令**不消费** `$ARGUMENTS`——无论用户输入什么，一律忽略，恒定只处理当前 feature（见下方"第 1 步"）。不支持通过参数指定其他 feature；要为别的 feature 生成，先切到那个 feature（更新`.specify/feature.json`/`SPECIFY_FEATURE`），再调用本命令。

## 命令边界

- 只做手动调用，不挂载任何 `before_*`/`after_*` 生命周期 hook——不会在`speckit-implement` 执行过程中自动触发，需要在 implement 完成后自己调用。
- 只分析已经写完的代码/UI，不重新解读 spec 的验收场景（`spec.md` 只用来取 User Story 标题和优先级做追溯标签，不作为生成的主要依据）。
- 忽略任何输入参数，只针对"当前 feature"生成，不支持一次调用指定其他 feature。
- 要求 implement **全部**任务已完成（`tasks.md` 里不存在任何 `[ ]`）才会生成；只要有一个任务还没完成，就说明 implement 尚未完成，整体硬阻断，不做部分/增量生成。

## 手动调用

```text
/speckit.de-speckit-extension.generate-manual-tests
```

不接受、也不解析任何参数——即使用户在命令后附带了文本，也按无参数处理。

## 执行步骤

### 第 1 步：定位 feature 目录

从项目根目录运行：

```bash
.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
```

解析出 `FEATURE_DIR`（绝对路径）。这个脚本内部读取`SPECIFY_FEATURE`/`.specify/feature.json` 来确定"当前 feature"，本命令不
自己解析 `feature.json`，也不提供任何覆盖当前 feature 的方式。

若脚本因为 `tasks.md` 不存在（`--require-tasks`）而非零退出：停止，把脚本的错误信息原样展示给用户——没有 `tasks.md` 就没有"已完成了什么"的依据，没有优雅降级可言。

### 第 2 步：确认 implement 已全部完成，收集涉及文件

- 读 `<FEATURE_DIR>/tasks.md` 里的全部任务行。只要存在任意一条标记为
  `[ ]`（未完成）的任务，就说明 implement 还没有跑完：**停止**，提示
  用户"这个 feature 还有未完成的任务，implement 尚未完成，请先跑完
  speckit-implement 的全部任务再运行本命令"——不生成任何文件，不做
  部分/增量处理。
- 确认全部任务均已标记 `[X]` 后，从每条任务描述里提取精确文件路径
  （`tasks.md` 的任务描述按约定都带精确文件路径，见其中的
  `## Path Conventions` 一节）。
- 目标项目不一定是 git 仓库，**不要**默认可以用 `git diff`/`git log`
  判断改动范围——`tasks.md` 里各任务列出的文件路径清单才是唯一可靠
  依据；即使目标项目确实是 git 仓库，也不用 `git diff`，保持两种情况
  下行为一致。
- 如果某条任务没有清晰列出文件路径，跳过它，不要凭空猜测涉及的文件。

### 第 3 步：静态分析涉及到的代码

对第 2 步收集到的每个文件逐一读取，提取可观察的、能写成"打开页面 →做什么 → 应该看到什么"的测试点。以下以常见前端框架为例，具体识别方式按目标项目实际使用的框架/语言调整：

- **条件渲染**：模板里的条件渲染指令/表达式（如 `*ngIf`/`*ngSwitch`、JSX 三元/`&&`、`v-if`）——每个分支是一个测试点（包括"条件不满足时应该不渲染什么"）。
- **循环渲染**：列表渲染（如 `*ngFor`、`.map()`、`v-for`）——覆盖"列表为空"和"列表有数据"两种可观察状态（仅当代码里能看出空态处理时才加空态用例）。
- **交互绑定**：点击/输入/聚焦等事件绑定——转成"用户做了什么操作，应该发生什么可观察的变化"。
- **响应式断点**：CSS 断点/媒体查询——转成"在某个视口宽度下应该看到什么布局"。
- **国际化**：模板里引用的 i18n key——只在代码里确实用了国际化机制（如 `TranslateService`/`| translate`、`react-i18next`、`vue-i18n`）时，才加一条"切换语言后文案正确切换"的测试点，不要凭空假设项目支持多语言。
- **组件 Props/Input/Output**：覆盖不同输入值下的可观察行为差异。

只写"用户/QA 能直接观察到的行为"，不要写"验证代码是否调用了某个内部方法"这类实现细节断言。

### 第 4 步：补充追溯标签（不是生成依据，只是分类/编号用）

- 读 `<FEATURE_DIR>/spec.md`，取每个 `### User Story N - ... (Priority: PX)`的标题和优先级。
- 把第 3 步生成的每条测试点，按内容相关性归到最贴近的 User Story 下，并记录对应的 `PX` 优先级。
- 找不到明显对应的 User Story 时，归到一个"未归类"分组，不要强行拉郎配。

### 第 5 步：生成 `manual-test-cases.md`

写入 `<FEATURE_DIR>/manual-test-cases.md` **如果该文件已存在，直接覆盖**——不做合并、不保留旧的"实际结果"/"执行人/日期"栏位内容（这是本命令唯一的幂等策略；如需保留旧的执行记录，请在调用前自行备份）。编号规则：`MT-<feature编号>-<两位序号>`，`<feature编号>` 取自`FEATURE_DIR` 目录名的前缀数字（如 `003-category-nav-menu` → `003`），序号从 `01` 开始按 User Story 顺序递增。

文件结构：

```markdown
# 手动测试用例：<feature 中文标题>

**Feature**: `<feature-slug>`
**生成依据**: tasks.md 中已完成任务涉及的 <N> 个文件（静态代码分析，非 spec 直转）
**生成时间**: <YYYY-MM-DD>

## User Story 1 - <标题> (Priority: P1)

| 编号 | 优先级 | 测试点 | 前置条件 | 测试步骤 | 预期结果 | 关联文件 | 实际结果 | 执行人/日期 |
|---|---|---|---|---|---|---|---|---|
| MT-003-01 | P1 | ... | ... | 1. ... 2. ... | ... | `xxx.component.html` | | |

## User Story 2 - <标题> (Priority: P2)

...

## 未归类

（仅在存在无法归类的测试点时输出这一节）
```

## 优雅降级

- 找不到 `FEATURE_DIR`（脚本非零退出，且不是因为 `--require-tasks`缺失 `tasks.md`）：停止，原样展示脚本的错误信息。
- `tasks.md` 里存在任意 `[ ]` 未完成任务：停止，提示用户先跑完
  `speckit-implement` 的全部任务——implement 尚未完成时不做部分生成，
  这是硬阻断，没有优雅降级。
- `spec.md` 不存在：不阻断——第 4 步的追溯标签退化成只有一个"未归类"分组，其余步骤照常执行。
- 已完成任务列出的文件本身不存在（比如后来被删除/改名）：跳过该文件，不中断整个生成流程，在文件末尾追加一行提示"以下任务引用的文件未找到，已跳过：<路径>"。
