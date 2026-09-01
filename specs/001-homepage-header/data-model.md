# Data Model: 商城首页 Header（欢迎词与快捷入口）

**Feature**: [spec.md](./spec.md) | **Date**: 2026-08-31

本功能不涉及任何数据实体：

- 欢迎词为固定文案（编译期/模板内容，非动态数据）。
- deliver to / track your order / All Offers 三个入口本期为纯静态展示，不绑定跳转目标、不读取任何业务数据。
- 无后端 API 调用，无本地状态需要建模（不需要 Signal Store）。

如后续迭代为入口引入跳转目标、动态文案或登录态相关内容，须在对应 ticket 中重新澄清并更新本文件。
