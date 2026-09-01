# 手动测试用例：商城首页 Header（欢迎词与快捷入口）

**Feature**: `001-homepage-header`
**生成依据**: tasks.md 中已完成任务涉及的 3 个行为相关文件（静态代码分析，非 spec 直转）：`frontend/src/app/layout/header/header.component.ts`、`frontend/src/app/layout/header/header.component.html`、`frontend/src/app/app.html`
**生成时间**: 2026-08-31

## User Story 1 - 浏览首页 Header 获取欢迎信息与快捷入口 (Priority: P1)

| 编号 | 优先级 | 测试点 | 前置条件 | 测试步骤 | 预期结果 | 关联文件 | 实际结果 | 执行人/日期 |
|---|---|---|---|---|---|---|---|---|
| MT-001-01 | P1 | Header 挂载在首页顶部 | 应用已启动（`ng serve`） | 1. 打开商城首页 | 页面最顶部（`<router-outlet>` 内容之前）渲染出 `<app-header>` 区域 | `frontend/src/app/app.html` | | |
| MT-001-02 | P1 | 欢迎词文案渲染正确 | 首页已加载 | 1. 观察 header 左侧文字 | 显示固定文案 "Welcome to worldwide Megamart!"，不因是否登录而变化 | `frontend/src/app/layout/header/header.component.html` | | |
| MT-001-03 | P1 | "Deliver to" 入口渲染正确 | 首页已加载 | 1. 观察 header 右侧第一个入口 | 显示定位图标 + 文案 "Deliver to 423651"，其中 "423651" 为加粗字重 | `frontend/src/app/layout/header/header.component.html` | | |
| MT-001-04 | P1 | "Track your order" 入口渲染正确 | 首页已加载 | 1. 观察 header 右侧第二个入口 | 显示配送卡车图标 + 文案 "Track your order" | `frontend/src/app/layout/header/header.component.html` | | |
| MT-001-05 | P1 | "All Offers" 入口渲染正确 | 首页已加载 | 1. 观察 header 右侧第三个入口 | 显示优惠券图标 + 文案 "All Offers" | `frontend/src/app/layout/header/header.component.html` | | |
| MT-001-06 | P1 | 两条分割线渲染正确 | 首页已加载 | 1. 观察三个入口之间的间隔区域 | "Deliver to" 与 "Track your order" 之间、"Track your order" 与 "All Offers" 之间各显示一条竖直分割线，共两条 | `frontend/src/app/layout/header/header.component.html` | | |
| MT-001-07 | P1 | 点击 "Deliver to" 无跳转/无副作用 | 首页已加载 | 1. 点击 "Deliver to 423651" 文案或图标 | 页面 URL 不变，无路由跳转，无弹窗或其他可观察变化（组件未绑定任何点击事件） | `frontend/src/app/layout/header/header.component.ts` | | |
| MT-001-08 | P1 | 点击 "Track your order" 无跳转/无副作用 | 首页已加载 | 1. 点击 "Track your order" 文案或图标 | 页面 URL 不变，无路由跳转，无弹窗或其他可观察变化 | `frontend/src/app/layout/header/header.component.ts` | | |
| MT-001-09 | P1 | 点击 "All Offers" 无跳转/无副作用 | 首页已加载 | 1. 点击 "All Offers" 文案或图标 | 页面 URL 不变，无路由跳转，无弹窗或其他可观察变化 | `frontend/src/app/layout/header/header.component.ts` | | |
| MT-001-10 | P1 | 桌面宽度下不换行、不遮挡、不溢出 | 首页已加载 | 1. 将浏览器窗口宽度调整为 1280px 及以上（如 1280px、1440px、1920px） | Header 各元素保持单行显示（欢迎词与三个入口均不换行），不出现横向滚动条，右侧三个入口不与欢迎词重叠 | `frontend/src/app/layout/header/header.component.html` | | |
