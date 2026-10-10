# SmartLens 开发日志

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

