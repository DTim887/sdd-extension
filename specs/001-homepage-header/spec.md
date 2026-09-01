# Feature Specification: 商城首页 Header（欢迎词与快捷入口）

**Feature Branch**: `SHDRP-434496/homepage-header`

**Created**: 2026-08-31

**Status**: Draft

**Input**: JIRA ticket SHDRP-434496 — 实现一个商城首页的 header，包含欢迎词、deliver to、track your order、All Offers 三个快捷入口，三个快捷入口两两之间各有一条分割线。经需求质量自检澄清：目标平台为 Web（PC 网页）；欢迎词为固定文案，不区分登录状态；三个入口本期均为静态展示，不涉及跳转或点击交互；已提供 Figma 设计稿链接（见下）。

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 浏览首页 Header 获取欢迎信息与快捷入口 (Priority: P1)

作为访问商城首页的用户，我希望一进入首页就能在顶部看到欢迎信息以及 deliver to、track your order、All Offers 三个快捷入口，以便快速了解页面提供的关键信息与功能分区。

**Why this priority**: Header 是首页最上方的常驻区域，是本次唯一交付物；其展示内容与视觉呈现即是本功能的全部价值，无法再拆分出更小的独立可交付切片。

**Independent Test**: 打开商城首页，无需任何前置操作即可在页面顶部看到欢迎词、三个快捷入口文案及入口间的两条分割线，视觉与 Figma 设计稿一致。

**Acceptance Scenarios**:

1. **Given** 用户打开商城首页，**When** 页面加载完成，**Then** 页面顶部 header 区域展示固定文案的欢迎词。
2. **Given** 用户打开商城首页，**When** 页面加载完成，**Then** header 区域依次展示 deliver to、track your order、All Offers 三个快捷入口，且相邻入口之间各显示一条分割线（共两条）。
3. **Given** 用户已登录或未登录，**When** 页面加载完成，**Then** 欢迎词内容保持一致（不因登录状态变化）。
4. **Given** 用户点击 deliver to、track your order 或 All Offers 任一入口，**When** 点击发生，**Then** 页面不产生任何跳转或状态变化（本期为静态展示）。

### Edge Cases

- 页面宽度小于桌面标准宽度（如平板/移动端宽度）时的展示不在本次范围内（见 Assumptions）。
- 欢迎词文案本身长度变化（如未来改为多语言）导致换行或溢出的情况，本次不处理，按设计稿固定尺寸展示。

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 系统 MUST 在商城首页顶部展示一个 header 区域，包含欢迎词、deliver to、track your order、All Offers 四个视觉元素。
- **FR-002**: Header MUST 显示固定文案的欢迎词，内容不因用户登录/未登录状态而改变。
- **FR-003**: Header MUST 依次展示 deliver to、track your order、All Offers 三个快捷入口，且三个入口两两之间各显示一条分割线（共两条分割线）。
- **FR-004**: 本期 deliver to、track your order、All Offers 三个入口 MUST 仅作静态展示，不绑定任何点击跳转或交互行为。
- **FR-005**: Header 的视觉呈现（布局、间距、字体、颜色、分割线样式等）MUST 与以下 Figma 设计稿保持一致：
  - 整体骨架：https://www.figma.com/design/xKfXcdxRX8fLK8Grc46Vbw/Ecommerce-Website-Design--Community-?node-id=2-63&t=sQv0surSxl0haT13-0
  - 欢迎词：https://www.figma.com/design/xKfXcdxRX8fLK8Grc46Vbw/Ecommerce-Website-Design--Community-?node-id=2-64&t=sQv0surSxl0haT13-0
  - deliver to：https://www.figma.com/design/xKfXcdxRX8fLK8Grc46Vbw/Ecommerce-Website-Design--Community-?node-id=2-108&t=sQv0surSxl0haT13-0
  - track your order：https://www.figma.com/design/xKfXcdxRX8fLK8Grc46Vbw/Ecommerce-Website-Design--Community-?node-id=2-109&t=sQv0surSxl0haT13-0
  - All Offers：https://www.figma.com/design/xKfXcdxRX8fLK8Grc46Vbw/Ecommerce-Website-Design--Community-?node-id=2-116&t=sQv0surSxl0haT13-0
  - deliver to 与 track your order 之间分割线：https://www.figma.com/design/xKfXcdxRX8fLK8Grc46Vbw/Ecommerce-Website-Design--Community-?node-id=2-124&t=sQv0surSxl0haT13-0
  - track your order 与 All Offers 之间分割线：https://www.figma.com/design/xKfXcdxRX8fLK8Grc46Vbw/Ecommerce-Website-Design--Community-?node-id=2-125&t=sQv0surSxl0haT13-0

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 用户打开商城首页后，无需滚动即可在首屏看到欢迎词及三个快捷入口文案。
- **SC-002**: Header 的视觉还原度经人工对照 Figma 设计稿验收通过（布局、间距、字体、颜色、分割线均一致）。
- **SC-003**: 在桌面浏览器标准宽度（≥1280px）下，header 内容不换行、不遮挡、不溢出。

## Assumptions

- 目标平台仅为 Web（PC 网页），移动端/响应式适配不在本次范围内。
- 三个快捷入口（deliver to、track your order、All Offers）本期仅做静态展示，跳转/交互逻辑留待后续迭代另行定义与澄清。
- 欢迎词为固定文案，不依赖用户登录状态或个性化数据。
- Figma 设计稿为本次 UI 视觉呈现的唯一依据，具体文案、颜色、间距、字体等细节以设计稿为准。
