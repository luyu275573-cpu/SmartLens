# 设计与交互 QA

## 2026-10-11｜审查修复模拟器回归

### 运行环境

- 设备/模拟器：Mate 90 Pro
- 系统版本：HarmonyOS 7.0.0（API 26）
- 目标：`127.0.0.1:5557`
- 包名与 Ability：`com.example.smartlens` / `EntryAbility`
- 截图构建：`entry/build/default/outputs/default/entry-default-unsigned.hap`（debug，未签名；本轮另行验证 release 元数据）

### 检查结果

| 场景 | 操作前状态 | 用户动作 | 操作后状态 | 结果 | 证据 |
| --- | --- | --- | --- | --- | --- |
| CameraKit 预览 | 首次权限对话框 | 点击“允许” | 预览显示，扫描叠加层保留 | `passed` | `docs/qa/2026-10-11-home-granted.jpeg` |
| 隐私政策 | 首页已显示 | 点击顶部“隐私政策” | 弹出端侧处理与权限说明 | `passed` | `docs/qa/2026-10-11-privacy-policy.jpeg` |
| 相册 | 首页预览已运行 | 点击相册图标 | 打开系统图片选择器 | `passed` | `docs/qa/2026-10-11-photo-picker.jpeg` |
| 拍照 | PhotoOutput 可用 | 点击中心按钮 | 显示“照片已捕获，等待识别链路处理” | `passed` | `docs/qa/2026-10-11-capture-feedback.jpeg` |
| 闪光灯降级 | 预览已运行 | 点击闪光灯图标 | 模拟器显示“不支持闪光灯”反馈 | `passed` | `docs/qa/2026-10-11-flash-feedback.jpeg` |
| 后台/退出 | CameraKit 已打开 | `aa force-stop` 并重启 | hilog 出现 `CAMERA_END`，进程重新获得相机 | `passed` | 设备 hilog |

### 结论与风险

- 本轮已验证入口响应、系统 Picker、PhotoOutput 反馈和不支持能力的降级状态。
- 截图中的实时摄像头区域已遮盖；模拟器证据不能替代真机、平板和折叠态验证。
- 真实识别、结果页、PixelMap 传递和正式签名仍未完成。

## 2026-10-10｜首页静态基线

### 运行环境

- 设备/模拟器：未提供
- 系统版本：未提供
- 包名与 Ability：`com.example.smartlens` / `EntryAbility`
- 构建产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`

### 检查结果

| 场景 | 操作前状态 | 用户动作 | 操作后状态 | 结果 | 证据 |
| --- | --- | --- | --- | --- | --- |
| 首屏 | 工程入口存在 | 启动应用 | 预期显示首页视觉骨架 | `blocked` | 尚无真机/模拟器证据 |
| 模式 Tab | `currentTab = 0` | 点击文字/票据/扫码 | 选中项颜色和字重更新 | `blocked` | 尚无交互截图 |

### 多设备覆盖

| 设备类型 | 状态 | 说明 |
| --- | --- | --- |
| phone | `blocked` | 待真机或模拟器验证 |
| tablet | `blocked` | 当前模块未声明 |
| 2in1 | `blocked` | 当前模块未声明 |

### 结论与风险

- ArkTS 构建可通过，但尚未形成设备运行证据。
- 当前拍照、相册和闪光灯入口是视觉占位，不能判定为功能通过。

## 2026-10-10｜Mate 90 Pro 模拟器运行态回归

### 运行环境

- 设备/模拟器：Mate 90 Pro
- 系统版本：HarmonyOS 7.0.0（API 26）
- 包名与 Ability：`com.example.smartlens` / `EntryAbility`
- 安装方式：`hdc install -r entry/build/default/outputs/default/entry-default-unsigned.hap`

### 检查结果

| 场景 | 操作前状态 | 用户动作 | 操作后状态 | 结果 | 证据 |
| --- | --- | --- | --- | --- | --- |
| 首页 | Ability 已安装 | 启动 `EntryAbility` | SmartLens 首页、扫描框、底部操作区可见 | `passed` | `docs/qa/2026-10-10-home-granted.jpeg` |
| 文字模式 | 默认选中识物 | 点击“文字” | “文字”变为识别绿并加粗 | `passed` | `docs/qa/2026-10-10-tab-text.jpeg` |
| 票据模式 | 文字模式已选中 | 点击“票据” | “票据”变为识别绿并加粗 | `passed` | `docs/qa/2026-10-10-tab-ticket.jpeg` |
| 权限拒绝降级 | 首次权限对话框 | 点击“不允许” | 首页显示“相机权限未开启，拍照识别不可用” | `passed` | `docs/qa/2026-10-10-permission-denied.jpeg` |

### 结论与风险

- L3 模拟器交互证据已建立，权限允许和拒绝分支均可观察。
- 模拟器无法替代真实摄像头和 Core Vision Kit 能力验证；当前取景区仍是占位实现。

## 2026-10-10｜CameraKit surface 回归

### 运行环境

- 设备/模拟器：Mate 90 Pro
- 系统版本：HarmonyOS 7.0.0（API 26）
- 包名与 Ability：`com.example.smartlens` / `EntryAbility`
- 安装方式：`hdc install -r entry/build/default/outputs/default/entry-default-unsigned.hap`

### 检查结果

| 场景 | 操作前状态 | 用户动作 | 操作后状态 | 结果 | 证据 |
| --- | --- | --- | --- | --- | --- |
| CameraKit 预览 surface | 相机权限已允许 | 启动首页并等待 `XComponent.onLoad` | 日志出现 `camera-previewSurface`，首页展示 CameraKit surface | `passed` | `docs/qa/2026-10-10-camera-preview-surface.jpeg` |
| 相机资源释放入口 | 首页已创建预览 | 退出/销毁页面 | `onDestroy` 调用 `CameraPreviewService.release` | `passed` | `entry/src/main/ets/pages/Index.ets` |
| 权限拒绝回退 | 首次启动权限对话框 | 点击“不允许” | 首页保留占位预览并显示琥珀色降级提示 | `passed` | `docs/qa/2026-10-10-camera-permission-denied.jpeg` |

### 结论与风险

- CameraKit 的后置摄像头输入、预览输出、会话配置和 UI surface 链路已在模拟器建立，最新允许分支已观察到摄像头画面。
- 预览证据图已遮盖实时摄像头内容，避免把个人影像提交到仓库；surface 与扫描叠加层仍可复核。
- 模拟器画面只能证明预览链路可用，真实设备仍需复验画面方向、比例和拍照回调。

## 2026-10-10｜识别结果模型构建验证

### 检查结果

| 场景 | 操作前状态 | 用户动作 | 操作后状态 | 结果 | 证据 |
| --- | --- | --- | --- | --- | --- |
| 模型编译 | 无识别模型文件 | 执行 HarmonyOS 构建 | `RecognitionResult` 与 `RecognitionService` 编译进 HAP | `passed` | `docs/qa/2026-10-10-build.md` |
| 低置信度规则 | 服务定义 `MIN_CONFIDENCE = 0.6` | 构建并检查服务逻辑 | 低于门槛的结果标记 `needsManualConfirmation` | `passed` | `entry/src/main/ets/service/RecognitionService.ets` |

### 结论与风险

- 数据层和规则层已通过静态编译验证。
- 真实视觉 SDK 输出、结果页展示和真机交互仍待后续任务。

