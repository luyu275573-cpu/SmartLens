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

## 2026-10-09｜工程骨架

- 状态：`done`
- 改动：补齐 Stage 工程配置、EntryAbility、首页占位、权限声明、资源和首个任务 Prompt。
- 提交：`863339c`。
- 验证：构建通过。

