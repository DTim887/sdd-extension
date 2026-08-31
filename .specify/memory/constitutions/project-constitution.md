# Project Constitution

本文档是项目级总览/索引，描述本项目包含哪些服务、各自职责与目录，以及跨服务共享的约定。每个服务的具体开发规范以各自的 constitution 文件为准，本文不重复其内容。

## 0. 服务概览

| 服务 | 目录 | 职责 | 遵循规范 |
| --- | --- | --- | --- |
| frontend-service | `frontend-service/` | 官网 UI 开发（Angular） | [[frontend-constitution]] |
| backend-service | `backend-service/` | 后台服务开发（Java / Spring Boot） | [[backend-constitution]] |

两个服务同属一个仓库（monorepo），独立构建、独立部署，通过 REST API 通信。

## 1. Application ID 分配

Application ID 用于 backend-service 业务错误码的拼接（格式 `{AppID}{Type}{Code}`，详见 [[backend-constitution]] 第 3 节）。

| 服务 | Application ID | 用途 |
| --- | --- | --- |
| backend-service | `0100` | 业务错误码前缀，如 `0100A0001` |

- Application ID 一经分配不得变更或挪作他用
- 若未来新增其他后端服务，须在本表补充新的 Application ID，禁止复用 `0100`

## 2. 跨服务共享约定

- frontend-service 与 backend-service 之间的接口契约、统一响应体 `{code, msg, data}`、HTTP 状态码语义，以 [[backend-constitution]] 第 2 节为唯一标准，frontend-service 不得自行定义另一套响应结构
- API 版本、破坏性变更规则由 backend-service 定义，frontend-service MUST 随后端版本升级同步适配，不得跳过版本各自实现兼容逻辑
- 两个服务的分支命名策略保持一致：`[Jira Ticket ID|Feature]/<工单号>-简短描述`

## Governance

- 本文件与 [[frontend-constitution]]、[[backend-constitution]] 是同一层级的细则文档，三者共同构成本项目的技术宪法，并受根目录 `.specify/memory/constitution.md` 的整体治理原则约束
- 若本文件与子文档在职责边界上出现冲突，跨服务共享事项以本文件为准，单服务内部实现细节以对应子文档为准
- 新增/移除服务、变更 Application ID 分配，须在 PR 描述中说明原因并更新本文件版本号

**Version**: 1.0.0 | **Ratified**: 2026-08-16 | **Last Amended**: 2026-08-16



## 3 数据库配置

后端服务数据库配置信息如下,   不需要新建数据库，通过以下方式链接到数据库。

```shell
spring.datasource.url=jdbc:mysql://127.0.0.1:3307/db_product?useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC
spring.datasource.username=root
spring.datasource.password=root123
```
