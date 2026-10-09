import { DesignTokens } from '../common/DesignTokens';

@Entry
@Component
struct Index {
  @State currentTab: number = 0;

  build() {
    Column() {
      // 顶部状态区
      Row() {
        Text('SmartLens 骨架已就绪').fontSize(16).fontColor('#FFFFFF')
        Blank()
        Text('🔒 本地识别').fontSize(11).fontColor('#94A3B8')
      }
      .width('100%')
      .padding(16)
      .backgroundColor(DesignTokens.CAMERA_BG)

      // 取景区（占位）
      Column() {
        Text('📷').fontSize(48)
        Text('相机取景区').fontSize(13).fontColor('#64748B')
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#1A2332')

      // 底部模式 Tab
      Row() {
        ForEach(['识物', '文字', '票据', '扫码'], (item: string, index: number) => {
          Text(item)
            .fontSize(13)
            .fontColor(index === this.currentTab ? DesignTokens.PRIMARY_GREEN : '#64748B')
            .fontWeight(index === this.currentTab ? FontWeight.Bold : FontWeight.Normal)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 12, bottom: 12 })
            .onClick(() => { this.currentTab = index; })
        }, (item: string) => item)
      }
      .width('100%')
      .backgroundColor(DesignTokens.CAMERA_BG)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(DesignTokens.CAMERA_BG)
  }
}
