# 阶段③｜「慧眼识物 Smart Lens」智能图像识别（鸿蒙 #1）—— 详细开发文档

> 时间区间：**2025.10 – 2026.4**
> 定位：鸿蒙原生第一个项目，从跨端转入鸿蒙，主打「系统级 + 端侧 AI」，证明你吃透鸿蒙独有能力（Core Vision Kit、意图框架、元服务、多设备协同），而非把 Android 换皮。

---

## 1. 项目概述

一句话：**集拍照识物 / 文字 OCR / 票据识别 / 扫码于一体，支持端侧离线推理、小艺语音唤起、多设备流转的鸿蒙原生智能图像识别应用。**

- **平台**：HarmonyOS NEXT（HarmonyOS 5，此时已商用 1 年，成熟稳定；可写 HarmonyOS 6）
- **语言**：ArkTS
- **UI**：ArkUI（声明式）
- **IDE**：DevEco Studio 5.x
- **形态**：常规 App + 元服务（意图可被小艺唤起）

---

## 2. 选题理由

| 维度 | 说明 |
|---|---|
| 时间点契合 | 2025.10 时 HarmonyOS NEXT 已商用 1 年，生态成熟，正适合做「鸿蒙原生 + AI」项目 |
| 鸿蒙差异化 | 端侧推理、意图框架、元服务、多设备协同都是鸿蒙独有优势 |
| AI 能力升级 | 从阶段②的「云端 LLM 调用」升级到「端侧视觉 AI」，体现能力递进 |
| 演示冲击力 | 拍照即出结果、语音唤起识别，面试演示效果好 |

---

## 3. 目标用户与核心场景

1. **办公族**：拍发票/合同/名片 → 一键 OCR 成结构化文字，导出/复制。
2. **学习人群**：拍照识题、识植物/动物/物品，翻译外文菜单。
3. **视障/无障碍人群**：语音唤起「识别一下这张图片」，朗读结果。

---

## 4. 核心功能清单

### 4.1 MVP
- [ ] 拍照 / 从相册选择图片
- [ ] 物体识别（分类 + 置信度）
- [ ] 文字 OCR（中英文），结果可复制
- [ ] 基础 UI：识别结果卡片 + 历史记录

### 4.2 完整版
- [ ] 票据/证件/名片结构化识别（发票字段、姓名、电话、公司）
- [ ] 条码 / 二维码扫描与解析
- [ ] 图片翻译（识别 + 翻译 + 覆盖回显）
- [ ] 端侧离线推理（关闭网络仍可用，保护隐私）
- [ ] 意图框架接入：小艺语音唤起「识别这张图」
- [ ] 元服务：免安装卡片式调用识别能力
- [ ] 多设备协同：手机拍照 → 流转到平板/PC 查看
- [ ] 识别历史 + 收藏 + 搜索

---

## 5. 技术选型与架构

### 5.1 技术栈
| 能力 | 选型 |
|---|---|
| UI | ArkUI（@Component / @State） |
| 视觉识别 | Core Vision Kit |
| 文字识别 | Core Vision Kit 文本识别 / OCR |
| 端侧推理（进阶） | MindSpore Lite 或 Core AI 端侧模型 |
| 语音唤起 | Core Speech Kit + 意图框架（Intent Kit） |
| 免安装 | 元服务（Atomic Service） |
| 流转 | 分布式能力（continuation / 分布式对象） |
| 存储 | Preferences + 关系型数据库（RDB） |

### 5.2 分层架构
```
┌─────────────────────────────────────────────┐
│          UI 层（ArkUI 页面/组件）              │
├─────────────────────────────────────────────┤
│        业务层（识别场景编排、历史管理）          │
├─────────────────────────────────────────────┤
│      能力层（Vision Kit / Speech Kit 封装）     │
├─────────────────────────────────────────────┤
│  平台能力层（相机、相册、意图、元服务、分布式）    │
└─────────────────────────────────────────────┘
```

---

## 6. 项目结构

```
SmartLens/
├── AppScope/app.json5              # 应用配置、权限
├── entry/src/main/
│   ├── ets/
│   │   ├── entryability/
│   │   ├── pages/                  # Index / History / Detail
│   │   ├── components/             # ResultCard / ScanOverlay
│   │   ├── service/                # RecognitionService / HistoryService
│   │   ├── capability/             # VisionManager / SpeechManager / IntentManager
│   │   ├── model/                  # RecognitionResult / HistoryItem
│   │   └── common/
│   ├── resources/
│   └── module.json5                # ability、权限
├── build-profile.json5
└── hvigorfile.ts
```

---

## 7. 核心模块设计

### 7.1 数据模型
```typescript
// model/RecognitionResult.ets
export enum RecognitionType { OBJECT, TEXT, DOCUMENT, BARCODE }

export interface RecognitionResult {
  id: string;
  type: RecognitionType;
  imageUri: string;
  content: string;
  items: RecognizedItem[];
  confidence: number;
  timestamp: number;
}

export interface RecognizedItem {
  label: string;
  value: string;
  score?: number;
  box?: Rect;   // 目标框（UI 描框用）
}
```

### 7.2 能力封装层
```typescript
// capability/VisionManager.ets
import { image } from '@kit.ImageKit';

export class VisionManager {
  static async recognizeObject(pixelMap: image.PixelMap): Promise<RecognizedItem[]> {
    // Core Vision Kit 物体识别 → [{ label, score }]
  }
  static async recognizeText(pixelMap: image.PixelMap): Promise<RecognizedItem[]> {
    // 文本识别，按行返回文本 + 位置框
  }
  static async recognizeDocument(pixelMap: image.PixelMap): Promise<RecognizedItem[]> {
    // 票据/证件结构化 → 键值对
  }
}
```

### 7.3 业务编排层
```typescript
// service/RecognitionService.ets
export class RecognitionService {
  static async run(pixelMap: image.PixelMap, type: RecognitionType): Promise<RecognitionResult> {
    // 按类型分发到 VisionManager，组装结果，HistoryService 落库
  }
}
```

### 7.4 意图框架接入
- `module.json5` 声明 intent 过滤，注册「识别图片」意图。
- 用户说「小艺，识别这张图片」，系统唤起本应用并传入图片，直接进入识别流程。

---

## 8. 关键难点与解决方案

| 难点 | 方案 |
|---|---|
| 相机取景与拍照回调 | ArkUI Camera 能力，注意 `PixelMap` 获取与生命周期 |
| 识别耗时卡顿 | 识别放 worker/异步任务，UI loading 态，回调更新 `@State` |
| 离线端侧推理 | MindSpore Lite 加载端侧模型，注意格式转换与量化 |
| 权限申请 | 相机/相册权限在 module.json5 + 运行时双层处理 |
| 多设备流转 | 分布式对象 / continuation 传递结果 |

---

## 9. 开发里程碑

| 阶段 | 目标 | 周期 |
|---|---|---|
| M1 | 工程 + 相机/相册 | 2–3 天 |
| M2 | 物体识别 + OCR（MVP） | 1 周 |
| M3 | 票据结构化 + 历史 | 1 周 |
| M4 | 意图框架 + 元服务 | 1 周 |
| M5 | 多设备协同 + 打磨 | 1 周 |

---

## 10. 测试要点

- [ ] 真机测试（模拟器对相机/视觉能力支持有限）
- [ ] 弱网/无网环境端侧识别可用
- [ ] 横竖屏、折叠屏/平板适配
- [ ] 权限拒绝后的降级提示
- [ ] 大量历史记录的列表性能（懒加载）

---

## 11. 上架/交付要点（华为 AppGallery）

- 包名规范：`com.你的域名.smartlens`（上架后不可改）
- 隐私政策：说明相机/相册用途、端侧数据处理声明
- 截图、年龄分级、权限说明文案
- 上架前用 HarmonyOS 上架检测流程自检（签名、release 构建、debug 属性、权限与隐私等）

---

## 12. 简历亮点 + 时间锚点

> **时间区间**：2025.10 – 2026.4（鸿蒙 #1）
> **可用技术**：HarmonyOS 5（可写 6）、Core Vision Kit、意图框架、元服务、MindSpore Lite

**简历写法**：负责鸿蒙原生智能图像识别应用，基于 Core Vision Kit 实现物体识别与 OCR，支持端侧离线推理与意图框架语音唤起，覆盖票据/证件结构化识别与多设备流转，已在真机完成发布回归。
