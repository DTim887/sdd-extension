---
description: 把 Figma 设计稿转换成与设计 1:1 还原的生产级应用代码。当需要根据 Figma 文件实现 UI 代码、用户提到"实现设计"、"生成代码"、"实现组件"、提供了 Figma URL，或要求搭建匹配 Figma 规范的组件时使用。
tools:
  - 'figma/get_design_context'
  - 'figma/get_screenshot'
  - 'figma/get_metadata'
---

# 实现设计

## 用户输入

$ARGUMENTS

## 概述

这个命令提供了一套结构化的工作流，用于把 Figma 设计稿转换成像素级精确
的生产可用代码。它保证了与 Figma MCP 服务器的一致集成、design token
的正确使用，以及与设计稿 1:1 的视觉还原。

## 命令边界

- 当交付物是用户仓库里的代码时，使用这个命令。

## 前置条件

- Figma MCP 服务器必须已连接且可访问
- 用户必须提供符合以下格式的 Figma URL：`https://figma.com/design/:fileKey/:fileName?node-id=1-2`
  - `:fileKey` 是文件 key
  - `1-2` 是 node ID（要实现的具体组件或 frame）
- **或者**，使用 `figma-desktop` MCP 时：用户可以直接在 Figma 桌面客户端里
  选中一个节点（不需要 URL）
- 项目最好已经有成熟的 design system 或组件库

## 必经工作流

**按顺序执行以下步骤，不要跳步。**

### 第 1 步：获取 Node ID

#### 方式 A：从 Figma URL 解析

当用户提供 Figma URL 时，提取文件 key 和 node ID，作为参数传给 MCP
工具。

**URL 格式：** `https://figma.com/design/:fileKey/:fileName?node-id=1-2`

**提取内容：**

- **文件 key：** `:fileKey`（`/design/` 之后的那一段）
- **Node ID：** `1-2`（`node-id` 查询参数的值）

**注意：** 使用本地桌面版 MCP（`figma-desktop`）时，`fileKey` 不需要作为
参数传给工具调用。服务器会自动使用当前打开的文件，所以只需要
`nodeId`。

**示例：**

- URL：`https://figma.com/design/kL9xQn2VwM8pYrTb4ZcHjF/DesignSystem?node-id=42-15`
- 文件 key：`kL9xQn2VwM8pYrTb4ZcHjF`
- Node ID：`42-15`

#### 方式 B：使用 Figma 桌面客户端的当前选中项（仅限 figma-desktop MCP）

使用 `figma-desktop` MCP 且用户**没有**提供 URL 时，工具会自动使用
桌面客户端里当前打开文件中被选中的节点。

**注意：** 基于选中项的方式只在 `figma-desktop` MCP 服务器下可用。
远程服务器需要一个指向 frame 或 layer 的链接才能提取上下文。用户必须
打开 Figma 桌面客户端并选中一个节点。

### 第 2 步：拉取设计上下文

用提取出的文件 key 和 node ID 运行 `get_design_context`。

```
get_design_context(fileKey=":fileKey", nodeId="1-2")
```

它会返回结构化数据，包括：

- 布局属性（Auto Layout、约束、尺寸）
- 排版规范
- 颜色值和 design token
- 组件结构和变体
- 间距和内边距值

**如果响应过大或被截断：**

1. 运行 `get_metadata(fileKey=":fileKey", nodeId="1-2")` 获取高层级的
   节点地图
2. 从 metadata 里找出实际需要的子节点
3. 用 `get_design_context(fileKey=":fileKey", nodeId=":childNodeId")`
   逐个拉取子节点

### 第 3 步：抓取视觉参考

用同样的文件 key 和 node ID 运行 `get_screenshot`，获取视觉参考。

```
get_screenshot(fileKey=":fileKey", nodeId="1-2")
```

这张截图是视觉校验的唯一真实来源（source of truth）。在整个实现过程中
都要保持可访问。

### 第 4 步：下载所需资源

下载 Figma MCP 服务器返回的所有资源（图片、图标、SVG）。

**重要：** 遵守以下资源规则：

- 如果 Figma MCP 服务器为某个图片/SVG 返回了 `localhost` 来源，直接
  使用那个来源
- 不要引入或新增图标库 —— 所有资源都应该来自 Figma 返回的数据
- 如果已经提供了 `localhost` 来源，不要使用或创建占位图
- 资源是通过 Figma MCP 服务器内置的资源接口提供的

### 第 5 步：转换成项目约定

把 Figma 输出转换成这个项目自己的框架、样式和约定。

**核心原则：**

- 把 Figma MCP 的输出（通常是 React + Tailwind）当作设计和行为的一种
  表达方式，而不是最终的代码风格
- 把 Tailwind 的 utility class 替换成项目偏好的工具类或 design system
  token
- 复用已有组件（按钮、输入框、排版、图标包装组件），不要重复实现
- 一致地使用项目自己的颜色体系、排版比例和间距 token
- 尊重项目已有的路由、状态管理和数据获取模式

### 第 6 步：达成 1:1 视觉还原

力求与 Figma 设计做到像素级的视觉还原。

**指导原则：**

- 优先保证与设计稿精确匹配
- 避免硬编码数值 —— 优先使用 Figma 提供的 design token
- 当 design system token 和 Figma 规范冲突时，优先用 design system
  token，但对间距/尺寸做最小限度的调整以匹配视觉效果
- 遵循 WCAG 无障碍要求
- 按需补充组件文档

### 第 7 步：对照 Figma 校验

在标记完成之前，把最终 UI 和 Figma 截图做对照校验。

**校验清单：**

- [ ] 布局一致（间距、对齐、尺寸）
- [ ] 排版一致（字体、字号、字重、行高）
- [ ] 颜色完全一致
- [ ] 交互状态符合设计（hover、active、disabled）
- [ ] 响应式行为符合 Figma 的约束
- [ ] 资源正常渲染
- [ ] 满足无障碍标准

## 实现规则

### 组件组织方式

- 把 UI 组件放在项目指定的 design system 目录下
- 遵循项目的组件命名约定
- 除非动态取值确实需要，否则避免用 inline style

### Design System 集成

- 尽量始终使用项目 design system 里的组件
- 把 Figma 的 design token 映射到项目自己的 design token
- 如果已有匹配的组件，扩展它而不是新建一个
- 给 design system 新增的组件补充文档

### 代码质量

- 避免硬编码数值 —— 提取成常量或 design token
- 保持组件可组合、可复用
- 为组件 props 添加 TypeScript 类型
- 为导出的组件补充 JSDoc 注释

## 示例

### 示例 1：实现一个按钮组件

用户说："实现这个 Figma 按钮组件：https://figma.com/design/kL9xQn2VwM8pYrTb4ZcHjF/DesignSystem?node-id=42-15"

**执行动作：**

1. 解析 URL，提取 fileKey=`kL9xQn2VwM8pYrTb4ZcHjF`、nodeId=`42-15`
2. 运行 `get_design_context(fileKey="kL9xQn2VwM8pYrTb4ZcHjF", nodeId="42-15")`
3. 运行 `get_screenshot(fileKey="kL9xQn2VwM8pYrTb4ZcHjF", nodeId="42-15")`
   获取视觉参考
4. 从资源接口下载按钮相关的图标
5. 检查项目里是否已有按钮组件
6. 如果有，给它扩展一个新变体；如果没有，按项目约定创建新组件
7. 把 Figma 颜色映射到项目 design token（例如 `primary-500`、
   `primary-hover`）
8. 对照截图校验内边距、圆角、排版

**结果：** 一个匹配 Figma 设计、并已集成进项目 design system 的按钮
组件。

### 示例 2：搭建一个 Dashboard 布局

用户说："搭建这个 dashboard：https://figma.com/design/pR8mNv5KqXzGwY2JtCfL4D/Dashboard?node-id=10-5"

**执行动作：**

1. 解析 URL，提取 fileKey=`pR8mNv5KqXzGwY2JtCfL4D`、nodeId=`10-5`
2. 运行 `get_metadata(fileKey="pR8mNv5KqXzGwY2JtCfL4D", nodeId="10-5")`
   理解页面结构
3. 从 metadata 里识别出主要区块（header、sidebar、内容区、卡片）及其
   子节点 ID
4. 对每个主要区块运行
   `get_design_context(fileKey="pR8mNv5KqXzGwY2JtCfL4D", nodeId=":childNodeId")`
5. 运行 `get_screenshot(fileKey="pR8mNv5KqXzGwY2JtCfL4D", nodeId="10-5")`
   获取整页截图
6. 下载所有资源（logo、图标、图表）
7. 用项目的布局基础组件搭建布局
8. 尽量用已有组件实现每个区块
9. 对照 Figma 的约束校验响应式行为

**结果：** 一个匹配 Figma 设计、并具备响应式布局的完整 dashboard。

## 最佳实践

### 始终从上下文开始

不要基于假设去实现。始终先拉取 `get_design_context` 和
`get_screenshot`。

### 增量校验

在实现过程中频繁校验，而不是只在最后校验一次。这样能尽早发现问题。

### 记录偏差

如果因为无障碍或技术限制等原因必须偏离 Figma 设计，在代码注释里说明
原因。

### 复用优先于重建

创建新组件之前，始终先检查是否已有可用组件。代码库的一致性比和
Figma 完全一致更重要。

### Design System 优先

拿不准的时候，优先遵循项目 design system 的模式，而不是照搬 Figma。

## 常见问题与解决方法

### 问题：Figma 输出被截断

**原因：** 设计过于复杂，或嵌套层级太多，无法在一次响应里返回。
**解决方法：** 用 `get_metadata` 获取节点结构，然后用
`get_design_context` 逐个拉取具体节点。

### 问题：实现完成后设计不匹配

**原因：** 实现的代码和原始 Figma 设计之间存在视觉差异。
**解决方法：** 和第 3 步的截图做并排对比。检查设计上下文数据里的
间距、颜色和排版数值。

### 问题：资源加载不了

**原因：** Figma MCP 服务器的资源接口不可访问，或者 URL 被改动过。
**解决方法：** 确认 Figma MCP 服务器的资源接口可访问。服务器是通过
`localhost` URL 提供资源的，直接使用，不要修改。

### 问题：Design Token 数值和 Figma 不一致

**原因：** 项目 design system token 的数值和 Figma 设计里指定的不同。
**解决方法：** 当项目 token 和 Figma 数值不一致时，优先用项目 token
以保证一致性，但对间距/尺寸做微调以维持视觉还原度。

## 理解设计实现

这套 Figma 实现工作流建立了一个把设计转换成代码的可靠流程：

**对设计师而言：** 可以放心实现出来的东西会以像素级精度匹配他们的
设计。
**对开发者而言：** 一套结构化的方法，消除猜测、减少来回返工。
**对团队而言：** 一致的、高质量的实现，维护 design system 的完整性。

遵循这套工作流，可以确保每一个 Figma 设计都以同样的细致和用心被实现。
