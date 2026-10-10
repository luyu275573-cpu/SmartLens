# 2026-10-11 审查修复与模拟器回归

## 环境

- 设备：Mate 90 Pro 模拟器
- 系统：HarmonyOS 7.0.0 / API 26
- 目标：`127.0.0.1:5557`
- 包名与 Ability：`com.example.smartlens` / `EntryAbility`
- 截图构建：debug，未签名 HAP（本轮另行验证 release 元数据）
- 安装：`hdc install -r entry/build/default/outputs/default/entry-default-unsigned.hap`

## 构建和元数据

| 检查 | 结果 | 证据 |
|---|---|---|
| `./scripts/check-standard.ps1` | `passed` | 命令输出 |
| `./scripts/build-harmony.ps1 -BuildMode debug` | `passed` | HAP `buildMode=debug`、`debug=true` |
| `./scripts/build-harmony.ps1 -BuildMode release` | `passed` | HAP `buildMode=release`、`debug=false` |
| HAP 权限 | `passed` | `reqPermissions` 仅为 `ohos.permission.CAMERA` |

## 模拟器交互

| 场景 | 操作 | 结果 | 证据 |
|---|---|---|---|
| 相机权限 | 首次启动允许相机 | CameraKit 预览显示，首页正常渲染 | `2026-10-11-home-granted.jpeg` |
| 隐私政策 | 点击顶部“隐私政策” | 弹出开发版端侧处理说明 | `2026-10-11-privacy-policy.jpeg` |
| 系统图片选择器 | 点击相册入口 | 打开系统图片选择器，未申请全量媒体权限 | `2026-10-11-photo-picker.jpeg` |
| 拍照 | 点击中心拍照按钮 | 页面显示“照片已捕获，等待识别链路处理” | `2026-10-11-capture-feedback.jpeg` |
| 闪光灯降级 | 点击闪光灯入口 | 设备不支持时显示“当前设备不支持闪光灯” | `2026-10-11-flash-feedback.jpeg` |
| 退出/重启 | `aa force-stop` 后重新启动 | 日志出现 CameraKit `CAMERA_END`，相机资源随进程退出 | 设备 hilog |

截图中的 CameraKit 实时画面已用占位底色遮盖，避免保存个人影像；证据只用于验证 UI 状态和交互反馈。

## 未完成项

- 真实设备相机、横竖屏、折叠屏和平板回归。
- `CapturePhoto` 到 `PixelMap` 的识别编排、Core Vision Kit、结果页和历史页。
- 正式 bundleName/vendor、签名配置和正式隐私政策主体信息。
