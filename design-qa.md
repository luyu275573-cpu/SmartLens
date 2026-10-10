# 设计与交互 QA

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

## 2026-10-10｜识别结果模型构建验证

### 检查结果

| 场景 | 操作前状态 | 用户动作 | 操作后状态 | 结果 | 证据 |
| --- | --- | --- | --- | --- | --- |
| 模型编译 | 无识别模型文件 | 执行 HarmonyOS 构建 | `RecognitionResult` 与 `RecognitionService` 编译进 HAP | `passed` | `docs/qa/2026-10-10-build.md` |
| 低置信度规则 | 服务定义 `MIN_CONFIDENCE = 0.6` | 构建并检查服务逻辑 | 低于门槛的结果标记 `needsManualConfirmation` | `passed` | `entry/src/main/ets/service/RecognitionService.ets` |

### 结论与风险

- 数据层和规则层已通过静态编译验证。
- 真实视觉 SDK 输出、结果页展示和真机交互仍待后续任务。

