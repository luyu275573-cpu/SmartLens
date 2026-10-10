# SmartLens 项目上下文

## 定位

端侧优先、隐私可控的 HarmonyOS NEXT 原生智能图像识别应用。

## 技术约束

- ArkTS + ArkUI，Stage 模型，API 26。
- 视觉能力目标为 Core Vision Kit；端侧推理预留 MindSpore Lite。
- 数据优先保留在端侧，不上传用户图片。
- UI 颜色、字号、圆角和间距优先引用 `entry/src/main/ets/common/DesignTokens.ets`。
- 识别结果置信度低于 `0.6` 时必须进入人工确认状态。

## 当前实现

- `EntryAbility` 加载 `pages/Index`。
- 首页已经有扫描框视觉骨架、模式 Tab 和端侧徽标。
- `model/RecognitionResult.ets` 与 `service/RecognitionService.ets` 已建立识别结果基础层和 0.6 置信度规则。
- `service/PermissionService.ets` 已建立运行时权限封装；`EntryAbility` 启动后请求相机权限，并通过 AppStorage 同步状态。
- 首页已实现相机权限拒绝降级提示，并通过 `XComponent` 接入 CameraKit 后置摄像头预览；预览启动失败时自动回退到占位预览。
- `service/CameraPreviewService.ets` 已封装 `PhotoSession`、`PreviewOutput`、可选 `PhotoOutput` 的创建、启动、错误监听和释放。
- `PhotoOutput` 拍照反馈、系统图片选择器、闪光灯降级、隐私政策入口和基础无障碍语义已接入；真实 `PixelMap` 识别、结果页和历史页尚未接入。

## 构建与记录

```powershell
hvigorw.bat assembleHap
./scripts/check-standard.ps1
./scripts/build-harmony.ps1
```

任务状态看 `tasks.md`，详细改动看 `changes.md` 和 `docs/development-log.md`，设备证据看 `docs/qa/`。

当前进行中的任务是 T-20261010-003：CameraKit 预览、PhotoOutput 拍照反馈和权限链路已在 Mate 90 Pro 模拟器验证，下一步是接入 `PixelMap`/Core Vision Kit 并进行真机回归。

## 当前风险

- `bundleName` 仍为示例值 `com.example.smartlens`。
- `signingConfigs` 为空，当前只能产出未签名 HAP。
- 已声明 phone/tablet/2in1 并启用自动旋转；折叠屏/平板和真机尚未回归，模拟器预览不替代真机相机验证。

