# Quickstart: 商城首页 Header（欢迎词与快捷入口）

**Feature**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

用于人工验证 header 实现是否符合 spec.md 中的验收场景（User Story 1）与 Figma 设计稿（见 spec.md FR-005）。

## Prerequisites

- 已完成 `frontend/` 依赖安装（`npm install`，于 `frontend/` 目录下）。
- 已按 plan.md 的 Project Structure 在 `frontend/src/app/layout/header/` 实现 `HeaderComponent`，并接入首页布局。

## Run

```bash
cd frontend
ng serve
```

浏览器打开开发服务器地址（默认 `http://localhost:4200`），导航至商城首页。

## Validation Scenarios

对照 spec.md 中的 Acceptance Scenarios 逐项核对：

1. **欢迎词展示**：首页顶部 header 区域可见固定文案的欢迎词，无需滚动（对应 SC-001）。
2. **三个快捷入口 + 两条分割线**：依次可见 deliver to、track your order、All Offers 三个入口文案，相邻入口之间各有一条分割线（共两条）。
3. **登录状态不影响欢迎词**：分别在已登录、未登录两种状态下访问首页，欢迎词文案内容保持一致。
4. **入口为静态展示**：依次点击 deliver to、track your order、All Offers，确认页面不发生任何跳转、路由变化或可观察的状态变化。
5. **视觉还原**：对照 spec.md FR-005 列出的 7 个 Figma 节点链接，逐一核对布局、间距、字体、颜色、分割线样式（对应 SC-002）。
6. **桌面宽度下不溢出**：浏览器窗口宽度 ≥1280px 时，header 内容不换行、不遮挡、不溢出（对应 SC-003）。

## Expected Outcome

以上 6 项全部通过即视为该功能实现符合 spec.md 验收标准；如有不符，参照对应 FR-00x / SC-00x 编号定位问题。

## Notes

- 本功能无数据模型、无 API 契约（见 data-model.md），因此本 quickstart 不包含接口层验证步骤。
- 本组件按 [[frontend-constitution]] 第 8.1 节豁免强制单元测试，本 quickstart 是本功能唯一的正式验收方式；建议在 `/speckit-implement` 完成后另行运行 `speckit-de-speckit-extension-generate-manual-tests` 生成更完整的人工测试用例清单。
