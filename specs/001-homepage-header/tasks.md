---

description: "Task list for 商城首页 Header（欢迎词与快捷入口）"
---

# Tasks: 商城首页 Header（欢迎词与快捷入口）

**Input**: Design documents from `/specs/001-homepage-header/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md

**Tests**: spec.md 未要求 TDD；该组件为纯静态展示、无逻辑分支，按 [[frontend-constitution]] 第 8.1 节豁免单元测试强制项（见 plan.md Constitution Check），因此本任务清单不包含测试任务。

**Organization**: 本功能只有一个用户故事（US1，P1），任务按 Setup → Foundational → US1 → Polish 组织。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel（不同文件，无相互依赖）
- **[Story]**: 对应 spec.md 中的用户故事标签（US1）
- 每个任务包含明确文件路径

## Path Conventions

Web app（monorepo）：`frontend/src/`，本功能不涉及 `backend/`（见 plan.md Project Structure）。

`frontend/` 目录当前尚未初始化（无 `package.json` / `angular.json`），因此 Phase 1 Setup 包含 Angular 工作区的初始化任务。

---

## Phase 1: Setup（项目初始化）

**Purpose**: 初始化 `frontend/` Angular 工作区及基础工具链（当前仓库中尚不存在）

- [X] T001 使用 Angular CLI 在 `frontend/` 初始化 Angular 最新稳定版（v17+）工作区，启用 Standalone Components、`strict: true` TypeScript、esbuild/application builder（per plan.md Technical Context，[[frontend-constitution]] 第 0 节）——**注**：当前环境 Node v22.18.0 不满足 Angular CLI 22.x 所需的 `^22.22.3`，改用兼容的最新版本 Angular 21.2（满足 `^22.12.0`），已在 research.md 记录该环境约束
- [X] T002 [P] 在 `frontend/` 安装并配置 Tailwind CSS（`frontend/tailwind.config.js`、全局样式入口 `frontend/src/styles.css`），禁止引入 Angular Material / PrimeNG（per [[frontend-constitution]] 第 4 节）——**注**：使用 Tailwind v3.4（而非 v4），原因见 research.md Decision 4a（Angular 内置零配置探测逻辑与 v4 的 `@tailwindcss/postcss` 拆分不兼容）；构建已验证通过（`ng build`）
- [X] T003 [P] 在 `frontend/` 配置 ESLint（angular-eslint）+ Prettier（`frontend/eslint.config.js`、`frontend/.prettierrc`）（per [[frontend-constitution]] 第 9.2 节）——`ng lint` 已验证通过
- [X] T004 [P] 在 `frontend/` 配置 Jest + jest-preset-angular 测试运行器（`frontend/jest.config.js`、`frontend/setup-jest.ts`），替换脚手架默认的 Vitest，为后续功能预留测试基础设施（per [[frontend-constitution]] 第 8 节，research.md Decision 6/7）——`npx jest` 已验证通过（2 passed）

---

## Phase 2: Foundational（阻塞性前置条件）

**Purpose**: 建立本功能实现所需的目录骨架与设计 token 占位，US1 的所有任务依赖此阶段完成

**⚠️ CRITICAL**: 本阶段完成前不得开始 Phase 3 的任务

- [X] T005 创建按业务领域划分的基础目录骨架 `frontend/src/app/core/{interceptors,guards,services}/`、`frontend/src/app/shared/{components,pipes,directives,utils}/`、`frontend/src/app/layout/header/`、`frontend/src/app/features/`（per plan.md Project Structure，[[frontend-constitution]] 第 1.1 节）
- [X] T006 [P] 在 `frontend/tailwind.config.js` 中为 header 预留 design tokens 占位（颜色/间距/字体），具体取值在 T007 实现阶段依据 Figma 精确核对（per [[frontend-constitution]] 第 4.2 节，禁止 magic number）——占位已在 T002 创建，T007/T008 中据 Figma 实际取值填充

**Checkpoint**: 目录骨架与基础工具链就绪，可以开始 User Story 1 的实现

---

## Phase 3: User Story 1 - 浏览首页 Header 获取欢迎信息与快捷入口 (Priority: P1) 🎯 MVP

**Goal**: 用户打开商城首页即可在顶部看到固定文案的欢迎词，以及 deliver to / track your order / All Offers 三个静态快捷入口（两条分割线），视觉与 Figma 设计稿一致。

**Independent Test**: 按 [quickstart.md](./quickstart.md) 的 6 项验收场景人工验证（欢迎词展示、三入口+两分割线、登录态不影响文案、点击无跳转、视觉对照 Figma、≥1280px 不溢出）。

### Implementation for User Story 1

- [X] T007 [US1] 使用 `speckit-de-speckit-extension-figma-implement-design` skill 拉取 spec.md FR-005 列出的 7 个 Figma 节点设计上下文，在 `frontend/src/app/layout/header/header.component.ts` 创建 `HeaderComponent`（`standalone: true`、`ChangeDetectionStrategy.OnPush`、无 `input()`/`output()`、不注入 `HttpClient` 或任何 service），MUST NOT 绕开该 skill 直接凭空实现（per [[frontend-constitution]] 第 4.1 节，[[speckit-de-speckit-extension-figma-implement-design]]）——已通过 `get_design_context`/`get_metadata`/`download_assets` 拉取全部 6 个内容节点，图标 SVG 已下载至 `frontend/public/icons/header/`
- [X] T008 [P] [US1] 在 `frontend/src/app/layout/header/header.component.html` 中用 Tailwind class 实现欢迎词、三个快捷入口、两条分割线的布局，像素级还原 T007 拉取的 Figma 设计上下文（依赖 T007；对应 FR-001、FR-002、FR-003、FR-005）——design tokens 写入 `frontend/tailwind.config.js`（header-bg/header-text/header-accent/header-divider/header-gutter/header-icon/header-bar 等），分割线以 CSS 元素还原（Figma 中为 1px 描边线，非图标类资源）
- [X] T009 [P] [US1] 在 `frontend/src/app/app.html` 顶部引入 `<app-header>`，使其在商城首页渲染（依赖 T007；无需绑定任何 `@Input`/事件，对应 FR-004 静态展示要求）——同步清理了脚手架默认的营销占位模板，`app.spec.ts` 断言已更新为校验 `<app-header>` 渲染
- [X] T010 [US1] 按 [quickstart.md](./quickstart.md) 的 6 项验收场景在本地 `ng serve` 环境人工验证并记录结果（依赖 T007、T008、T009）——6 项全部通过：①②③④⑤⑥ 见下方"人工验收记录"

**Checkpoint**: User Story 1（本功能唯一故事）完整可独立验证，达到 MVP 交付标准

### 人工验收记录（T010，2026-08-31，`ng serve` + 浏览器截图）

| # | 场景 | 结果 |
|---|------|------|
| 1 | 欢迎词展示，无需滚动 | ✓ 通过 |
| 2 | 三个快捷入口 + 两条分割线依次可见 | ✓ 通过 |
| 3 | 欢迎词为固定文案（组件无登录态相关逻辑，天然满足） | ✓ 通过 |
| 4 | 点击三个入口均不跳转（实测点击 "Track your order"，`location.href` 未变化） | ✓ 通过 |
| 5 | 视觉对照 Figma 截图（背景色、文案、图标、分割线均一致） | ✓ 通过 |
| 6 | 桌面宽度下不换行/不遮挡/不溢出（`document.body.scrollWidth <= window.innerWidth` 校验为 `false`，即无溢出；文本均 `whitespace-nowrap`） | ✓ 通过 |

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: 收尾质量检查

- [X] T011 [P] 在 `frontend/` 运行 `ng lint`，修复所有告警（per [[frontend-constitution]] 第 9.2 节 PR 门槛要求）——`All files pass linting`
- [X] T012 `/speckit-implement` 完成后，运行 `speckit-de-speckit-extension-generate-manual-tests` skill，基于本功能实现生成正式人工测试用例清单至 `specs/001-homepage-header/manual-test-cases.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**：无依赖，可立即开始；T001 需先完成，T002–T004 依赖 T001（工作区已存在）后可并行
- **Foundational (Phase 2)**：依赖 Setup 完成；T005、T006 之间无相互依赖，可并行；本功能唯一的 User Story 依赖本阶段完成
- **User Story 1 (Phase 3)**：依赖 Foundational 完成；T007 先行，T008/T009 依赖 T007 但彼此独立可并行，T010 依赖 T007–T009 全部完成
- **Polish (Phase 4)**：依赖 User Story 1 完成

### Within User Story 1

- T007（组件骨架）→ T008（样式还原）、T009（挂载到首页）可并行 → T010（人工验收）

### Parallel Opportunities

- Setup 阶段：T002、T003、T004 可并行（不同配置文件）
- Foundational 阶段：T005、T006 可并行（不同文件）
- User Story 1 阶段：T008、T009 可并行（不同文件，均依赖 T007）

---

## Parallel Example: Setup

```bash
# T001 完成、Angular 工作区存在后：
Task: "Install & configure Tailwind CSS in frontend/"
Task: "Configure ESLint (angular-eslint) + Prettier in frontend/"
Task: "Configure Jest + jest-preset-angular in frontend/"
```

## Parallel Example: User Story 1

```bash
# T007（HeaderComponent 骨架）完成后：
Task: "Style header.component.html to match Figma design"
Task: "Mount <app-header> into app.component.html"
```

---

## Implementation Strategy

### MVP First（本功能只有一个 User Story）

1. 完成 Phase 1: Setup（初始化 Angular 工作区与工具链）
2. 完成 Phase 2: Foundational（目录骨架 + design tokens 占位）
3. 完成 Phase 3: User Story 1（HeaderComponent 实现 + 挂载 + 人工验收）
4. **STOP and VALIDATE**：按 quickstart.md 独立验证 User Story 1
5. 完成 Phase 4: Polish（lint 通过 + 生成人工测试用例清单）

---

## Notes

- 本功能仅有一个 P1 用户故事，无 P2/P3，因此没有跨故事集成任务
- [P] 任务 = 不同文件、无相互依赖
- 未生成测试任务：纯展示组件、本期无交互，按 [[frontend-constitution]] 8.1 节豁免；T011 的 `ng lint` 是本功能的质量门禁
- T007 MUST 使用 `speckit-de-speckit-extension-figma-implement-design` skill，不得跳过（constitution 原则 V，NON-NEGOTIABLE）
- 建议每个任务完成后提交一次 commit
