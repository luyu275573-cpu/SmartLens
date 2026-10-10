# SmartLens 全面缺陷与安全审查

审查日期：2026-10-11  
审查范围：ArkTS 源码、Stage 配置、权限、构建脚本、HAP 元数据、已有模拟器 QA 证据。  
审查结论：`blocked`（发布门禁未通过）；当前未发现已写入仓库的密钥、令牌或明确的图片外传代码，但存在以下必须处理的阻断项和运行时风险。

## 已执行验证

| 检查 | 结果 | 证据 |
|---|---|---|
| `scripts/check-standard.ps1` | `passed` | 标准文件和状态词检查通过 |
| `hvigorw assembleHap --no-daemon` | `passed`，有 ArkTS warning | `CameraPreviewService.ets` 的异常处理提示 |
| `hvigorw assembleApp --no-daemon` | `passed`，未签名 | Hvigor 明确提示未配置 `signingConfigs` |
| `scripts/build-harmony.ps1 -BuildMode release` | 脚本返回 `passed`，实际产物为 debug | HAP `module.json`：`buildMode: debug`、`debug: true` |
| `hvigorw assembleHap --no-daemon -p buildMode=release` | `release` 元数据生效 | HAP `module.json`：`buildMode: release`、`debug: false`；仍未签名 |
| 视觉对比度计算 | 2 项不达标 | `#64748B/#1A2332 = 3.32:1`，`#64748B/#0B0F14 = 4.04:1` |
| 模拟器运行 | 仅采用已有证据 | `docs/qa/2026-10-10-interaction.md`；本次环境未检测到 `hdc` |

## 阻断项与高风险项

### SL-001｜发布身份仍为占位值（阻断）

- 文件：`AppScope/app.json5:3-4`
- 现状：`bundleName` 为 `com.example.smartlens`，`vendor` 为 `example`。
- 影响：无法作为正式应用身份发布；身份一旦上架后修改会造成升级和数据迁移问题。
- 处理：由项目所有者提供最终包名和 vendor 后再写入，不能由审查工具猜测。

### SL-002｜没有签名配置（阻断）

- 文件：`build-profile.json5:3`
- 现状：`signingConfigs` 为空，`products.default.signingConfig` 却引用 `default`。
- 证据：构建日志显示 `Will skip sign 'hos_hap'` 和 `Will skip sign 'app'`。
- 影响：只能安装未签名开发产物，不能进入正式发布链路。
- 处理：配置 DevEco/AGC 正式证书、profile 和安全存储；口令与私钥不得入库。

### SL-003｜构建脚本的 release 参数失效（高风险）

- 文件：`scripts/build-harmony.ps1:4-20`
- 现状：脚本接收 `-BuildMode`，但始终只执行 `assembleHap`，未传入 `-p buildMode=release`。
- 复现：执行 `./scripts/build-harmony.ps1 -BuildMode release` 后，HAP 内部仍为 `buildMode: debug`、`debug: true`。
- 影响：CI 或交付人员会得到“脚本报告 release、产物实际 debug”的错误安全信号。
- 处理：脚本按模式传递 Hvigor 参数，并在成功后解析 HAP `module.json` 校验 `buildMode/debug`，不符合就失败。

### SL-004｜权限声明超过当前功能需要（高风险）

- 文件：`entry/src/main/module.json5:29-49`
- 现状：声明了 `CAMERA`、`READ_MEDIA`、`INTERNET`，运行时只申请 `CAMERA`，当前源码没有相册读取、网络请求或视觉 SDK 上传实现。
- 影响：扩大用户授权和商店审核范围；`INTERNET` 与“端侧本地识别”产品承诺形成不一致。
- 处理：在功能真正接入前删除未使用权限；相册优先使用系统 Picker，确需受限媒体权限时补齐用途、运行时流程和隐私文案。

### SL-005｜页面退出/后台期间存在相机资源竞态（高风险）

- 文件：`entry/src/main/ets/pages/Index.ets:14-40`、`entry/src/main/ets/entryability/EntryAbility.ets:38-42`
- 现状：`startCameraPreview()` 等待异步 `CameraPreviewService.open()` 时，页面可能已触发 `aboutToDisappear`/`XComponent.onDestroy`；此时 `cameraHandle` 尚未赋值，随后 `open()` 成功会把句柄写回已离开的页面，无法再释放。Ability 的 `onBackground()` 也是空实现。
- 影响：相机输入、预览输出和 session 可能泄漏；应用退到后台后还可能继续占用摄像头，造成隐私、耗电和下次打开冲突。
- 处理：引入启动代次/取消标记，在 `open()` 返回后检查页面仍有效；在 `onBackground` 或等价生命周期停止预览，回前台按权限和 surface 状态恢复。

### SL-006｜CameraKit 中间创建失败时不能保证释放（高风险）

- 文件：`entry/src/main/ets/service/CameraPreviewService.ets:37-53`
- 现状：`createCameraInput`、`createPreviewOutput`、`createSession` 位于 `try` 之前。若第二或第三个创建调用抛异常，之前已创建的对象不会进入统一释放分支。构建器也对这些调用给出“Function may throw exceptions”警告。
- 影响：相机服务长期占用、后续打开失败或进程稳定性下降。
- 处理：使用可选句柄在同一 `try/finally` 中分阶段创建和释放；保留原始错误码用于诊断。

### SL-007｜缺少 CameraKit 运行时错误监听（高风险）

- 文件：`entry/src/main/ets/service/CameraPreviewService.ets`
- 现状：没有为 `CameraInput`、`PreviewOutput`、`PhotoSession` 注册 `error`/占用/服务异常监听。
- 影响：相机被其他应用占用、系统禁用或服务 fatal error 时，页面可能仍显示 ready，用户无法重试或得到准确降级提示。
- 处理：注册并在释放时注销监听；将冲突、禁用、服务故障映射为可操作的 UI 状态。

## 中风险功能与数据问题

### SL-008｜权限恢复路径缺失

- 文件：`EntryAbility.ets:40-42`、`Index.ets`
- 用户在系统设置重新授权后，应用没有在 `onForeground` 主动复核权限，也没有“重新授权/打开设置”动作；通常需要重启应用才能恢复预览。

### SL-009｜识别结果输入未做边界校验

- 文件：`entry/src/main/ets/service/RecognitionService.ets:10-40`、`model/RecognitionResult.ets:12-26`
- `score` 未验证为有限值且位于 `[0,1]`；大于 1 的异常分数会直接绕过 `0.6` 人工确认门槛。
- `id = type + timestamp` 在同一毫秒的并发识别中可能碰撞。
- 结果直接保存调用方传入的可变 `items` 引用；`imageUri`、`timestamp`、文本字段也没有格式或来源校验。
- 处理：拒绝/归一化非法 SDK 输出，使用唯一 ID（例如时间戳加随机/递增序列），复制结果数组，并对 URI 来源和导出格式做允许列表校验。

### SL-010｜主要入口仍是视觉占位，功能状态与 UI 不一致

- 文件：`entry/src/main/ets/pages/Index.ets:133-165,177-188`
- 拍照、相册、闪光灯三个入口没有 `onClick`；模式 Tab 只改变颜色/字重，没有改变识别分发；没有 `PhotoOutput`、`PixelMap`、Core Vision Kit、结果页或历史页。
- 影响：用户会以为功能可用，实际点击无响应；这是当前 MVP 的主要功能缺口。

### SL-011｜隐私政策与数据处理披露缺失

- 全仓库检索只有设计文案和开发文档，没有应用内隐私政策文本、入口或同意/查看路径。
- 影响：相机、相册、识别结果和未来票据/证件 PII 缺少合规说明；“🔒 本地识别”徽标不能替代正式披露。
- 处理：在接入真实识别和媒体选择前补齐隐私政策、用途说明、端侧处理范围、保留/删除规则和第三方 SDK 说明。

### SL-012｜Ability 对外导出边界需要收紧

- 文件：`entry/src/main/module.json5:20-26`
- `EntryAbility` 当前 `exported: true` 且只配置系统 home skill；目前没有接收外部图片或 URI，因此未发现当前可利用的数据注入路径。
- 风险：后续加入 Intent/小艺/元服务入口时，如果直接信任 Want 中的 URI、文本或字段，可能出现越权读取、路径遍历或恶意内容进入导出链路。
- 处理：新增入口时明确 action/entity，校验调用来源、URI scheme、权限和大小，拒绝任意文件路径，并为不受支持的 Want 安全降级。

## 低风险质量与可维护性问题

### SL-013｜深色主题次要文字对比度不足

- `DesignTokens.TEXT_SECONDARY`（`#64748B`）在 `PREVIEW_BG`（`#1A2332`）上为 `3.32:1`，在 `CAMERA_BG`（`#0B0F14`）上为 `4.04:1`，普通正文目标通常应达到 `4.5:1`。

### SL-014｜无障碍语义不完整

- 图标使用 Emoji/Text，未提供可读名称、角色或状态描述；拍照、相册和闪光灯也不是明确的可访问按钮。
- 选中状态主要依赖颜色和字重，未验证大字号、读屏和系统字体放大。

### SL-015｜设备适配覆盖不足

- `module.json5` 仅声明 `phone`；未验证横竖屏、折叠态、平板和窗口尺寸变化。
- 预览固定选择 `previewProfiles[0]`，未按窗口比例、方向和设备能力选择 profile。

### SL-016｜标准检查器无法阻止发布错误

- `scripts/check-standard.ps1` 只检查文件存在和任务状态，不检查 placeholder 身份、签名、权限最小化、release 元数据或危险日志。
- 因此出现“标准检查通过、发布仍被阻断”的情况；应把这些门禁加入发布检查脚本。

### SL-017｜依赖可复现性和发布加固尚未建立

- `.gitignore` 忽略 `oh-package-lock.json5`；当前无运行时三方依赖，但后续引入 SDK 后无法保证锁定版本。
- release 构建未配置 obfuscation；Hvigor 已提示未启用混淆。该项当前是加固建议，不是已确认的运行时漏洞。

## 未发现事项

- 未发现硬编码 API Key、密码、私钥或 bearer token。
- 当前源码没有网络请求、图片上传、远程 URL 加载或持久化历史数据，因此暂未发现实际的数据外传和本地数据库注入路径。
- 上述“未发现”只针对当前代码；接入 Core Vision Kit、相册、导出、Intent、RDB 后必须重新审查数据边界。

## 建议修复顺序

1. 先修复 SL-003，并让脚本在 HAP 元数据不是 release 或仍为 debug 时失败。
2. 由项目所有者提供正式 bundle/vendor，再配置签名；补充隐私政策和最小权限。
3. 修复 SL-005～SL-007 的相机生命周期、错误监听和权限恢复。
4. 给识别结果增加输入校验和唯一 ID，再接入 PhotoOutput/PixelMap。
5. 接入真实拍照链路后补齐结果页、历史页、无障碍、对比度和多设备 QA。

