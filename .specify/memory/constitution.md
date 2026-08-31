<!--
Sync Impact Report
==================
Version change: (none, initial) → 1.0.0
Rationale: Initial ratification of the root constitution. No prior
constitution.md existed at .specify/memory/; this file is derived from and
sits above the three existing sub-constitutions (backend, frontend, project),
which remain the detailed rulebooks for their respective scopes.

Modified principles: N/A (initial creation)
Added principles:
  - I. 技术栈锁定，不可覆盖 (Technology Stack Lock-In)
  - II. 分层架构与职责边界 (Layered Architecture & Bounded Responsibility)
  - III. 统一响应契约与错误码 (Unified Response Contract & Error Codes)
  - IV. 测试先行与质量门禁 (Test-First & Quality Gate)
  - V. 设计驱动的前端开发 (Design-Driven Frontend Development)

Added sections:
  - 跨服务协作规范 (Cross-Service Collaboration Standards)
  - 研发流程与质量门禁 (Development Workflow & Quality Gates)
  - Governance

Removed sections: N/A

Deferred / follow-up items:
  - TODO(RATIFICATION_DATE): 若项目实际启动日期早于本文件创建日期，请以更早的
    实际立项日期回填，此处暂以本文件首次生成日期作为批准日期。
  - Dependent templates (plan/spec/tasks/checklist) were not modified by this
    command per its scope guard; a follow-up consistency pass over
    `.specify/templates/*.md` is recommended but out of scope here.
-->

# SHDR Platform Constitution
<!-- 项目名称推断自代码库既有约定：后端根包 com.disney.shdr.[service-name]、
Jira 工单前缀 SHDRP、数据库 db_product。若与实际项目对外名称不符，请在下次
修订时更正 PROJECT_NAME 并说明原因。 -->

## Core Principles

### I. 技术栈锁定，不可覆盖（Technology Stack Lock-In, NON-NEGOTIABLE）

- 后端服务 MUST 使用 Java 17、Spring Boot 4.0.6、springdoc-openapi 2.3.0、
  Maven、MySQL 8.0、MyBatis-Plus 3.5.16（Spring Boot 4.x 环境下 MUST 使用
  `mybatis-plus-spring-boot4-starter`）、Redis 8.6、RabbitMQ，详见
  [[backend-constitution]] 第 0、7 节。这些约束项标注为"不允许覆盖"，任何
  服务或团队不得自行替换。
- 前端服务 MUST 使用 Angular 最新稳定版（v17+，Standalone Components /
  Signals / 新控制流语法）、TypeScript `strict: true`、Angular CLI、
  Tailwind CSS + 自建组件库、Jest，详见 [[frontend-constitution]] 第 0 节。
  同样标注为"不允许覆盖"的约束项不得自行替换。
- 标注为"可覆盖"的约束项（如前端包管理器、状态管理的局部例外）允许团队按
  需调整，但须在对应子文档中说明。
- Rationale: 本仓库为 monorepo，前后端服务独立构建、独立部署；技术栈一旦
  分裂将导致工具链、CI/CD、排障经验无法在团队间复用，且违反的成本随代码量
  增长呈指数上升，因此在最外层文档中重申其不可协商性。

### II. 分层架构与职责边界（Layered Architecture & Bounded Responsibility）

- 后端服务 MUST 遵循 `api / service / repository / domain / infrastructure /
  common` 分层结构与各层禁止事项（如 controller 禁止含业务逻辑、repository
  禁止含业务判断），详见 [[backend-constitution]] 第 1 节。
- 前端服务 MUST 遵循 `core / shared / layout / features` 的按业务域划分结构，
  并严格区分智能组件（pages，负责取数）与展示组件（components，仅通过
  `input()`/`output()` 通信），详见 [[frontend-constitution]] 第 1、2 节。
- Rationale: 明确的层间边界是可测试性和可维护性的前提；边界一旦被打破
  （如展示组件直接注入 HttpClient、controller 直接写业务逻辑），后续的
  单元测试规范（原则 IV）将失去意义。

### III. 统一响应契约与错误码（Unified Response Contract & Error Codes）

- 统一响应体结构 `{code, msg, data}`、HTTP 状态码语义、业务错误码格式
  `{ApplicationID}{Type}{Code}` 唯一以 [[backend-constitution]] 第 2、3 节
  为标准；前端服务 MUST NOT 自行定义另一套响应结构，须在拦截器层
  （`unwrap.interceptor.ts` / `error.interceptor.ts`）统一解包和转换，
  业务代码不感知该结构，详见 [[frontend-constitution]] 第 5.1 节。
- 每个后端服务的 Application ID 由 [[project-constitution]] 第 1 节统一
  分配，一经分配 MUST NOT 变更或挪作他用；错误码一经发布 MUST NOT 修改
  含义，只可新增。
- 破坏性变更（响应结构变更、字段类型变更、删除已有接口或字段）MUST 升级
  API 主版本号，前端 MUST 随后端版本升级同步适配，不得为兼容旧版本自行
  实现分支逻辑。
- Rationale: 前后端独立部署、通过 REST API 通信，响应契约是双方唯一的
  耦合点；契约分裂会让每一次接口变更都变成排查噩梦。

### IV. 测试先行与质量门禁（Test-First & Quality Gate）

- 后端 Service 层与 Controller 层单元测试为 MUST，使用 JUnit 5 +
  Mockito（Controller 用 `@WebMvcTest` + MockMvc），覆盖率目标：整体
  ≥70%、Service 层 ≥80%、Controller 层 ≥70%，详见
  [[backend-constitution]] 第 4 节。
- 前端 Service / Store 层单元测试为 MUST，使用 Jest +
  `jest-preset-angular`，覆盖率目标 ≥70%，详见 [[frontend-constitution]]
  第 8 节。
- PR 提交前 MUST 本地跑通全部测试（后端 `mvn test`；前端 `ng lint` +
  `npx jest`），并在 PR 描述中注明当前覆盖率数值；MUST NOT 通过注释掉
  失败测试的方式让构建通过。
- Rationale: 覆盖率数值本身不卡 CI 合并，但作为自检项写入 PR 描述，是
  让"测试先行"从口号变成可追溯记录的最低成本手段。

### V. 设计驱动的前端开发（Design-Driven Frontend Development, NON-NEGOTIABLE）

- 涉及视觉变化的前端改动（新增页面、新增/修改组件外观）MUST 存在对应的
  Figma 设计稿链接，且该链接须同时记录在 `spec.md` 与 `tasks.md` 对应
  UI 任务条目中；设计稿未提供前 MUST NOT 先行自由发挥实现 UI。
- 实现此类 UI 任务时 MUST 使用
  `speckit-de-speckit-extension-figma-implement-design` skill（拉取设计
  上下文 → 截图校验 → 转换为标准工作流），MUST NOT 绕开该 skill 直接
  凭空实现，详见 [[frontend-constitution]] 第 4.1 节。
- Rationale: 该项目前端定位为电商/SaaS 产品类 UI，像素级还原 Figma 是
  产品要求；跳过设计稿直接实现会导致返工成本远高于等待设计产出的成本。

## 跨服务协作规范

- 本仓库为 monorepo，`frontend-service`（Angular）与 `backend-service`
  （Java / Spring Boot）两个服务独立构建、独立部署，仅通过 REST API 通信，
  详见 [[project-constitution]] 第 0 节。
- 两个服务的功能分支命名策略 MUST 保持一致：
  `[Jira Ticket ID|Feature]/<工单号>-简短描述`（如
  `SHDRP-433819/project-initialization`）。
- 新增后端服务时 MUST 在 [[project-constitution]] 第 1 节补充新的
  Application ID，MUST NOT 复用已分配号段（如 `backend-service` 的
  `0100`）。

## 研发流程与质量门禁

- PR 提交前 MUST 完成各自子文档的自检清单：后端见
  [[backend-constitution]] 第 4.7 节，前端见代码规范工具章节
  （[[frontend-constitution]] 第 9.2 节，`ng lint` + `npx jest` 全部通过）。
- 本地快速调试与 CI/CD 正式验证须使用不同的构建命令（后端见
  [[backend-constitution]] 第 4.9 节），MUST NOT 在 CI/CD 中跳过测试
  编译或执行。
- Swagger UI 集成为后端 MUST 项（详见 [[backend-constitution]] 第 2.8
  节），非生产环境 MUST 保持可访问，用于前后端联调对齐接口契约。

## Governance

- 文档层级：本文件（`.specify/memory/constitution.md`）是本项目技术宪法
  的最高治理文件；[[project-constitution]] 是跨服务共享事项的索引与细则；
  [[backend-constitution]]、[[frontend-constitution]] 是各自服务的实现
  细则。下层文档的具体规则 MUST NOT 与本文件的 Core Principles 冲突；
  如有冲突，以本文件为准，并须启动修订流程更新下层文档。
- 修订流程：任何对本文件 Core Principles 的增删或语义变更，MUST 在 PR
  描述中说明修订原因，并按语义化版本规则更新下方版本号——
  MAJOR：移除或重新定义某条原则（不兼容变更）；MINOR：新增原则或对现有
  原则做实质性扩展；PATCH：措辞澄清、错别字修正等非语义性修改。
- 合规审查：涉及后端的 PR 须同时满足本文件与 [[backend-constitution]]；
  涉及前端的 PR 须同时满足本文件与 [[frontend-constitution]]；涉及双方
  的改动（如响应契约、Application ID）以 [[project-constitution]] 第 2
  节的跨服务约定为准。
- 标注为"不允许覆盖"/NON-NEGOTIABLE 的约束项，任何团队或子项目不得自行
  变更，如确有必要须先修订本文件及相应子文档。

**Version**: 1.0.0 | **Ratified**: 2026-08-25 | **Last Amended**: 2026-08-25
