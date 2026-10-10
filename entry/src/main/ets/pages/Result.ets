import { router } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { DesignTokens } from '../common/DesignTokens';
import { RecognizedItem, RecognitionResult, RecognitionType } from '../model/RecognitionResult';

@Entry
@Component
struct Result {
  @StorageProp('activeRecognitionResult') result: RecognitionResult | undefined = undefined;
  @State message: string = '';

  private titleOf(type: RecognitionType): string {
    switch (type) {
      case RecognitionType.TEXT: return '文字识别结果';
      case RecognitionType.DOCUMENT: return '票据识别结果';
      case RecognitionType.BARCODE: return '扫码结果';
      default: return '物体识别结果';
    }
  }

  private confidenceText(confidence: number): string {
    return `${Math.round(confidence * 100)}%`;
  }

  private formatTime(timestamp: number): string {
    return new Date(timestamp).toLocaleString();
  }

  private async copyContent(): Promise<void> {
    if (this.result === undefined || this.result.content.length === 0) {
      this.message = '当前没有可复制内容';
      return;
    }
    try {
      const board: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      await board.setData(pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.result.content));
      this.message = '识别内容已复制';
    } catch {
      this.message = '复制失败，请稍后重试';
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(32)
          .fontColor(DesignTokens.TEXT_ON_DARK)
          .accessibilityText('返回相机首页')
          .accessibilityRole(AccessibilityRoleType.BUTTON)
          .onClick(() => { router.back(); })
        Text(this.result === undefined ? '识别结果' : this.titleOf(this.result.type))
          .fontSize(DesignTokens.FONT_TITLE)
          .fontColor(DesignTokens.TEXT_ON_DARK)
          .margin({ left: DesignTokens.SPACE_3 })
        Blank()
        Text('🔒 本地识别')
          .fontSize(DesignTokens.FONT_STATUS)
          .fontColor(DesignTokens.TEXT_SECONDARY)
      }
      .width('100%')
      .padding(DesignTokens.SPACE_4)
      .backgroundColor(DesignTokens.CAMERA_BG)

      if (this.result === undefined) {
        Column() {
          Text('暂无识别结果')
            .fontSize(DesignTokens.FONT_LABEL)
            .fontColor(DesignTokens.TEXT_ON_DARK)
          Text('请返回首页拍照或从相册选择图片')
            .fontSize(DesignTokens.FONT_STATUS)
            .fontColor(DesignTokens.TEXT_SECONDARY)
            .margin({ top: DesignTokens.SPACE_2 })
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            Text('识别完成')
              .fontSize(DesignTokens.FONT_SECTION)
              .fontColor(DesignTokens.TEXT_PRIMARY)
              .fontWeight(FontWeight.Bold)
              .alignSelf(ItemAlign.Start)
            Text(this.formatTime(this.result.timestamp))
              .fontSize(DesignTokens.FONT_STATUS)
              .fontColor(DesignTokens.TEXT_SECONDARY)
              .alignSelf(ItemAlign.Start)
              .margin({ top: DesignTokens.SPACE_1 })

            Row() {
              Text('最高置信度')
                .fontSize(DesignTokens.FONT_LABEL)
                .fontColor(DesignTokens.TEXT_PRIMARY)
              Blank()
              Text(this.confidenceText(this.result.confidence))
                .fontSize(DesignTokens.FONT_LABEL)
                .fontColor(this.result.needsManualConfirmation ? DesignTokens.SCAN_AMBER : DesignTokens.ACCENT_GREEN)
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .padding(DesignTokens.SPACE_4)
            .backgroundColor(DesignTokens.TAG_BG)
            .borderRadius(DesignTokens.RADIUS_CARD)
            .margin({ top: DesignTokens.SPACE_4 })

            if (this.result.needsManualConfirmation) {
              Text('置信度低于 60%，请人工确认识别内容')
                .fontSize(DesignTokens.FONT_STATUS)
                .fontColor(DesignTokens.SCAN_AMBER)
                .width('100%')
                .margin({ top: DesignTokens.SPACE_2 })
                .accessibilityText('置信度低于百分之六十，请人工确认识别内容')
            }

            if (this.result.items.length === 0) {
              Text('未识别到有效内容')
                .fontSize(DesignTokens.FONT_LABEL)
                .fontColor(DesignTokens.TEXT_SECONDARY)
                .margin({ top: DesignTokens.SPACE_5 })
            } else {
              ForEach(this.result.items, (item: RecognizedItem) => {
                Row() {
                  Column() {
                    Text(item.label)
                      .fontSize(DesignTokens.FONT_STATUS)
                      .fontColor(DesignTokens.TEXT_SECONDARY)
                    Text(item.value)
                      .fontSize(DesignTokens.FONT_LABEL)
                      .fontColor(DesignTokens.TEXT_PRIMARY)
                      .margin({ top: DesignTokens.SPACE_1 })
                      .maxLines(4)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Text(this.confidenceText(item.score))
                    .fontSize(DesignTokens.FONT_STATUS)
                    .fontColor(DesignTokens.ACCENT_GREEN)
                }
                .width('100%')
                .padding(DesignTokens.SPACE_4)
                .backgroundColor(DesignTokens.CARD_WHITE)
                .borderRadius(DesignTokens.RADIUS_CARD)
                .margin({ top: DesignTokens.SPACE_3 })
              }, (item: RecognizedItem) => `${item.label}-${item.value}-${item.score}`)
            }

            Text('原始内容')
              .fontSize(DesignTokens.FONT_LABEL)
              .fontWeight(FontWeight.Bold)
              .fontColor(DesignTokens.TEXT_PRIMARY)
              .alignSelf(ItemAlign.Start)
              .margin({ top: DesignTokens.SPACE_5 })
            Text(this.result.content.length > 0 ? this.result.content : '无')
              .fontSize(DesignTokens.FONT_LABEL)
              .fontColor(DesignTokens.TEXT_PRIMARY)
              .width('100%')
              .padding(DesignTokens.SPACE_4)
              .backgroundColor(DesignTokens.CARD_WHITE)
              .borderRadius(DesignTokens.RADIUS_CARD)
              .margin({ top: DesignTokens.SPACE_2 })

            Row() {
              Text('复制内容')
                .fontSize(DesignTokens.FONT_LABEL)
                .fontColor(DesignTokens.ACCENT_GREEN)
                .accessibilityText('复制识别内容')
                .accessibilityRole(AccessibilityRoleType.BUTTON)
                .onClick(() => { this.copyContent(); })
              Blank()
              Text('🔒 仅保存在本机')
                .fontSize(DesignTokens.FONT_STATUS)
                .fontColor(DesignTokens.TEXT_SECONDARY)
            }
            .width('100%')
            .margin({ top: DesignTokens.SPACE_4, bottom: DesignTokens.SPACE_5 })
          }
          .width('100%')
          .padding(DesignTokens.SPACE_4)
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor(DesignTokens.PREVIEW_BG)
      }

      if (this.message.length > 0) {
        Text(this.message)
          .width('100%')
          .fontSize(DesignTokens.FONT_STATUS)
          .fontColor(DesignTokens.SCAN_AMBER)
          .textAlign(TextAlign.Center)
          .padding({ top: DesignTokens.SPACE_2, bottom: DesignTokens.SPACE_2 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(DesignTokens.PREVIEW_BG)
  }
}
