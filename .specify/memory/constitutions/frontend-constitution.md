# Frontend Constitution

## 0. 前端技术栈

该规范仅描述 Angular 前端 Web 应用（电商 / SaaS 产品类），不包含后端服务，后端约定见 [[backend-constitution]]。

| 约束项 | 标准 | 覆盖策略 |
| --- | --- | --- |
| 框架 | Angular 最新稳定版（v17+），启用 Standalone Components、Signals、新控制流语法 | 不允许覆盖 |
| 语言 | TypeScript，`strict: true` | 不允许覆盖 |
| 构建工具 | Angular CLI（esbuild/application builder） | 不允许覆盖 |
| 包管理器 | npm | 可覆盖（团队统一即可） |
| 样式方案 | Tailwind CSS + 自建组件库（还原 Figma 设计稿） | 不允许覆盖 |
| 状态管理 | Angular Signals + Service（不引入 NgRx） | 可覆盖（单个 feature 状态确实复杂时可局部引入） |
| HTTP 客户端 | `HttpClient` + 自定义 `HttpInterceptorFn` | 不允许覆盖 |
| 国际化 | ngx-translate（运行时切换语言，无需按语言重新构建） | 可覆盖 |
| 单元测试 | Jest + jest-preset-angular | 不允许覆盖 |
| 代码规范 | ESLint（angular-eslint）+ Prettier | 不允许覆盖 |

---

## 1. 项目目录结构规范

### 1.1 项目目录结构总览

采用按业务领域（feature-based）划分的目录结构：

```
src/
  app/
    core/                          # 单例能力，只在根加载一次
      interceptors/                # HTTP 拦截器（认证、解包、错误处理）
      guards/                      # 路由守卫（函数式）
      services/                    # 全局单例服务（如 AuthService）
    shared/                        # 跨 feature 复用、无业务归属
      components/                  # 纯展示组件（对应 Figma 基础组件）
      pipes/
      directives/
      utils/
    layout/                        # 页面骨架（Header/Footer/Nav）
    features/                      # 业务功能模块，按领域划分
      product/
        pages/                     # 路由级"智能"组件，负责取数
        components/                # feature 内部复用的"哑"组件
        services/                  # feature 数据服务 + Signal Store
        models/                    # 类型定义 / interface
        product.routes.ts
      cart/
      order/
      checkout/
      ...
    app.routes.ts
    app.config.ts
  assets/
    i18n/                          # 多语言文件
      en/
      zh/
  environments/
    environment.ts
    environment.prod.ts
```

### 1.2 各层职责说明

| 目录 | 职责 | 禁止事项 |
| --- | --- | --- |
| core/ | 全局单例：拦截器、守卫、鉴权 | 禁止放置业务 feature 相关组件 |
| shared/ | 无业务语义的通用组件/工具 | 禁止依赖任意 features/ 下的内容 |
| features/*/pages | 路由入口，注入 service 获取数据 | 禁止把复杂展示逻辑写在这里，应拆到 components |
| features/*/components | 纯展示组件，通过 input()/output() 通信 | 禁止直接注入 HttpClient 或业务 service |
| features/*/services | 数据获取、Signal Store、业务编排 | 禁止直接操作 DOM 或组件生命周期 |
| features/*/models | interface / type 定义 | 禁止包含逻辑代码 |

### 1.3 命名约定

| 类型 | 文件后缀 | 示例 |
| --- | --- | --- |
| 组件 | `.component.ts` | `product-card.component.ts` |
| 服务 | `.service.ts` | `product-api.service.ts` |
| Signal Store | `.store.ts` | `cart.store.ts` |
| 路由配置 | `.routes.ts` | `product.routes.ts` |
| 守卫 | `.guard.ts` | `auth.guard.ts` |
| 拦截器 | `.interceptor.ts` | `error.interceptor.ts` |
| 类型/接口 | `.model.ts` | `product.model.ts` |
| 管道 | `.pipe.ts` | `currency-format.pipe.ts` |
| 目录/文件命名风格 | kebab-case | `product-detail/` |
| Class 命名风格 | PascalCase | `ProductCardComponent` |

---

## 2. 组件设计规范

### 2.1 基本约束

- 所有组件 MUST 设置 `standalone: true`（Angular 17+ 默认即为 standalone，禁止手写 `NgModule` 组织业务组件，第三方库强制要求的除外）
- 模板控制流 MUST 使用新语法 `@if` / `@for` / `@switch`，禁止使用 `*ngIf` / `*ngFor` / `*ngSwitch`
- 所有组件 MUST 设置 `changeDetection: ChangeDetectionStrategy.OnPush`
- 组件输入输出 MUST 使用函数式 API：`input()` / `input.required()` / `output()`，禁止使用装饰器 `@Input()` / `@Output()`

### 2.2 智能组件 / 展示组件分离

| 类型 | 位置 | 职责 | 禁止事项 |
| --- | --- | --- | --- |
| 智能组件（Container） | `features/*/pages/` | 通过 `inject()` 获取 service/store，向下传递数据 | 禁止承载复杂展示/交互细节 |
| 展示组件（Presentational） | `features/*/components/`、`shared/components/` | 仅通过 `input()`/`output()` 通信，纯渲染 | 禁止注入 `HttpClient` 或任何数据服务 |

### 2.3 组件示例

```ts
@Component({
  selector: 'app-product-card',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CurrencyFormatPipe],
  templateUrl: './product-card.component.html',
})
export class ProductCardComponent {
  product = input.required<Product>();
  addToCart = output<string>();

  onAddToCart(): void {
    this.addToCart.emit(this.product().id);
  }
}
```

---

## 3. 状态管理规范（Signals + Service）

### 3.1 基本原则

- 状态 MUST 使用 `signal()` / `computed()` / `effect()` 管理，禁止手动 `subscribe()` 后赋值给普通字段（会破坏 Zoneless 变更检测、易造成内存泄漏）
- 能用 `computed()` 派生的状态禁止再用 `effect()` 手动同步
- 异步 HTTP 数据 MUST 通过 `toSignal()` 或 `resource()`/`rxResource()` 转换为 Signal，不在组件里裸用 `Observable` + `async` pipe 承载核心业务状态

### 3.2 Feature Store 规范

- 每个 feature 若有跨组件共享状态，MUST 封装为 `xxx.store.ts`，`providedIn: 'root'` 或在 feature 路由级 `providers` 中提供
- Store 对外只暴露只读 Signal（`.asReadonly()`），状态修改必须通过 Store 提供的方法，禁止外部直接 `.set()`

```ts
@Injectable({ providedIn: 'root' })
export class CartStore {
  private readonly _items = signal<CartItem[]>([]);
  readonly items = this._items.asReadonly();
  readonly totalCount = computed(() =>
    this._items().reduce((sum, i) => sum + i.quantity, 0)
  );

  addItem(item: CartItem): void {
    this._items.update((items) => [...items, item]);
  }
}
```

### 3.3 跨模块共享状态

- 跨 feature 共享的关键业务状态（如购物车、当前用户）MUST 放在 `core/services/` 下，作为全局单例 Store
- feature 内部私有状态不得提升到 `core/`

---

## 4. 样式与 UI 组件规范

### 4.1 设计还原原则

- 涉及视觉变化的前端 UI 开发（新增页面、新增/修改组件外观等）MUST 存在对应的 Figma 设计稿链接，且该链接须同时记录在 `spec.md`（产品需求）与 `tasks.md`（对应 UI 任务条目）中；纯逻辑修复、重构等不产生视觉变化的改动不受此约束
- 若相关 Figma 设计稿尚未提供，禁止先行自由发挥实现 UI，必须等待设计稿产出、链接补全后再开始编码
- 实现上述 UI 任务时 MUST 使用 `speckit-de-speckit-extension-figma-implement-design` skill（拉取设计上下文 → 截图校验 → 转换为项目约定的标准工作流），禁止绕开该 skill 直接凭空实现
- 样式方案采用 **Tailwind CSS + 自建组件库**，像素级还原 Figma 设计稿
- 禁止引入 Angular Material / PrimeNG 等自带设计语言的组件库，避免与 Figma 定制设计冲突
- `shared/components/` 下的组件应与 Figma 组件（Component/Variant）一一对应，命名保持一致，便于设计协同

### 4.2 Design Tokens

- 颜色、间距、圆角、字体、阴影等 design tokens MUST 在 `tailwind.config.js` 中统一定义（对齐 Figma 的 Design Tokens / Styles）
- 业务代码禁止出现 magic number 的颜色值（如 `#3B82F6`）或任意间距值，必须通过 Tailwind 语义化 class 使用

```js
// tailwind.config.js
theme: {
  extend: {
    colors: {
      brand: { DEFAULT: '#3B82F6', dark: '#1D4ED8' },
      danger: '#EF4444',
    },
    spacing: { 18: '4.5rem' },
  },
},
```

### 4.3 使用约束

- 禁止使用内联 `style` 属性，优先使用 Tailwind class；动态样式通过 `[class]` / `[ngClass]` 绑定
- 响应式设计遵循 Tailwind 断点（`sm/md/lg/xl`），移动优先（mobile-first）编写
- 组件私有、Tailwind 无法表达的复杂样式（如动画关键帧）放在组件的 `.scss` 中，并使用 `:host` 限定作用域

---

## 5. HTTP / API 层规范

后端统一响应体为 `{ code, msg, data }`（详见 [[backend-constitution]] 第 2.3 节），前端 MUST 在拦截器层统一处理，业务代码不感知该结构。

### 5.1 拦截器职责

| 拦截器 | 职责 |
| --- | --- |
| `auth.interceptor.ts` | 自动附加认证 Token（`Authorization` 请求头） |
| `unwrap.interceptor.ts` | 校验响应体 `code === 200`，成功时将 `response.body` 替换为 `data` 字段 |
| `error.interceptor.ts` | `code !== 200` 或 HTTP 错误时，统一转换为 `AppError` 并 `throwError` |
| `loading.interceptor.ts` | 维护全局请求计数 Signal，驱动 loading 状态 |

### 5.2 API Service 规范

- API 服务 MUST 放在各 feature 的 `services/` 下，命名 `xxx-api.service.ts`
- API Service 只负责 HTTP 调用与出入参类型定义（对应 `models/`），禁止包含业务逻辑或状态管理（业务逻辑放 Store）

```ts
@Injectable({ providedIn: 'root' })
export class ProductApiService {
  private http = inject(HttpClient);

  getProduct(id: string): Observable<Product> {
    return this.http.get<Product>(`/api/v1/products/${id}`);
  }
}
```

### 5.3 环境配置

- API `baseUrl` 等环境相关配置 MUST 放在 `environments/environment.ts`，禁止在业务代码中硬编码域名/路径前缀

---

## 6. 路由规范

- 所有 feature 路由 MUST 通过 `loadChildren` + 组件级 `loadComponent` 懒加载，每个 feature 独立打包为单独 chunk
- 路由守卫 MUST 使用函数式 `CanActivateFn` / `CanMatchFn`，禁止使用基于 class 的 Guard
- 路由路径命名使用 kebab-case，禁止使用驼峰或下划线（如 `/product-detail/:id`，不允许 `/productDetail/:id`）

---

## 7. 国际化规范（i18n）

电商/SaaS 场景需要用户在不重新构建部署的情况下动态切换语言，因此采用 **ngx-translate** 运行时方案，而非 `@angular/localize` 的编译期多包方案。

### 7.1 文件组织

- 多语言文件放在 `assets/i18n/{lang}/{namespace}.json`，按 feature 拆分命名空间，避免单文件过大
- 示例：`assets/i18n/en/product.json`、`assets/i18n/zh/product.json`

### 7.2 使用约束

- 模板中的文案 MUST 通过 `translate` pipe 或 directive 引用，禁止在模板/TS 中硬编码可见文案字符串
- Key 命名规范：`{feature}.{section}.{key}`，全小写，点分隔，下划线连接单词

```
cart.checkout.submit_button
product.detail.out_of_stock
```

- 日期、货币、数字格式化 MUST 使用 Angular 内置 `DatePipe` / `CurrencyPipe` 并传入当前 locale，禁止手写格式化逻辑

---

## 8. 测试与质量规范

### 8.1 目标与范围

- 测试框架：Jest + `jest-preset-angular`
- 测试层级：Service / Store 层（必须）+ 核心业务组件逻辑（建议）
- 纯展示组件（无逻辑分支）：可不测

### 8.2 必测场景清单

| 场景类型 | 说明 | 是否必须 |
| --- | --- | --- |
| Happy Path | 正常入参/状态变更，返回预期结果 | 必须 |
| 边界值 | 空数组、null、初始状态 | 必须 |
| 错误路径 | API 报错/拦截器抛出 AppError 时的处理 | 必须（有异步调用时） |
| Computed 派生 | `computed()` 在依赖变化后重新求值正确 | 必须（Store 含 computed 时） |
| 用户交互 | 组件内点击/输入触发 `output()` 事件 | 建议 |

### 8.3 示例

```ts
describe('CartStore', () => {
  it('addItem_whenCalled_increasesTotalCount', () => {
    const store = new CartStore();
    store.addItem({ id: '1', quantity: 2 });
    expect(store.totalCount()).toBe(2);
  });

  it('addItem_whenCalledTwice_accumulatesItems', () => {
    const store = new CartStore();
    store.addItem({ id: '1', quantity: 1 });
    store.addItem({ id: '2', quantity: 3 });
    expect(store.totalCount()).toBe(4);
  });
});
```

### 8.4 测试命名规范

统一格式：`方法名_场景描述_预期结果`

```
// 好的命名
addItem_whenItemNotExists_appendsToList()
getProduct_whenApiFails_throwsAppError()

// 避免
test1()
shouldWork()
```

### 8.5 覆盖率要求

| 指标 | 目标 | 说明 |
| --- | --- | --- |
| Service / Store 层行覆盖率 | ≥ 70% | 重点保障 |
| 整体行覆盖率 | ≥ 50% | 参考指标，不卡合并 |

- 覆盖率为自检项，不卡 CI 合并，但 PR 描述中须注明覆盖率数值
- 禁止只测 getter/setter 或纯常量导出堆砌覆盖率

---

## 9. 研发流程

### 9.1 分支策略

与后端保持一致（见 [[backend-constitution]] 第 5.1 节）：

- 功能分支命名：`[Jira Ticket ID|Feature]/<工单号>-简短描述`
- 示例：`SHDRP-433820/product-list-page`

### 9.2 代码规范工具

| 工具 | 用途 |
| --- | --- |
| ESLint (`angular-eslint`) | 代码规范/最佳实践检查 |
| Prettier | 代码格式化 |
| Husky + lint-staged | Git commit 前自动执行 lint + format |

- PR 提交前必须本地执行 `ng lint` 与 `npx jest` 且全部通过

---

## Governance

- 本规范适用于所有基于 Angular 的前端 Web 项目，与 [[backend-constitution]] 共同构成本项目的技术宪法
- 标记"不允许覆盖"的约束项，任何团队/项目不得自行更改，如确有必要须先修订本文档
- 修订本文档需在 PR 描述中说明修订原因，并更新下方版本信息

**Version**: 1.1.0 | **Ratified**: 2026-08-16 | **Last Amended**: 2026-08-25
