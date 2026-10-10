# SmartLens 开发日志

## 2026-10-11｜真实识别主链路与结果/历史页

- 完成 `CapturePhoto.main`、系统图片选择器 URI 到 RGBA `PixelMap` 的输入适配，并在格式不符时执行 PixelMap 转换；识别完成或失败都会释放图片资源。
- 接入 `@kit.CoreVisionKit`：物体模式使用 Object Detection，文字模式使用 OCR，票据模式组合物体检测、OCR 和本地字段提取；扫码保持明确的未接入降级，不伪造结果。
- 新增 `Result.ets` 与 `History.ets` 页面，注册页面路由；结果页展示分类/文本、置信度、人工确认提示、端侧徽标和复制入口。
- 新增 `HistoryService.ets`，使用 Preferences 保存最多 100 条文本和元数据；增加写入队列错误恢复、历史数据校验和 UUID 结果 ID，避免重启后的碰撞和损坏数据污染 UI。
- 验证：debug HAP 构建通过；Mate 90 Pro API 26 模拟器日志确认 `CapturePhoto callback received` 与 `CapturePhoto converted to RGBA PixelMap`。物体检测返回 Core Vision 错误 `1011000002`，OCR 初始化返回超时 `200`，页面显示失败提示且没有写入假历史。
- 证据：`docs/qa/2026-10-11-recognition-chain.jpeg`、`docs/qa/2026-10-11-recognition-chain-hilog.txt`、`docs/qa/2026-10-11-history-empty.jpeg`。
- 遗留风险：模拟器缺少可用视觉模型，识别成功、结果页非空态、历史删除/重启回读和真机回归需在能力完整设备上继续验证；正式身份、签名及平板/折叠屏回归暂缓。

## 2026-10-11｜审查问题修复与模拟器回归

- 完成上一轮安全审查的代码修复：移除未使用的 `READ_MEDIA`/`INTERNET` 权限，补齐 CameraKit 异步竞态、后台停止、异常释放和运行时错误监听。
- 首页入口已接入 CameraKit 拍照、系统 `PhotoViewPicker` 和闪光灯切换；设备能力不足时显示可操作的降级反馈。
- 识别结果服务过滤 NaN/越界分数，复制结果项并使用时间戳加递增序列生成唯一 ID；低于 `0.6` 仍进入人工确认。
- 新增开发版隐私政策文件和应用内查看入口，补充按钮/模式无障碍语义、对比度 Token、自动旋转及 phone/tablet/2in1 声明。
- 修复构建脚本的 debug/release 参数传递，并在 HAP 内校验 `buildMode` 与 `debug` 元数据。
- 验证：`scripts/check-standard.ps1`、debug 构建、release 构建均通过；HAP 权限只含 `ohos.permission.CAMERA`；Mate 90 Pro API 26 模拟器完成预览、隐私政策、系统图片选择器、拍照反馈和闪光灯降级验证。
- 证据：`docs/qa/2026-10-11-remediation.md` 及同日期截图；实时摄像头区域已遮盖。
- 遗留风险：正式身份和签名、真机/多设备回归、`PixelMap` 到 Core Vision Kit、结果页和历史页仍待后续任务。

## 2026-10-11

- 完成一次全面缺陷与安全审查，覆盖 ArkTS 页面、CameraKit 服务、权限声明、Ability 生命周期、识别结果模型、构建脚本、HAP 元数据、隐私与无障碍。
- 确认 `scripts/build-harmony.ps1 -BuildMode release` 参数未生效：产物仍为 `debug:true`；显式传入 `-p buildMode=release` 才能得到 release 元数据，但项目仍未签名。
- 确认正式身份、签名、最小权限、隐私政策、相机后台生命周期和资源异常释放等阻断/高风险项，完整报告见 `docs/qa/2026-10-11-security-audit.md`。
- 本次仅新增审查记录，没有修改业务源码；下一步按报告顺序建立修复任务。

## 2026-10-10

- 接入远程仓库 `origin/master`。
- 完成相机首页视觉骨架并推送提交 `a692daa`。
- 建立标准化记录文件和 QA 证据目录。
- 完成识别结果模型与 0.6 置信度人工确认规则。
- 标准检查和 HAP 构建通过；构建产物仍未签名。
- 启动 Mate 90 Pro API 26 模拟器验证首页前台显示，并点击验证“文字”“票据”模式 Tab 状态切换。
- 新增运行时相机权限状态同步和拒绝降级提示；模拟器拒绝权限后首页显示琥珀色提示，日志记录 `authResults:[-1]`。
- 保存本次交互截图至 `docs/qa/`，权限任务进入 `in_progress`，下一步接入 CameraKit 真实取景。
- 新增 `CameraPreviewService`，接入 CameraKit 后置摄像头 `PhotoSession`、`PreviewOutput` 和 `XComponent` surface 生命周期。
- 在 Mate 90 Pro API 26 模拟器观察到 `camera-previewSurface` 创建日志，并在重新安装后的允许分支取得摄像头画面；新增服务日志记录 surface、session 启动和资源释放。
- 重新验证权限拒绝分支，保存 `docs/qa/2026-10-10-camera-permission-denied.jpeg`，日志记录 `Camera permission granted: false` 与 `authResults:[-1]`。
- CameraKit 任务仍为 `in_progress`：待接入 `PhotoOutput`/`PixelMap` 拍照回调，并在真机完成回归。

## 2026-10-09

- 初始化 HarmonyOS NEXT Stage 工程。
- 完成设计文档、开发文档、智能体规范和设计 Token。
- 补齐 EntryAbility、首页占位、权限声明、Hvigor 配置。
- 构建验证通过，当前产物未签名。

## 记录规则

每次开发记录日期、目标、实际改动、验证命令、提交号和遗留风险。真机运行、截图和交互证据统一放在 `docs/qa/`，没有设备证据时明确标记为 `blocked`。

