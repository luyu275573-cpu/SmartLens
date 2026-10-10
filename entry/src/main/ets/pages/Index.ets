import { DesignTokens } from '../common/DesignTokens';
import { Context } from '@kit.AbilityKit';
import { CameraPreviewHandle, CameraPreviewService } from '../service/CameraPreviewService';

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @StorageProp('cameraPermissionState') cameraPermissionState: string = 'pending';
  @State cameraStatus: string = 'idle';
  private readonly cameraController: XComponentController = new XComponentController();
  private cameraHandle: CameraPreviewHandle | undefined = undefined;

  aboutToDisappear(): void {
    this.stopCameraPreview();
  }

  private async startCameraPreview(): Promise<void> {
    if (this.cameraPermissionState !== 'granted' || this.cameraHandle !== undefined || this.cameraStatus === 'starting') {
      return;
    }
    this.cameraStatus = 'starting';
    try {
      const hostContext: Context | undefined = this.getUIContext().getHostContext();
      if (hostContext === undefined) {
        throw new Error('HOST_CONTEXT_UNAVAILABLE');
      }
      const surfaceId: string = this.cameraController.getXComponentSurfaceId();
      this.cameraHandle = await CameraPreviewService.open(hostContext, surfaceId);
      this.cameraStatus = 'ready';
    } catch {
      this.cameraStatus = 'fallback';
    }
  }

  private async stopCameraPreview(): Promise<void> {
    const handle: CameraPreviewHandle | undefined = this.cameraHandle;
    this.cameraHandle = undefined;
    if (handle !== undefined) {
      await CameraPreviewService.release(handle);
    }
  }

  build() {
    Column() {
      // 顶部标题与隐私徽标
      Row() {
        Text('SmartLens')
          .fontSize(DesignTokens.FONT_TITLE)
          .fontColor(DesignTokens.TEXT_ON_DARK)
        Blank()
        Text('🔒 本地识别')
          .fontSize(DesignTokens.FONT_STATUS)
          .fontColor(DesignTokens.TEXT_SECONDARY)
      }
      .width('100%')
      .padding(DesignTokens.SPACE_4)
      .backgroundColor(DesignTokens.CAMERA_BG)

      if (this.cameraPermissionState === 'denied' || this.cameraStatus === 'fallback') {
        Row() {
          Text(this.cameraPermissionState === 'denied' ? '⚠️ 相机权限未开启，拍照识别不可用' : '⚠️ 相机暂不可用，已切换占位预览')
            .fontSize(DesignTokens.FONT_STATUS)
            .fontColor(DesignTokens.SCAN_AMBER)
        }
        .width('100%')
        .padding({ left: DesignTokens.SPACE_4, right: DesignTokens.SPACE_4, top: DesignTokens.SPACE_2, bottom: DesignTokens.SPACE_2 })
        .backgroundColor(DesignTokens.PREVIEW_BG)
      }

      // CameraKit 预览区；未授权或设备不支持时回退到占位预览。
      Stack() {
        Stack() {
          if (this.cameraPermissionState === 'granted' && this.cameraStatus !== 'fallback') {
            XComponent({ id: 'camera-preview', type: XComponentType.SURFACE, controller: this.cameraController })
              .width('100%')
              .height('100%')
              .onLoad(() => { this.startCameraPreview(); })
              .onDestroy(() => { this.stopCameraPreview(); })
          } else {
            Text('📦')
              .fontSize(DesignTokens.FONT_PREVIEW_ICON)
              .width(110)
              .height(110)
              .textAlign(TextAlign.Center)
              .backgroundColor(DesignTokens.CAMERA_BG)
              .borderRadius(DesignTokens.RADIUS_SCAN)
          }

          // 扫描框四角与扫描线
        Stack() {
          Text('').width('100%').height(2).backgroundColor(DesignTokens.PRIMARY_GREEN)
          Text('').width(2).height('100%').backgroundColor(DesignTokens.PRIMARY_GREEN)
        }
        .width(32)
        .height(32)
        .align(Alignment.TopStart)

        Stack() {
          Text('').width('100%').height(2).backgroundColor(DesignTokens.PRIMARY_GREEN)
          Text('').width(2).height('100%').backgroundColor(DesignTokens.PRIMARY_GREEN).align(Alignment.TopEnd)
        }
        .width(32)
        .height(32)
        .align(Alignment.TopEnd)

        Stack() {
          Text('').width('100%').height(2).backgroundColor(DesignTokens.PRIMARY_GREEN).align(Alignment.BottomStart)
          Text('').width(2).height('100%').backgroundColor(DesignTokens.PRIMARY_GREEN)
        }
        .width(32)
        .height(32)
        .align(Alignment.BottomStart)

        Stack() {
          Text('').width('100%').height(2).backgroundColor(DesignTokens.PRIMARY_GREEN).align(Alignment.BottomStart)
          Text('').width(2).height('100%').backgroundColor(DesignTokens.PRIMARY_GREEN).align(Alignment.TopEnd)
        }
        .width(32)
        .height(32)
        .align(Alignment.BottomEnd)

        Text('')
          .width('70%')
          .height(2)
          .backgroundColor(DesignTokens.PRIMARY_GREEN)
          .opacity(0.85)
        }
        .width('72%')
        .height('46%')
        .align(Alignment.Center)

        // 拍照、相册和闪光灯入口（能力接入前保留视觉入口）
        Column() {
          Blank().layoutWeight(1)
          Row() {
            Text('🖼️')
              .fontSize(DesignTokens.FONT_STATUS)
              .fontColor(DesignTokens.TEXT_ON_DARK)
              .width(56)
              .height(56)
              .border({ width: 2, color: DesignTokens.TEXT_ON_DARK })
              .borderRadius(DesignTokens.RADIUS_ACTION_SMALL)
              .textAlign(TextAlign.Center)
              .margin({ right: DesignTokens.SPACE_5 })

            Text('⦿')
              .fontSize(DesignTokens.FONT_TITLE)
              .fontColor(DesignTokens.TEXT_PRIMARY)
              .width(70)
              .height(70)
              .backgroundColor(DesignTokens.CARD_WHITE)
              .borderRadius(DesignTokens.RADIUS_ACTION_LARGE)
              .textAlign(TextAlign.Center)
              .margin({ right: DesignTokens.SPACE_5 })

            Text('⚡')
              .fontSize(DesignTokens.FONT_STATUS)
              .fontColor(DesignTokens.TEXT_ON_DARK)
              .width(56)
              .height(56)
              .border({ width: 2, color: DesignTokens.TEXT_ON_DARK })
              .borderRadius(DesignTokens.RADIUS_ACTION_SMALL)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ bottom: DesignTokens.SPACE_4 })
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(DesignTokens.PREVIEW_BG)

      // 底部模式 Tab
      Row() {
        ForEach(['识物', '文字', '票据', '扫码'], (item: string, index: number) => {
          Text(item)
            .fontSize(DesignTokens.FONT_LABEL)
            .fontColor(index === this.currentTab ? DesignTokens.PRIMARY_GREEN : DesignTokens.TEXT_SECONDARY)
            .fontWeight(index === this.currentTab ? FontWeight.Bold : FontWeight.Normal)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: DesignTokens.SPACE_3, bottom: DesignTokens.SPACE_3 })
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
