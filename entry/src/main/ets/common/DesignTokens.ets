/**
 * SmartLens 设计 Token —— UI 中所有颜色必须引用此处，禁止硬编码色值。
 * 与 docs/design.html 的视觉风格保持一致。
 */
export class DesignTokens {
  // 品牌色
  static readonly PRIMARY_GREEN: string = '#00C896'   // 识别绿
  static readonly SCAN_AMBER: string = '#FFB300'      // 扫描琥珀
  static readonly ACCENT_GREEN: string = '#00A173'    // 强调绿

  // 背景与表面
  static readonly CAMERA_BG: string = '#0B0F14'       // 相机深底
  static readonly PREVIEW_BG: string = '#1A2332'      // 取景区占位背景
  static readonly CARD_WHITE: string = '#FFFFFF'      // 结果卡片
  static readonly TAG_BG: string = '#E6FBF4'          // 标签底色

  // 文字
  static readonly TEXT_PRIMARY: string = '#0F172A'
  static readonly TEXT_SECONDARY: string = '#64748B'
  static readonly TEXT_ON_DARK: string = '#FFFFFF'

  // 圆角
  static readonly RADIUS_CARD: number = 16
  static readonly RADIUS_TAG: number = 8
  static readonly RADIUS_SCAN: number = 12
  static readonly RADIUS_ACTION_SMALL: number = 28
  static readonly RADIUS_ACTION_LARGE: number = 35

  // 间距（vp）
  static readonly SPACE_1: number = 4
  static readonly SPACE_2: number = 8
  static readonly SPACE_3: number = 12
  static readonly SPACE_4: number = 16
  static readonly SPACE_5: number = 20

  // 字号（vp）
  static readonly FONT_TITLE: number = 16
  static readonly FONT_STATUS: number = 11
  static readonly FONT_LABEL: number = 13
  static readonly FONT_PREVIEW_ICON: number = 40
}
