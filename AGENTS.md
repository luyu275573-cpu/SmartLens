# AGENTS.md — SmartLens 项目上下文（AI 编码智能体必读）

> 本文档是 Codex / Claude / DeepSeek 等智能体在本项目工作时的唯一事实来源。

## 1. 项目一句话
「SmartLens 慧眼识物」：HarmonyOS NEXT 原生智能图像识别应用，集拍照识物、文字 OCR、票据结构化识别、扫码于一体，支持端侧离线推理、小艺语音唤起、元服务免安装、多设备流转。**定位：端侧优先、隐私可控。**

## 2. 技术栈（锁定，不得擅自更换）
- 平台：HarmonyOS NEXT（API 12+，本机 DevEco Studio 26 + OpenHarmony SDK API 26）
- 语言：ArkTS
- UI：ArkUI（声明式，@Component / @State）
- 视觉识别：Core Vision Kit（物体识别 / OCR / 票据结构化）
- 语音：Core Speech Kit（可选）
- 端侧推理：MindSpore Lite（进阶）
- 系统能力：意图框架（Intent Kit）+ 元服务（Atomic Service）+ 分布式流转
- 存储：Preferences + 关系型数据库（RDB）

## 3. 必读文档（本仓库 docs/）
| 文件 | 内容 |
|---|---|
| `docs/design.html` | UI 设计图（风格/配色/功能/5 屏）——**设计真源** |
| `docs/development-doc.md` | 详细开发文档 |
| `docs/agent-spec.md` | 智能体开发约束与规范 |

## 4. 目录结构（目标）
```
entry/src/main/
├── ets/
│   ├── entryability/       # UIAbility 入口
│   ├── pages/              # Index(相机首页) / Result(结果) / History / Detail
│   ├── components/         # ResultCard / ScanOverlay
│   ├── service/            # RecognitionService / HistoryService
│   ├── capability/         # VisionManager / SpeechManager / IntentManager
│   ├── model/              # RecognitionResult / HistoryItem
│   └── common/DesignTokens.ets   # 设计 Token
├── module.json5            # ability、权限（相机/相册）
└── resources/
AppScope/app.json5
build-profile.json5 / hvigorfile.ts / oh-package.json5 / local.properties
```

## 5. 功能需求 + 验收清单
### 页面与功能
1. **相机首页**：拍照/相册、扫码、对焦、闪光灯、模式切换（识物/文字/票据/扫码）
2. **识别结果**：物体分类+置信度、OCR 文字、票据字段、复制/导出
3. **票据识别**：发票/证件/名片字段提取（代码/号码/金额/税额/日期/销售方）
4. **历史记录**：识别历史、收藏、搜索、删除
5. **小艺唤起/元服务**：语音唤起识别、免安装卡片

### 验收（核心）
- [ ] 拍照 → 物体识别出分类 + 置信度（≥0.6 才输出，否则「需人工确认」）
- [ ] OCR 文字可复制
- [ ] 票据识别输出结构化字段
- [ ] 无网络端侧识别仍可用（数据不出端）
- [ ] 真机跑通，横竖屏/折叠屏适配，权限拒绝有降级提示

## 6. 设计 Token（UI 必须引用，禁止硬编码色值）
见 `entry/src/main/ets/common/DesignTokens.ets`。
关键值：识别绿 `#00C896`、扫描琥珀 `#FFB300`、相机深底 `#0B0F14`、
结果卡片 `#FFFFFF`、强调绿 `#00A173`、圆角 12/16、端侧徽标「🔒 本地识别」。

## 7. 编码约束（硬性规则）
1. 增量修改，禁止大文件覆盖式重写。
2. 颜色/字号/圆角引用 DesignTokens，禁止硬编码。
3. 相机/相册权限在 module.json5 与运行时双层处理，遵循最小权限。
4. 识别耗时任务放 worker/异步，UI 用 loading 态，回调更新 @State。
5. 禁止硬编码密钥/凭据；端侧识别不联网上传图片。
6. 每任务输出：改动说明 / 涉及文件 / 验证方式 / 遗留风险。

## 8. 构建与运行命令
```bash
# 用 DevEco Studio 打开本目录（或命令行 hvigorw）
hvigorw assembleHap             # 构建 HAP
hdc install <hap路径>           # 真机安装
# 真机调试：DevEco Studio 的 Previewer/模拟器/真机
```

## 9. 验收门禁
L1 构建 HAP 通过 → L2 关键逻辑单测 → L3 真机跑通核心链路（截图）→ L4 人工 review + 上架前检测（签名/release/隐私）。

## 10. 当前进度与第一步
- 当前：仓库已建，有本文件 + docs + 设计 Token；DevEco 工程骨架待生成。
- 第一步：用 DevEco Studio 新建空 Ability 工程（或手动补齐 hvigorfile.ts/module.json5/oh-package.json5），
  然后实现「相机首页」：取景框 + 扫描框 + 底部模式 Tab（识物/文字/票据/扫码），对照 docs/design.html 第一屏。
- 每完成一个可验证单元就 git 提交。

## 11. 项目记录文件
- `tasks.md`：当前任务、状态和完成检查项。
- `changes.md`：按日期记录实际改动、验证结果和遗留风险。
- `development-log.md`：面向开发过程的时间线记录。
- `PROJECT_CONTEXT.md`：供后续智能体快速恢复上下文。
- `design.md` / `design-qa.md`：设计基线和设备/交互验证结论。
- `docs/qa/`：构建、前台状态、截图和交互证据。
