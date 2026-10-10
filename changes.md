# 变更记录

## 2026-10-11｜真实 PixelMap、Core Vision Kit 与结果历史闭环

- 状态：`blocked`
- 目标：把相机/相册输入交给真实 `PixelMap` 和 Core Vision Kit，完成结果页与本地历史记录。
- 识别链路：`CapturePhoto.main` 与 PhotoViewPicker URI 均转换为 RGBA `PixelMap`；物体识别使用 `objectDetection.ObjectDetector`，文字使用 `textRecognition`，票据模式增加 OCR 字段提取（发票代码、号码、金额、税额、价税合计、日期、销售方）。扫码明确返回未接入错误，不生成假结果。
- 结果与历史：新增 `Result`、`History` 页面和 `main_pages.json` 路由；结果页展示条目、置信度、人工确认提示和复制；`HistoryService` 使用 Preferences 保存最多 100 条，仅保存文本和元数据；结果 ID 使用 UUID，历史解析校验类型、分数、长度和时间戳，写入队列失败后可继续工作。
- 资源与输入：相机回调释放 `CapturePhoto` 和 `PixelMap`；PixelMap 格式不符时尝试转换为 RGBA_8888；Core Vision 分析器始终在 `finally` 销毁。
- 验证：`hvigorw.bat assembleHap --no-daemon -p buildMode=debug` 通过；Mate 90 Pro API 26 模拟器确认拍照回调和 RGBA PixelMap 生成。物体检测返回 `1011000002`，OCR 初始化返回超时 `200`，因此识别成功和非空历史回读状态为 `blocked`，证据见 `docs/qa/2026-10-11-recognition-chain-hilog.txt`。
- 遗留风险：需在提供 Core Vision 模型的真机或能力完整设备上复验识别成功、结果页跳转、Preferences 非空列表、删除和重启回读；正式 bundleName/vendor、签名、平板/折叠屏回归按当前范围后置。

## 2026-10-11｜全面审查问题修复与模拟器回归

- 状态：`done`
- 权限：从 `module.json5` 移除未使用的 `READ_MEDIA`、`INTERNET`，相册改用系统 `PhotoViewPicker`。
- CameraKit：补齐输入/输出/session 错误监听、PhotoOutput 回调、异步启动代次校验、页面/后台停止、异常阶段清理和幂等释放。
- 识别模型：过滤 NaN 与越界分数，复制输入项，使用 UUID 生成结果 ID。
- 首页：拍照、相册、闪光灯入口具备实际调用和降级提示；新增隐私政策弹窗、无障碍语义、设备类型声明和自动旋转。
- 构建门禁：`scripts/build-harmony.ps1` 将 `BuildMode` 传给 Hvigor，并解析 HAP `module.json` 校验 debug/release 元数据。
- 验证：标准检查通过；debug/release 构建均通过；HAP 元数据仅含 `ohos.permission.CAMERA`；Mate 90 Pro API 26 模拟器完成预览、隐私政策、系统图片选择器、拍照反馈和闪光灯降级验证。
- 遗留风险：HAP 仍未签名，正式 bundleName/vendor 未确定；真实 PixelMap/Core Vision Kit、真机和多设备回归在后续任务中处理。

## 2026-10-11｜全面缺陷与安全审查

- 状态：`done`
- 目标：全面排查当前工程的潜在 bug、权限/隐私风险和发布门禁问题。
- 改动：新增 `docs/qa/2026-10-11-security-audit.md`，记录源码、配置、HAP 元数据、对比度和已有设备证据的审查结论；未修改业务源码和发布身份。
- 验证：`scripts/check-standard.ps1` 通过；`hvigorw assembleHap --no-daemon`、`assembleApp --no-daemon` 通过但未签名；`scripts/build-harmony.ps1 -BuildMode release` 复现为 debug HAP；显式 `-p buildMode=release` 可生成 release 元数据但仍未签名。
- 结论：审查状态 `blocked`。阻断项包括正式身份、签名、release 脚本、隐私政策；高风险项包括相机异步竞态、后台释放、异常清理和运行时错误监听。
- 遗留风险：尚未修复报告中的代码问题；本次环境未检测到 `hdc`，动态结论沿用 2026-10-10 模拟器证据，真机回归仍待完成。

## 2026-10-10｜工程记录体系与识别结果基础模型

- 状态：`done`
- 用户目标：增加开发跟踪记录，并继续推进 SmartLens 开发。
- 项目类型：HarmonyOS NEXT Stage 模型 ArkTS/ArkUI 应用。

### 本次改动

- 新增项目说明、任务清单、变更记录、设计基线、设计 QA、开发日志和项目上下文文件。
- 新增标准检查脚本和 HarmonyOS 构建脚本。
- 新增识别结果模型与统一置信度门槛服务。

### 验证

- 标准检查：`scripts/check-standard.ps1` 通过；Python 标准检查通过，有目录/设备类型现状警告。
- HarmonyOS 构建：`scripts/build-harmony.ps1 -BuildMode debug` 通过。
- 设备与交互：本任务为纯模型层，不涉及设备交互；首页设备验证仍待真机条件。
- 构建产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`，53,543 bytes。
- 证据索引：`docs/qa/`。

### 遗留风险

- Core Vision Kit 尚未接入，模型服务当前只负责结果结构和规则编排。
- 低于 0.6 的结果会标记人工确认，但尚未在结果页展示。

## 2026-10-10｜相机首页视觉骨架

- 状态：`done`
- 改动：完成扫描框、扫描线、物体占位、顶部隐私徽标、拍照/相册/闪光灯视觉入口和模式 Tab。
- 提交：`a692daa`。
- 验证：`hvigorw.bat assembleHap` 成功；未签名警告保留。

## 2026-10-10｜运行时相机权限与拒绝降级

- 状态：`in_progress`（权限链路完成，CameraKit 真实取景待接入）。
- 改动：新增 `PermissionService`，Ability 启动后仅请求 `ohos.permission.CAMERA`；使用 AppStorage 将权限状态同步到首页。
- 改动：首页在权限拒绝时显示琥珀色降级提示“相机权限未开启，拍照识别不可用”。
- 验证：`hvigorw.bat assembleHap --no-daemon` 成功；HAP 已通过 `hdc install -r` 部署到 Mate 90 Pro（HarmonyOS 7.0.0/API 26）。
- 设备证据：允许路径见 `docs/qa/2026-10-10-home-granted.jpeg`；文字/票据 Tab 见 `docs/qa/2026-10-10-tab-text.jpeg`、`docs/qa/2026-10-10-tab-ticket.jpeg`；拒绝路径见 `docs/qa/2026-10-10-permission-denied.jpeg`。
- 日志证据：`Camera permission granted: false`，`authResults:[-1]`，`dialogShownResults:[true]`。
- 遗留风险：当前取景区仍是视觉占位，拍照/相册/闪光灯尚未绑定系统能力；HAP 仍未配置签名。

## 2026-10-10｜CameraKit 后置取景链路

- 状态：`in_progress`（预览链路完成，拍照回调和真机回归待完成）。
- 改动：新增 `CameraPreviewService`，封装后置摄像头发现、预览 profile、`PhotoSession` 配置、启动和释放。
- 改动：首页使用 `XComponent` surface 承载 CameraKit 预览；无权限、无可用 profile 或启动失败时回退到占位预览并显示降级提示。
- 涉及文件：`entry/src/main/ets/service/CameraPreviewService.ets`、`entry/src/main/ets/pages/Index.ets`。
- 模拟器证据：`docs/qa/2026-10-10-camera-preview-surface.jpeg`；权限拒绝证据：`docs/qa/2026-10-10-camera-permission-denied.jpeg`。
- 证据处理：预览截图已遮盖摄像头实时画面，避免提交个人影像；CameraKit 真实启动状态以设备日志为准。
- 构建与验证：`hvigorw.bat assembleHap --no-daemon`、`scripts/check-standard.ps1`；Mate 90 Pro API 26 通过 surface/权限分支验证。
- 当前构建产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`，75,425 bytes。
- 遗留风险：Mate 90 Pro 模拟器已能输出摄像头帧，但仍不能替代真机验证；尚未接入 `PhotoOutput` 和 `PixelMap` 识别。

## 2026-10-09｜工程骨架

- 状态：`done`
- 改动：补齐 Stage 工程配置、EntryAbility、首页占位、权限声明、资源和首个任务 Prompt。
- 提交：`863339c`。
- 验证：构建通过。

