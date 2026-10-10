# 变更记录

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

