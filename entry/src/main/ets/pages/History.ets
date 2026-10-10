import { Context } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { DesignTokens } from '../common/DesignTokens';
import { HistoryService } from '../service/HistoryService';
import { RecognitionResult } from '../model/RecognitionResult';

@Entry
@Component
struct History {
  @State items: RecognitionResult[] = [];
  @State loading: boolean = true;
  @State message: string = '';

  aboutToAppear(): void {
    this.loadHistory();
  }

  onPageShow(): void {
    this.loadHistory();
  }

  private async loadHistory(): Promise<void> {
    this.loading = true;
    try {
      const context: Context | undefined = this.getUIContext().getHostContext();
      if (context === undefined) {
        throw new Error('HOST_CONTEXT_UNAVAILABLE');
      }
      this.items = await HistoryService.list(context);
    } catch {
      this.message = '读取历史记录失败';
    } finally {
      this.loading = false;
    }
  }

  private openResult(item: RecognitionResult): void {
    AppStorage.setOrCreate('activeRecognitionResult', item);
    router.pushUrl({ url: 'pages/Result' });
  }

  private async remove(item: RecognitionResult): Promise<void> {
    try {
      const context: Context | undefined = this.getUIContext().getHostContext();
      if (context === undefined) {
        throw new Error('HOST_CONTEXT_UNAVAILABLE');
      }
      await HistoryService.remove(context, item.id);
      await this.loadHistory();
    } catch {
      this.message = '删除失败，请稍后重试';
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
        Text('识别历史')
          .fontSize(DesignTokens.FONT_TITLE)
          .fontColor(DesignTokens.TEXT_ON_DARK)
          .margin({ left: DesignTokens.SPACE_3 })
        Blank()
        Text('🔒 本地记录')
          .fontSize(DesignTokens.FONT_STATUS)
          .fontColor(DesignTokens.TEXT_SECONDARY)
      }
      .width('100%')
      .padding(DesignTokens.SPACE_4)
      .backgroundColor(DesignTokens.CAMERA_BG)

      if (this.loading) {
        LoadingProgress()
          .color(DesignTokens.PRIMARY_GREEN)
          .width(28)
          .height(28)
          .layoutWeight(1)
      } else if (this.items.length === 0) {
        Column() {
          Text('还没有识别记录')
            .fontSize(DesignTokens.FONT_LABEL)
            .fontColor(DesignTokens.TEXT_ON_DARK)
          Text('完成一次拍照识别后，结果会保存在这里')
            .fontSize(DesignTokens.FONT_STATUS)
            .fontColor(DesignTokens.TEXT_SECONDARY)
            .margin({ top: DesignTokens.SPACE_2 })
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.items, (item: RecognitionResult) => {
            ListItem() {
              Row() {
                Column() {
                  Text(item.content.length > 0 ? item.content : '未识别到有效内容')
                    .fontSize(DesignTokens.FONT_LABEL)
                    .fontColor(DesignTokens.TEXT_PRIMARY)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(`${item.type} · ${Math.round(item.confidence * 100)}% · ${new Date(item.timestamp).toLocaleString()}`)
                    .fontSize(DesignTokens.FONT_STATUS)
                    .fontColor(DesignTokens.TEXT_SECONDARY)
                    .margin({ top: DesignTokens.SPACE_2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .onClick(() => { this.openResult(item); })
                Text('删除')
                  .fontSize(DesignTokens.FONT_STATUS)
                  .fontColor(DesignTokens.SCAN_AMBER)
                  .accessibilityText('删除这条识别记录')
                  .accessibilityRole(AccessibilityRoleType.BUTTON)
                  .onClick(() => { this.remove(item); })
              }
              .width('100%')
              .padding(DesignTokens.SPACE_4)
              .backgroundColor(DesignTokens.CARD_WHITE)
              .borderRadius(DesignTokens.RADIUS_CARD)
            }
            .margin({ left: DesignTokens.SPACE_4, right: DesignTokens.SPACE_4, top: DesignTokens.SPACE_3 })
          }, (item: RecognitionResult) => item.id)
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
