# 2026-10-10 交互验证记录

- 设备/模拟器：Mate 90 Pro，HarmonyOS 7.0.0（API 26）
- 包名/Ability：`com.example.smartlens` / `EntryAbility`
- 结论：`passed`（视觉骨架与权限降级）；CameraKit 真实取景仍未完成

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

