# Implementation Plan: 商城首页 Header（欢迎词与快捷入口）

**Branch**: `SHDRP-434496/homepage-header` | **Date**: 2026-08-31 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-homepage-header/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

在商城首页顶部实现一个纯展示型 header 区域：固定文案欢迎词 + deliver to / track your order / All Offers 三个静态快捷入口（本期无点击跳转），入口间各一条分割线。技术方案：作为 `layout/` 下的展示型 Angular Standalone 组件实现，样式使用 Tailwind CSS 按 Figma 设计稿 1:1 还原，不涉及后端 API 调用或数据持久化。

## Technical Context

**Language/Version**: TypeScript（`strict: true`），Angular 最新稳定版（v17+，Standalone Components / Signals / 新控制流语法）

**Primary Dependencies**: Angular CLI（esbuild/application builder）、Tailwind CSS + 自建组件库（`shared/components/`）

**Storage**: N/A（纯静态展示，无数据持久化，无接口调用）

**Testing**: Jest + jest-preset-angular；该组件为纯展示组件、无逻辑分支（本期无点击交互），按 [[frontend-constitution]] 第 8.1 节可不强制编写单元测试，但仍须通过 `ng lint`

**Target Platform**: Web 桌面浏览器（PC，标准宽度 ≥1280px）；移动端/响应式不在本次范围内

**Project Type**: web（monorepo 中的 `frontend/` 子项目，本次功能仅涉及前端，不改动 `backend/`）

**Performance Goals**: 无特殊性能指标，遵循标准首屏渲染体验（随首页整体加载，无额外异步请求）

**Constraints**: 像素级还原 Figma 设计稿（FR-005）；禁止引入 Angular Material / PrimeNG；颜色/间距/字体等 MUST 通过 Tailwind Design Tokens 表达，禁止 magic number

**Scale/Scope**: 单个 header 展示组件，对应 7 个 Figma 节点（骨架 + 欢迎词 + 3 入口 + 2 分割线），无路由、无 API、无状态管理需求

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| 原则 | 评估 | 结论 |
| --- | --- | --- |
| I. 技术栈锁定 | 使用规定的 Angular v17+ / TypeScript strict / Tailwind CSS，不引入新框架或替代方案 | PASS |
| II. 分层架构与职责边界 | Header 属于 `layout/`（页面骨架）纯展示组件，不注入 `HttpClient`，不含业务逻辑 | PASS |
| III. 统一响应契约与错误码 | 本功能不调用任何后端 API，无响应契约相关内容 | N/A |
| IV. 测试先行与质量门禁 | 纯展示组件、无逻辑分支、本期无交互，按 [[frontend-constitution]] 8.1 节豁免单元测试强制项；仍须通过 `ng lint` | PASS（豁免有据可查） |
| V. 设计驱动的前端开发（NON-NEGOTIABLE） | 已在 spec.md FR-005 记录完整 Figma 链接；实现 MUST 使用 `speckit-de-speckit-extension-figma-implement-design` skill，禁止绕开凭空实现 | PASS（将在 tasks.md 中体现） |

无违反项，Complexity Tracking 表无需填写。

## Project Structure

### Documentation (this feature)

```text
specs/001-homepage-header/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

无 `contracts/` 目录：本功能不对外暴露任何接口（无 API、无 CLI、无库导出），属于纯内部静态 UI 展示，故跳过。

### Source Code (repository root)

```text
frontend/
├── src/
│   ├── app/
│   │   ├── layout/
│   │   │   └── header/
│   │   │       ├── header.component.ts
│   │   │       ├── header.component.html
│   │   │       └── header.component.spec.ts   # 可选，见 Technical Context › Testing
│   │   └── app.config.ts
│   ├── assets/
│   └── environments/
└── tailwind.config.js                          # 补充/复用 header 所需 design tokens
```

**Structure Decision**: Web application（monorepo `frontend/` + `backend/`），本功能仅涉及 `frontend/`。Header 作为页面骨架组件放在 `frontend/src/app/layout/header/`，符合 [[frontend-constitution]] 第 1.1 节 `layout/` 目录定位（Header/Footer/Nav）；不新建 `features/` 模块，不改动 `backend/`。

## Complexity Tracking

*No entries — Constitution Check 无违反项，无需 justify。*
