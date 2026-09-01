# Research: 商城首页 Header（欢迎词与快捷入口）

**Feature**: [spec.md](./spec.md) | **Date**: 2026-08-31

Technical Context 中无遗留 `NEEDS CLARIFICATION` 项——需求已经过 `requirement-self-check` 澄清，技术栈由项目 constitution 强制锁定，无需额外调研候选方案。以下记录关键决策的依据。

## Decision 1: 组件放置位置

- **Decision**: 新建 `frontend/src/app/layout/header/header.component.ts`，作为页面骨架层组件。
- **Rationale**: [[frontend-constitution]] 第 1.1 节明确 `layout/` 目录职责为 "Header/Footer/Nav"；该组件不承载业务数据、不属于任何 `features/*` 业务域，符合展示型页面骨架定位。
- **Alternatives considered**: 放入 `shared/components/`——排除，因为 `shared/` 定位是"跨 feature 复用、无业务归属"的通用组件（如按钮、卡片），而 header 是页面级唯一骨架元素，不是可复用的通用 UI 片元；放入某个 `features/*/components/`——排除，因为 header 不属于任何单一业务域。

## Decision 2: 是否需要状态管理 / API 调用

- **Decision**: 不引入 Signal Store、不注入 `HttpClient`。
- **Rationale**: 需求澄清已确认欢迎词为固定文案（不依赖登录状态），三个入口本期为纯静态展示（无跳转、无数据请求）。[[frontend-constitution]] 第 2.2 节禁止展示组件注入 `HttpClient` 或业务 service。
- **Alternatives considered**: 预留 `AuthStore` 注入以便未来欢迎词根据登录态变化——排除，属于为假设中的未来需求提前设计，违反"不做投机性设计"的原则；待后续 ticket 明确该需求后再引入。

## Decision 3: 单元测试策略

- **Decision**: 不强制为 `header.component.ts` 编写 Jest 单元测试。
- **Rationale**: [[frontend-constitution]] 第 8.1 节："纯展示组件（无逻辑分支）：可不测"。本组件无 `computed()`、无条件分支、无用户交互事件，符合豁免条件；仍需通过 `ng lint`。
- **Alternatives considered**: 编写渲染快照测试——评估后认为对纯静态模板收益低于维护成本，暂不引入；如后续入口恢复点击交互，需重新评估并按 8.2 节"用户交互"场景补测。

## Decision 4: 样式还原方式

- **Decision**: 使用 Tailwind CSS 语义化 class + `tailwind.config.js` 中的 design tokens 还原 Figma 设计稿（间距、颜色、字体、分割线样式）。
- **Rationale**: [[frontend-constitution]] 第 4 节强制要求（不允许覆盖的样式方案），且禁止 magic number 颜色/间距值。
- **Alternatives considered**: 组件私有 `.scss`——仅在 Tailwind 无法表达的复杂样式（如动画）时使用；本组件为静态布局，预期无需使用。

## Decision 5: Angular 版本选择（实现阶段追加）

- **Decision**: 使用 Angular 21.2（CLI `@angular/cli@21`），而非当前 npm registry 上的最新 major 版本（22.x）。
- **Rationale**: 实现环境 Node 版本为 v22.18.0；Angular CLI 22.x 要求 `^22.22.3 || ^24.15.0 || >=26.0.0`，当前 Node 不满足；Angular CLI 21.x 要求 `^20.19.0 || ^22.12.0 || >=24.0.0`，v22.18.0 落在 `^22.12.0` 区间内，可正常安装运行。21.2 仍满足 [[frontend-constitution]] 第 0 节"v17+"的下限要求，且包含 Standalone Components / Signals / 新控制流语法等全部强制特性。
- **Alternatives considered**: 升级本机 Node 版本以使用 22.x——超出本次任务范围（涉及开发环境变更，需用户另行决定）；降级到更旧的 Angular 版本（如 19.x）——排除，21.x 已是当前环境下可用的最新稳定版，没有必要进一步降级。
- **Follow-up**: 待开发环境 Node 升级到 `^22.22.3`/`^24.15.0`/`>=26.0.0` 后，可运行 `ng update` 升级到 Angular 22.x 最新稳定版，以完全对齐"最新稳定版"要求。

## Decision 4a: Tailwind CSS 主版本选择（实现阶段追加）

- **Decision**: 使用 Tailwind CSS v3.4（而非 npm 上最新的 v4.x）。
- **Rationale**: Angular esbuild 构建器（`@angular/build`）内置"零配置"Tailwind 探测逻辑——只要检测到项目根存在 `tailwind.config.js`，就会硬编码 `require('tailwindcss')` 并将其当作 v3 风格的 PostCSS 插件工厂直接调用（`tailwind.default({config})`），不读取也不尊重自定义 `postcss.config.js`。Tailwind v4 已将 PostCSS 插件拆分到独立的 `@tailwindcss/postcss` 包，`tailwindcss` 包本身作为 PostCSS 插件调用会直接抛错（"tailwindcss package moved..."），与 Angular 的该内置逻辑不兼容。v3.4 与该零配置检测天然兼容，且 constitution 第 4.2 节"design tokens MUST 在 `tailwind.config.js` 中统一定义"的表述本身就是 v3 风格 JS 配置的写法。
- **Alternatives considered**: 强行接入 v4（移除 `tailwind.config.js`，改用 CSS `@theme` 定义 tokens）——排除，会直接违反 constitution 关于 tokens 必须在 `tailwind.config.js` 中定义的字面要求，且需要绕开 Angular 内置支持手动 wiring，增加不必要的复杂度；升级到更新的 `@angular/build` 版本以获得原生 v4 支持——已是当前环境可用的最新 Angular 主版本（21.x，见 Decision 5），无更高版本可用。
- **Follow-up**: 待 Angular 官方构建工具原生支持 Tailwind v4（`@tailwindcss/postcss`）零配置检测后，可重新评估升级。

## Decision 6: 测试运行器与脚手架默认值的冲突（实现阶段追加）

- **Decision**: `ng new` 在 Angular 21 中默认引入 Vitest 而非 Jest；需在 T004 中手动替换为 Jest + jest-preset-angular。
- **Rationale**: [[frontend-constitution]] 第 0 节将"单元测试 MUST 使用 Jest + jest-preset-angular"标注为不允许覆盖的约束项，脚手架默认值不能作为例外。
- **Alternatives considered**: 保留 Vitest——排除，直接违反 constitution 的 NON-NEGOTIABLE 约束。

## Decision 7: Angular 21 默认 Zoneless（实现阶段追加）

- **Decision**: 沿用 Angular 21 脚手架的默认值——不引入 `zone.js`，应用为 zoneless（无 `provideZonelessChangeDetection()` 需要显式调用，`ng new` 生成的 `app.config.ts` 已不含 zone.js 依赖）；Jest 测试环境相应使用 `jest-preset-angular/setup-env/zoneless` 的 `setupZonelessTestEnv()`。
- **Rationale**: Angular 21 起新项目默认即为 zoneless，这与 [[frontend-constitution]] 第 3.1 节"状态 MUST 使用 `signal()`/`computed()`/`effect()` 管理，禁止手动 `subscribe()` 后赋值"的精神完全一致（zoneless 依赖 Signals 驱动变更检测）；本组件本身也不使用 Zone.js 特性。
- **Alternatives considered**: 手动引入 `zone.js` 并配置为 zone-based 应用——排除，无必要向后兼容一个未使用的运行时机制，且与 constitution 倡导的 Signals-first 方向相反。

## 待实现阶段确认事项

- 实现该 UI 任务时 MUST 使用 `speckit-de-speckit-extension-figma-implement-design` skill（拉取设计上下文 → 截图校验 → 转换为标准工作流），不得绕开该 skill 直接凭空实现（[[frontend-constitution]] 第 4.1 节，spec.md FR-005 已记录全部 7 个 Figma 链接）。
