# SmartLens 慧眼识物

SmartLens 是 HarmonyOS NEXT 原生端侧图像识别应用，覆盖拍照识物、OCR、票据结构化识别和扫码，并预留小艺唤起、元服务与多设备流转能力。

## 当前基线

- 平台：HarmonyOS NEXT / Stage 模型 / API 26
- 语言与 UI：ArkTS + ArkUI
- 当前已实现：工程入口、设计 Token、相机首页视觉骨架、模式 Tab、识别结果领域模型与置信度门槛
- 尚未实现：CameraKit 真实取景、运行时权限、Core Vision Kit、结果页、历史页、签名配置和真机回归

## 构建

```powershell
hvigorw.bat assembleHap
```

产物位于 `entry/build/` 下的最新 `.hap` 文件。当前构建可通过，但项目没有 signingConfigs，产物为未签名 HAP。

## 目录

- `entry/src/main/ets/pages/`：页面
- `entry/src/main/ets/common/`：设计 Token 和通用常量
- `entry/src/main/ets/model/`：识别结果模型
- `entry/src/main/ets/service/`：业务编排服务
- `docs/`：产品、开发、设计和 QA 资料
- `tasks.md` / `changes.md` / `docs/development-log.md`：过程记录

## 记录与门禁

每个非琐碎任务先登记到 `tasks.md`，完成后回填 `changes.md`、`design-qa.md` 和 `docs/qa/`。提交前运行：

```powershell
./scripts/check-standard.ps1
./scripts/build-harmony.ps1
```

