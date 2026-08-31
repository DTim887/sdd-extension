# Backend Constitution

## 0. 后端 Java 技术栈

该规范仅描述 JAVA 纯后端 API 服务， 不包含前端

| 约束项 | 标准 | 覆盖策略 |
| --- | --- | --- |
| 技术栈 | JAVA 17， Spring Boot 4.0.6， springdoc-openapi 2.3.0 | 不允许覆盖 |
| 构建工具 | Maven | 不允许覆盖 |
| 数据库 | MySQL 8.0 | 不允许覆盖 |
| ORM框架 | MyBatis-Plus 3.5.16 | 不允许覆盖 |
| 分布式缓存 | Redis 8.6 | 不允许覆盖 |
| 消息中间件 | RabbitMQ | 不允许覆盖 |

## 1. 项目包规范

根包命名 `com.disney.shdr.[service-name]`

### 1.1 项目目录结构总览

```
com.disney.shdr.[service-name]
  │
  ├── [ServiceName]Application.java          # 启动类
  │
  ├── api/                                   # 对外接口层
  │   ├── controller/                        # REST Controller
  │   ├── request/                           # 请求 DTO（入参）
  │   └── response/                          # 响应 DTO（出参）
  │
  ├── service/                              # 业务逻辑层
  │   ├── [XxxService].java                 # 接口定义
  │   └── impl/                             # 接口实现
  │
  ├── repository/                            # 数据访问层
  │   ├── [XxxRepository].java              # JPA / MyBatis Mapper 接口
  │   └── entity/                           # 数据库实体（对应表结构）
  │
  ├── domain/                               # 领域模型（业务对象，独立于 DB 结构）
  │
  ├── infrastructure/                       # 基础设施
  │   ├── config/                           # Spring 配置类（Bean、MVC、Security 等）
  │   ├── client/                           # 外部/第三方服务调用（Feign / RestTemplate）
  │   ├── messaging/                        # MQ Producer 封装、配置、序列化
  │   └── cache/                            # 缓存操作封装
  │
  ├── common/                               # 通用组件（无业务依赖）
  │   ├── constants/                        # 常量
  │   ├── enums/                            # 枚举
  │   ├── exception/                        # 自定义异常类
  │   ├── response/                         # 统一响应体封装（Result<T>）
  │   └── util/                             # 工具类
  │
  └── filter/                               # 过滤器 / 拦截器
```

### 1.2 各层职责说明

| 层 | 职责 | 禁止事项 |
| --- | --- | --- |
| api/controller | 接收请求、参数校验、调用 service、组装响应 | 禁止含业务逻辑 |
| api/request | 入参 DTO，含 @Valid 校验注解 | 禁止直接传入 service 内部 |
| api/response | 出参 DTO，面向调用方 | 禁止暴露内部 entity 字段 |
| service | 业务逻辑编排，跨 repository 事务 | 禁止直接操作 HTTP 上下文 |
| repository | 数据库 CRUD，只操作 entity | 禁止含业务判断 |
| repository/entity | 与数据库表一一对应 | 禁止直接作为 API 响应体返回 |
| domain | 纯业务对象，不依赖 ORM 注解 | 可选，复杂业务场景使用 |
| infrastructure/client | 封装外部调用，统一异常转换 | 禁止直接被 controller 调用 |
| common | 无业务依赖的纯工具组件 | 禁止引用上层业务包 |

### 1.3 命名约定

| 类型 | 后缀 | 示例 |
| --- | --- | --- |
| Controller | Controller | DeviceController |
| Service 接口 | Service | DeviceService |
| Service 实现 | ServiceImpl | DeviceServiceImpl |
| Repository | Repository | DeviceRepository |
| 数据库实体 | Entity 或 DO | DeviceDO |
| 请求 DTO | Request | CreateDeviceRequest |
| 响应 DTO | Response / VO | DeviceResponse |
| 外部调用封装 | Client | CdnClient |
| 自定义异常 | Exception | DeviceNotFoundException |

---

## 2. API 设计优先

### 2.1 REST API 设计规范

所有 API 需集成 Swagger UI。

- URI 只使用名词，禁止包含动词或操作词
- 资源路径使用复数形式（如 `/devices`，`/configurations`）
- 子资源通过父资源路径嵌套（如 `/devices/{id}/configurations`）
- URI 版本号使用前缀格式：

```
/api/v1/devices
/api/v1/devices/{id}
/api/v1/devices/{id}/configurations
/api/v1/devices/{id}/configurations/{configId}
```

### 2.2 REST API Method 规范

| 操作 | Method | URI 示例 | 说明 |
| --- | --- | --- | --- |
| 查询集合 | GET | /devices | 支持分页参数 startIndex、size |
| 查询单个 | GET | /devices/{id} | 返回完整资源详情 |
| 创建资源 | POST | /devices | 成功返回 201 Created |
| 全量更新 | PUT | /devices/{id} | 幂等操作 |
| 删除资源 | DELETE | /devices/{id} | 成功返回 200/202/204 |

- 分页示例：`GET /devices?startIndex=0&size=20`
- 异步删除返回 202，需提供可追踪的 taskId；同步删除返回 200 或 204

### 2.3 统一响应体结构

```
成功（2xx）
{ "code": 200, "msg": "success", "data": { ... } }

分页数据：
{
  "code": 200, "msg": "success",
  "data": {
    "rows": [ { ... } ],
    "pageSize": 10, "pageNum": 1, "total": 100
  }
}

集合数据：
{ "code": 200, "msg": "success", "data": { "list": [ { ... } ] } }

失败（4xx）：
{ "code": 400, "msg": "bad request, http method GET is not allowed" }

服务异常（5xx）
{ "code": 500, "msg": "service error, please try again" }
```

### 2.4 HTTP 状态码规范

| 状态码 | 场景 |
| --- | --- |
| 200 OK | 请求成功，含响应体 |
| 201 Created | 资源创建成功 |
| 202 Accepted | 异步操作已接受，处理中 |
| 204 No Content | 成功但无响应体（如 DELETE） |
| 400 Bad Request | 请求参数错误或格式非法 |
| 401 Unauthorized | 未认证或 Token 无效 |
| 403 Forbidden | 已认证但无权限 |
| 404 Not Found | 资源不存在 |
| 405 Method Not Allowed | HTTP 方法不支持 |
| 415 Unsupported Media Type | Content-Type 不支持 |
| 500 Internal Server Error | 服务端未知异常 |

### 2.5 版本管理规范

- 采用 URI 版本号方式（推荐）：`/api/v1/...`
- 以下情况必须升级主版本号（Breaking Change）：
- 响应数据结构变更
- 请求/响应字段类型变更
- 删除任何已有接口或字段
- 新增接口或新增响应字段属于非破坏性变更，无需升级主版本

### 2.6 请求头规范

- `Content-Type: application/json`
- `Accept: application/json`
- 自定义私有请求头使用 `x-` 前缀（如 `x-request-id`）
- 支持 `Accept-Encoding: gzip` 压缩，响应中包含 `Content-Encoding: gzip`

### 2.7 无状态原则

- 每个请求必须携带完整认证和上下文信息，服务端不保存任何会话状态
- 会话状态由客户端维护

### 2.8 所有 API 必须集成 Swagger UI

- 每个服务必须引入 `springdoc-openapi-starter-webmvc-ui` 作为运行时依赖
- 每个 Controller 必须使用 `@Tag` 注解标注其逻辑分组名称
- 每个对外暴露的接口方法必须标注 `@Operation(summary = "...")` 描述接口用途
- 每个请求/响应 DTO 必须使用 `@Schema` 注解描述字段含义并提供示例值
- Swagger UI 地址（`/swagger-ui.html`）在所有非生产环境中必须保持可访问；生产环境可通过配置关闭

---

## 3. 统一业务错误码规范

### 3.1 错误码结构

每个 Application 都需要预分配错误码前缀 Application ID（如 `9900`），完整错误码由以下三部分拼接而成：

| 组成部分 | 长度 | 说明 |
| --- | --- | --- |
| Application ID | 4 位数字 | 标识归属应用，每个 Application 预分配号段 |
| Error Type | 1 位字母 | 标识错误来源类型（A / B / C 见下表） |
| Error Code | 4 位数字 | 该类型下的具体错误编号，范围 0001~9999，类别间以 100 步长划分 |

| Type | 含义 | 业务场景 |
| --- | --- | --- |
| A | 客户端错误（Client Error） | 参数错误、用户版本过低、支付超时等由调用方引起的错误 |
| B | 系统错误（System Error） | 业务逻辑错误、程序健壮性不足等由当前系统引起的错误 |
| C | 第三方服务错误（Third-party Error） | CDN 故障、消息投递超时等由外部依赖引起的错误 |

完整格式示例：

```
9900 A 0001
^^^^ ^ ^^^^
|    | └── Error Code: 具体错误编号（4位）
|    └──── Error Type: 错误来源类型（1位字母）
└───────── Application ID: 应用标识（4位）
```

### 3.2 错误响应格式

业务错误码通过统一响应体的 `code` 字段返回，HTTP 状态码仍遵循第 2.3、2.4 章规范。

```
{
  "code": "9900A0001",
  "msg": "请求参数 [userId] 不能为空",
  "data": null
}
```

### 3.3 使用原则

- 错误码一经发布不得修改含义，只可新增
- 新增错误码须在此文档同步更新分配表
- 错误码统一由枚举类进行维护
- 类别间保留 100 步长，为未来细分预留空间（如 A0001~A0099 为参数类，A0100~A0199 为版本类）

---

## 4. 测试与质量

### 4.1 目标与范围

本规范适用于 Java / Spring Boot 后端服务的开发自测阶段。

- 测试类型：单元测试（Unit Test），不要求集成测试和 E2E 测试
- 测试层级：Service 层（必须）+ Controller 层（必须）
- Repository 层、工具类：可选，有复杂逻辑时建议覆盖

### 4.2 测试框架

| 用途 | 工具 |
| --- | --- |
| 测试框架 | JUnit 5（junit-jupiter） |
| Mock 框架 | Mockito（mockito-core） |
| Controller 测试 | Spring MockMvc（@WebMvcTest） |
| 断言库 | AssertJ（推荐）/ JUnit 原生 |

### 4.3 Service 层测试规范

#### 测试类结构

```
@ExtendWith(MockitoExtension.class)          // 纯单元测试，不启动 Spring 容器
class DeviceServiceImplTest {

    @Mock
    private DeviceRepository deviceRepository;

    @InjectMocks
    private DeviceServiceImpl deviceService;

    // ...
}
```

#### 必测场景清单

| 场景类型 | 说明 | 是否必须 |
| --- | --- | --- |
| Happy Path | 正常入参，业务流程走通，返回预期结果 | 必须 |
| 资源不存在 | 查询/更新目标不存在时抛出正确异常 | 必须 |
| 参数边界 | 空值、null、空集合等边界入参的处理 | 必须 |
| 业务规则冲突 | 重复创建、状态不合法等业务约束 | 必须（有业务规则时） |
| 第三方/下游失败 | 外部 client 抛异常时，服务的错误处理行为 | 必须（有外部调用时） |
| 分页/集合为空 | 查询结果为空列表时的返回值 | 建议 |

#### Mock 原则

- 只 Mock 直接依赖，不 Mock 被测类自身的方法
- 外部调用（Client、MQ Producer、Cache）必须 Mock，测试不依赖真实网络/数据库
- 禁止 Mock 静态方法（如需要，说明设计有问题，应重构）

#### 示例

```
@Test
void getDevice_whenExists_returnsResponse() {
    // Arrange
    DeviceEntity entity = buildDeviceEntity(1L, "printer");
    when(deviceRepository.findById(1L)).thenReturn(Optional.of(entity));

    // Act
    DeviceResponse result = deviceService.getDevice(1L);

    // Assert
    assertThat(result.getId()).isEqualTo(1L);
    assertThat(result.getName()).isEqualTo("printer");
}

@Test
void getDevice_whenNotFound_throwsException() {
    when(deviceRepository.findById(99L)).thenReturn(Optional.empty());

    assertThatThrownBy(() -> deviceService.getDevice(99L))
        .isInstanceOf(DeviceNotFoundException.class)
        .hasMessageContaining("99");
}
```

### 4.4 Controller 层测试规范

#### 测试类结构

```
@WebMvcTest(DeviceController.class)          // 只加载 Web 层，不启动完整容器
class DeviceControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private DeviceService deviceService;     // Mock 掉 Service

    // ...
}
```

#### 必测场景清单

Controller 层不测业务逻辑，只测：路由是否正确、参数校验是否生效、响应体格式是否符合统一规范。

| 场景类型 | 说明 | 是否必须 |
| --- | --- | --- |
| 正常请求 | 合法入参，返回预期 HTTP 状态码和响应体结构 | 必须 |
| 参数校验失败 | 缺少必填字段、格式非法，返回 400 | 必须 |

#### 示例

```
@Test
void getDevice_whenExists_returns200() throws Exception {
    DeviceResponse response = new DeviceResponse(1L, "printer");
    when(deviceService.getDevice(1L)).thenReturn(response);

    mockMvc.perform(get("/api/v1/devices/1"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.code").value("200"))
        .andExpect(jsonPath("$.data.name").value("printer"));
}

@Test
void createDevice_whenMissingName_returns400() throws Exception {
    String body = """{ "name": "" }""";

    mockMvc.perform(post("/api/v1/devices")
            .contentType(MediaType.APPLICATION_JSON)
            .content(body))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.code").value("9900A0001"));
}
```

### 4.5 覆盖率要求

| 指标 | 目标 | 说明 |
| --- | --- | --- |
| 整体行覆盖率 | ≥ 70% | 重点保障 |
| Service 层行覆盖率 | ≥ 80% | 重点保障 |
| Controller 层行覆盖率 | ≥ 70% | 重点保障 |

- 覆盖率为自检项，不卡 CI 合并，但 PR 描述中须注明当前覆盖率数值
- 若某模块因特殊原因低于目标，PR 描述中须说明原因

查看覆盖率报告：

```
mvn test jacoco:report
# 报告路径：target/site/jacoco/index.html
```

### 4.6 测试命名规范

统一格式：`方法名_场景描述_预期结果`

```
// 好的命名
void getDevice_whenNotFound_throwsDeviceNotFoundException()
void createDevice_whenNameIsBlank_returns400()
void updateDevice_whenSuccess_returnsUpdatedData()

// 避免
void test1()
void testGetDevice()
void shouldWork()
```

### 4.7 PR 提交前自检清单

提交 PR 前，逐项确认：

- [ ] Service 层核心方法均有 Happy Path 测试
- [ ] Service 层资源不存在、参数异常等错误路径已覆盖
- [ ] Controller 层参数校验（400）已验证
- [ ] Controller 层响应体格式符合统一规范（code/msg/data）
- [ ] 所有测试本地执行通过（`mvn test`）

### 4.8 禁止事项

- 禁止测试中使用 `Thread.sleep()` 等待异步结果，改用 `CompletableFuture` 或 `Awaitility`
- 禁止测试共享可变状态（静态变量等），每个测试必须独立可重复执行
- 禁止在测试代码中写真实外部地址（DB 连接、MQ 地址、第三方 URL）
- 禁止注释掉失败的测试来让构建通过；失败测试必须修复或删除并说明原因
- 禁止只测 getter/setter，覆盖率不应靠无意义测试堆砌

### 4.9 Maven 构建命令说明

| 命令 | 跳过测试编译 | 跳过测试执行 | 适用场景 |
| --- | --- | --- | --- |
| `mvn spring-boot:run` | ❌ | ❌ | 正常启动，执行全部测试 |
| `mvn spring-boot:run -DskipTests` | ❌ | ✅ | 跳过执行但仍编译测试代码，**测试代码有编译错误时仍会失败** |
| `mvn spring-boot:run -Dmaven.test.skip=true` | ✅ | ✅ | 完全跳过测试编译和执行，用于快速本地启动验证 |

**结论**：本地快速启动调试时使用 `-Dmaven.test.skip=true`；CI/CD 及正式验证时必须使用不带跳过参数的完整构建命令。

---

## 5. 研发流程

### 5.1 分支策略

- 功能分支命名：`[Jira Ticket ID|Feature]/<工单号>-简短描述`
- 示例：`SHDRP-433819/project-initialization`

---

## 6. 数据库规范

### 6.1 命名规范

#### 数据库命名

- 使用 `db_xxx` 作为前缀，格式：`db_<业务名>`
- 临时库必须以 `tmp` 为前缀，并以日期为后缀
- 示例：`ONLINE_PAYMENT` → `db_online_payment`

#### 表命名

- 所有表必须添加注释（`COMMENT`）
- 业务表使用 `tb_` 为前缀
- 日志表以 `log_` 为前缀
- 临时表必须以 `tmp_` 为前缀，并以日期为后缀

#### 字段命名

- 所有字段必须添加注释；新增字段须标识用途
- 状态、枚举类字段须在注释中给出枚举值及其含义
- 主键字段统一命名为 `id`，自增类型
- 外键/关联字段采用 `关联表名_id` 的方式命名

#### 索引命名

| 索引类型 | 命名规则 |
| --- | --- |
| 主键索引 | `pk_字段名` |
| 普通索引 | `idx_字段名` |
| 唯一索引 | `uk_字段名` |
| 外键索引 | `fk_表名_字段名` |

### 6.2 业务规范

- 字符集默认使用 `utf8mb4`（utf8 的超集，支持 emoji 等 4 字节字符，无乱码风险）
- 禁止大 SQL、大事务、大 Batch，须拆分为小 SQL、小事务、小 Batch
- 高并发、高吞吐、大数据量场景**禁止**使用：外键约束、存储过程、触发器、视图、事件；如必须使用，须联系 DBA 评估
- 外键关系仅在字段层面记录关联表主键，不在数据库级别创建外键约束

### 6.3 索引规范

- 加索引的字段如无特殊情况必须为 `NOT NULL`
- 建表时须预估数据量并提前建立索引
- 每条 `SELECT`、`UPDATE`、`DELETE` 上线前必须执行 `EXPLAIN` 分析，关注以下指标：

| 字段 | 说明 |
| --- | --- |
| `type` | 查询类型：`ALL`=全表扫描，`index`=走索引，`ref`=等值查询，`range`=范围查询 |
| `key` | 实际使用的索引，`NULL` 表示未使用索引 |
| `rows` | 预估扫描行数，越小越好 |

- 组合索引字段按区分度从大到小排列，字段数不超过 5 个

### 6.4 字段类型规范

- 字段尽量定义为 `NOT NULL` 并提供默认值
- 关联列的字段名和字段类型必须完全一致，避免隐式类型转换导致索引失效
- 使用 `TINYINT` 代替 `ENUM` 类型，并在注释中说明各状态值含义
- 字段长度按实际需要分配，不随意分配过大容量
- 避免使用 `TEXT`、`BLOB` 类型：
- MySQL 内存临时表不支持 `TEXT`/`BLOB`，排序等操作会退化为磁盘临时表
- `TEXT`/`BLOB` 只能使用前缀索引，且不能设置默认值
- 如必须使用，将 `TEXT`/`BLOB` 列拆分到独立扩展表，查询时禁止 `SELECT *`

### 6.5 SQL 规范

- 尽量用 `JOIN` 代替子查询，用小表驱动大表
- 尽量少用 `OR`，改用 `UNION ALL`；若必须使用 `OR`，所有 `OR` 条件列必须均有独立索引

---

## 7. MyBatis-Plus 使用规范

### 7.1 Spring Boot 4.x 兼容性

MyBatis-Plus 官方针对 Spring Boot 4.x（Spring Framework 7.x）提供了专用 starter：`mybatis-plus-spring-boot4-starter`（版本仍为 3.5.16），其自动配置可在 Spring Boot 4.x 环境下正常生效，`SqlSessionFactory` 会自动创建，无需手动配置。

**规范**：

- pom.xml 依赖 MUST 使用 `mybatis-plus-spring-boot4-starter`（artifactId），版本固定为 `3.5.16`；禁止使用 `mybatis-plus-boot-starter` 或 `mybatis-plus-spring-boot3-starter`（二者均针对 Spring Boot 2.x/3.x 设计，在 Spring Boot 4.x 下自动配置不生效）
- 启动类 MUST 标注 `@MapperScan`，指向 `repository` 包
- `application.yml`/`application.properties` 中 MUST 通过 `mybatis-plus.configuration.map-underscore-to-camel-case=true` 启用驼峰映射，并通过 `mybatis-plus.global-config.db-config.logic-delete-field=isDeleted` 配置逻辑删除全局字段
- 如需自定义 `SqlSessionFactory`/`SqlSessionTemplate`（如多数据源场景），才在 `infrastructure/config/` 下手动创建 `MybatisConfig`；单数据源场景禁止手动创建，避免覆盖 starter 自动配置

### 7.2 Entity 规范

- Entity 类 MUST 使用 `@TableName` 指定表名、`@TableId(type=AUTO)` 指定自增主键、`@TableLogic` 标注逻辑删除字段
- Entity 字段与数据库列名通过驼峰规则自动映射，无需手动指定 `@TableField`（特殊情况除外）
- Entity MUST 包含 `isDeleted` 逻辑删除字段，禁止使用物理删除

### 7.3 Repository 规范

- Repository 接口 MUST 继承 `BaseMapper<T>`，并标注 `@Mapper`
- 自定义查询 MUST 通过 `LambdaQueryWrapper` 在 Repository 的 `default` 方法中封装，禁止在 Service 层直接构造 QueryWrapper