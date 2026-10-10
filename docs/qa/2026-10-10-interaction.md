# 2026-10-10 交互验证记录

- 设备/模拟器：Mate 90 Pro，HarmonyOS 7.0.0（API 26）
- 包名/Ability：`com.example.smartlens` / `EntryAbility`
- 结论：`passed`（视觉骨架、权限降级和 CameraKit surface）；拍照回调与真机画面仍待完成

## 首页

- 操作前：HAP 已安装，Ability 可启动。
- 用户动作：通过 `hdc shell aa start -b com.example.smartlens -a EntryAbility` 启动。
- 操作后：观察到标题、端侧徽标、扫描框、扫描线、占位物体、拍照区和四个模式 Tab。
- 证据：`2026-10-10-home-granted.jpeg`。

## 模式 Tab

- 操作前：默认选中“识物”。
- 用户动作：点击“文字”，再点击“票据”。
- 操作后：对应 Tab 使用识别绿并加粗，其他 Tab 保持次要文字色。
- 证据：`2026-10-10-tab-text.jpeg`、`2026-10-10-tab-ticket.jpeg`。

## 相机权限拒绝

- 操作前：卸载并重新安装 HAP，首次启动显示系统相机权限对话框。
- 用户动作：点击系统对话框“不允许”。
- 操作后：PermissionService 返回 `authResults:[-1]`，首页显示“相机权限未开启，拍照识别不可用”。
- 证据：`2026-10-10-permission-denied.jpeg`，设备权限状态 `reqPermissionStates:[-1,0,-1]`。

## 识别结果模型

- 操作前：模型和服务文件不存在。
- 用户动作：执行标准检查和 HarmonyOS 构建。
- 操作后：模型与服务成功编译进 HAP。
- 结论：`passed`，见 `2026-10-10-build.md`；该项不依赖设备交互。

## CameraKit 后置预览

- 操作前：相机权限已允许，首页 `XComponent` 已加载。
- 用户动作：启动首页，等待 `XComponent.onLoad` 完成 CameraKit 初始化。
- 操作后：日志出现 `camera-previewSurface`，`PhotoSession` 配置和启动链路完成，退出时进入资源释放。
- 证据：`2026-10-10-camera-preview-surface.jpeg`。
- 说明：截图已遮盖摄像头实时画面，仅保留 surface 和扫描叠加层；真实启动日志已留在本次验证记录中。
- 结论：`passed`（模拟器 surface 链路与摄像头画面）；仍需真机复验画面方向、比例和拍照回调。

## 相机权限拒绝（CameraKit 版本）

- 操作前：清理应用数据后重新启动，出现系统相机权限对话框。
- 用户动作：点击“不允许”。
- 操作后：首页显示“相机权限未开启，拍照识别不可用”，未创建 CameraKit surface。
- 证据：`2026-10-10-camera-permission-denied.jpeg`，日志 `authResults:[-1]`。

