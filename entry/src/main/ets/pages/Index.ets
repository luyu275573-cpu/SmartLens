import { DesignTokens } from '../common/DesignTokens';
import { Context } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { image } from '@kit.ImageKit';
import { router } from '@kit.ArkUI';
import { CameraPreviewHandle, CameraPreviewService } from '../service/CameraPreviewService';
import { ImageProcessingService } from '../service/ImageProcessingService';
import { HistoryService } from '../service/HistoryService';
import { RecognitionService } from '../service/RecognitionService';
import { RecognitionResult, RecognitionType } from '../model/RecognitionResult';

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @StorageProp('cameraPermissionState') cameraPermissionState: string = 'pending';
  @StorageProp('cameraLifecycle') cameraLifecycle: string = 'foreground';
  @State cameraStatus: string = 'idle';
  @State flashEnabled: boolean = false;
  @State actionMessage: string = '';
  @State recognitionLoading: boolean = false;
  @State pageVisible: boolean = true;
  private readonly cameraController: XComponentController = new XComponentController();
  private cameraHandle: CameraPreviewHandle | undefined = undefined;
  private previewGeneration: number = 0;
  private pendingCaptureType: RecognitionType = RecognitionType.OBJECT;

  aboutToAppear(): void {
    this.pageVisible = true;
  }

  onPageShow(): void {
    this.pageVisible = true;
    if (this.cameraPermissionState === 'granted' && this.cameraLifecycle === 'foreground') {
      this.startCameraPreview();
    }
  }

  onPageHide(): void {
    this.pageVisible = false;
    this.stopCameraPreview();
  }

  aboutToDisappear(): void {
    this.pageVisible = false;
    this.stopCameraPreview();
  }

  private async startCameraPreview(): Promise<void> {
    if (this.cameraPermissionState !== 'granted' || this.cameraLifecycle !== 'foreground' ||
      !this.pageVisible || this.cameraHandle !== undefined || this.cameraStatus === 'starting') {
      return;
    }
    const generation: number = ++this.previewGeneration;
    this.cameraStatus = 'starting';
    try {
      const hostContext: Context | undefined = this.getUIContext().getHostContext();
      if (hostContext === undefined) {
        throw new Error('HOST_CONTEXT_UNAVAILABLE');
      }
      const surfaceId: string = this.cameraController.getXComponentSurfaceId();
      const handle: CameraPreviewHandle = await CameraPreviewService.open(
        hostContext,
        surfaceId,
        async (pixelMap: image.PixelMap): Promise<void> => {
          await this.handlePixelMap(pixelMap, `camera://capture/${Date.now()}`, generation, this.pendingCaptureType);
        },
        () => {
          if (generation === this.previewGeneration && this.pageVisible) {
            this.handleCameraError();
          }
        }
      );
      if (generation !== this.previewGeneration || !this.pageVisible || this.cameraLifecycle !== 'foreground' ||
        this.cameraPermissionState !== 'granted') {
        await CameraPreviewService.release(handle);
        return;
      }
      this.cameraHandle = handle;
      this.cameraStatus = 'ready';
    } catch {
      if (generation === this.previewGeneration && this.pageVisible) {
        this.cameraStatus = 'fallback';
        this.actionMessage = '相机暂不可用，请稍后重试';
      }
    }
  }

  private async stopCameraPreview(nextStatus: string = 'idle'): Promise<void> {
    ++this.previewGeneration;
    const handle: CameraPreviewHandle | undefined = this.cameraHandle;
    this.cameraHandle = undefined;
    this.cameraStatus = nextStatus;
    if (handle !== undefined) {
      await CameraPreviewService.release(handle);
    }
  }

  private handleCameraError(): void {
    this.actionMessage = '相机服务发生变化，请重新打开预览';
    this.stopCameraPreview('fallback');
  }

  private async capturePhoto(): Promise<void> {
    if (this.recognitionLoading) {
      this.actionMessage = '上一张图片正在识别，请稍候';
      return;
    }
    const handle: CameraPreviewHandle | undefined = this.cameraHandle;
    if (handle === undefined || this.cameraStatus !== 'ready') {
      this.actionMessage = '相机尚未准备好';
      return;
    }
    const generation: number = this.previewGeneration;
    this.pendingCaptureType = this.recognitionType();
    this.cameraStatus = 'capturing';
    try {
      await CameraPreviewService.capture(handle);
      if (generation !== this.previewGeneration || !this.pageVisible || this.cameraHandle !== handle) {
        return;
      }
      this.actionMessage = '照片已捕获，正在识别…';
      this.cameraStatus = 'ready';
    } catch {
      if (generation === this.previewGeneration && this.pageVisible && this.cameraHandle === handle) {
        this.cameraStatus = 'ready';
        this.actionMessage = '当前设备暂不支持拍照输出';
      }
    }
  }

  private toggleFlash(): void {
    if (this.cameraHandle === undefined || this.cameraStatus !== 'ready') {
      this.actionMessage = '相机尚未准备好';
      return;
    }
    const nextValue: boolean = !this.flashEnabled;
    try {
      CameraPreviewService.toggleFlash(this.cameraHandle, nextValue);
      this.flashEnabled = nextValue;
      this.actionMessage = nextValue ? '闪光灯已开启' : '闪光灯已关闭';
    } catch {
      this.actionMessage = '当前设备不支持闪光灯';
    }
  }

  private async pickPhoto(): Promise<void> {
    if (this.recognitionLoading) {
      this.actionMessage = '上一张图片正在识别，请稍候';
      return;
    }
    try {
      const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const result = await picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1,
        isOriginalSupported: true
      });
      if (result.photoUris.length === 0) {
        if (this.pageVisible) {
          this.actionMessage = '未选择图片';
        }
        return;
      }
      const uri: string = result.photoUris[0];
      const pixelMap: image.PixelMap = await ImageProcessingService.fromUri(uri);
      try {
        await this.handlePixelMap(pixelMap, uri, this.previewGeneration, this.recognitionType());
      } finally {
        await ImageProcessingService.release(pixelMap);
      }
    } catch {
      if (this.pageVisible) {
        this.actionMessage = '打开相册失败，请稍后重试';
      }
    }
  }

  private async handlePixelMap(pixelMap: image.PixelMap, imageUri: string, generation: number,
    type: RecognitionType): Promise<void> {
    if (!this.pageVisible || generation !== this.previewGeneration) {
      return;
    }
    this.recognitionLoading = true;
    this.actionMessage = '正在进行端侧识别…';
    try {
      const result: RecognitionResult = await RecognitionService.run(pixelMap, type, imageUri);
      const hostContext: Context | undefined = this.getUIContext().getHostContext();
      if (hostContext === undefined) {
        throw new Error('HOST_CONTEXT_UNAVAILABLE');
      }
      await HistoryService.save(hostContext, result);
      if (this.pageVisible && generation === this.previewGeneration) {
        AppStorage.setOrCreate('activeRecognitionResult', result);
        this.actionMessage = '';
        await router.pushUrl({ url: 'pages/Result' });
      }
    } catch {
      if (this.pageVisible && generation === this.previewGeneration) {
        this.actionMessage = type === RecognitionType.BARCODE ? '扫码能力暂未接入，请先使用识物、文字或票据模式' : '识别服务暂不可用，请更换图片后重试';
      }
    } finally {
      this.recognitionLoading = false;
    }
  }

  private recognitionType(): RecognitionType {
    switch (this.currentTab) {
      case 1: return RecognitionType.TEXT;
      case 2: return RecognitionType.DOCUMENT;
      case 3: return RecognitionType.BARCODE;
      default: return RecognitionType.OBJECT;
    }
  }

  private openHistory(): void {
    router.pushUrl({ url: 'pages/History' });
  }

  private showPrivacyPolicy(): void {
    this.getUIContext().showAlertDialog({
      title: 'SmartLens 隐私政策',
      message: 'SmartLens 仅在你主动使用拍照或相册选择功能时访问图片。当前版本的预览和识别数据只在设备侧处理，不上传图片；相册通过系统图片选择器授权。识别历史只保存在本机 Preferences，最多保留 100 条文本和元数据，原始图片不会写入历史，用户可在历史页逐条删除。你可以随时在系统设置中撤回相机权限。',
      autoCancel: true,
      confirm: {
        value: '知道了',
        action: () => {}
      }
    });
  }

  build() {
    Column() {
      // 顶部标题与隐私徽标
      Row() {
        Text('SmartLens')
          .fontSize(DesignTokens.FONT_TITLE)
          .fontColor(DesignTokens.TEXT_ON_DARK)
        Blank()
        Text('隐私政策')
          .fontSize(DesignTokens.FONT_STATUS)
          .fontColor(DesignTokens.TEXT_SECONDARY)
          .accessibilityText('查看隐私政策')
          .accessibilityRole(AccessibilityRoleType.BUTTON)
          .onClick(() => { this.showPrivacyPolicy(); })
          .margin({ right: DesignTokens.SPACE_3 })
        Text('历史')
          .fontSize(DesignTokens.FONT_STATUS)
          .fontColor(DesignTokens.TEXT_SECONDARY)
          .accessibilityText('查看识别历史')
          .accessibilityRole(AccessibilityRoleType.BUTTON)
          .onClick(() => { this.openHistory(); })
          .margin({ right: DesignTokens.SPACE_3 })
        Text('🔒 本地识别')
          .fontSize(DesignTokens.FONT_STATUS)
          .fontColor(DesignTokens.TEXT_SECONDARY)
          .accessibilityText('本地识别状态：图片在设备侧处理')
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
          if (this.cameraPermissionState === 'granted' && this.cameraLifecycle === 'foreground' &&
            this.cameraStatus !== 'fallback') {
            XComponent({ id: 'camera-preview', type: XComponentType.SURFACE, controller: this.cameraController })
              .width('100%')
              .height('100%')
              .onLoad(() => { this.startCameraPreview(); })
              .onDestroy(() => {
                if (this.cameraStatus !== 'fallback') {
                  this.stopCameraPreview();
                }
              })
          } else {
            Text('📦')
              .fontSize(DesignTokens.FONT_PREVIEW_ICON)
              .width(DesignTokens.PREVIEW_PLACEHOLDER_SIZE)
              .height(DesignTokens.PREVIEW_PLACEHOLDER_SIZE)
              .textAlign(TextAlign.Center)
              .backgroundColor(DesignTokens.CAMERA_BG)
              .borderRadius(DesignTokens.RADIUS_SCAN)
          }

          // 扫描框四角与扫描线
        Stack() {
          Text('').width('100%').height(DesignTokens.SCAN_LINE_THICKNESS).backgroundColor(DesignTokens.PRIMARY_GREEN)
          Text('').width(DesignTokens.SCAN_LINE_THICKNESS).height('100%').backgroundColor(DesignTokens.PRIMARY_GREEN)
        }
        .width(DesignTokens.SCAN_CORNER_SIZE)
        .height(DesignTokens.SCAN_CORNER_SIZE)
        .align(Alignment.TopStart)

        Stack() {
          Text('').width('100%').height(DesignTokens.SCAN_LINE_THICKNESS).backgroundColor(DesignTokens.PRIMARY_GREEN)
          Text('').width(DesignTokens.SCAN_LINE_THICKNESS).height('100%').backgroundColor(DesignTokens.PRIMARY_GREEN).align(Alignment.TopEnd)
        }
        .width(DesignTokens.SCAN_CORNER_SIZE)
        .height(DesignTokens.SCAN_CORNER_SIZE)
        .align(Alignment.TopEnd)

        Stack() {
          Text('').width('100%').height(DesignTokens.SCAN_LINE_THICKNESS).backgroundColor(DesignTokens.PRIMARY_GREEN).align(Alignment.BottomStart)
          Text('').width(DesignTokens.SCAN_LINE_THICKNESS).height('100%').backgroundColor(DesignTokens.PRIMARY_GREEN)
        }
        .width(DesignTokens.SCAN_CORNER_SIZE)
        .height(DesignTokens.SCAN_CORNER_SIZE)
        .align(Alignment.BottomStart)

        Stack() {
          Text('').width('100%').height(DesignTokens.SCAN_LINE_THICKNESS).backgroundColor(DesignTokens.PRIMARY_GREEN).align(Alignment.BottomStart)
          Text('').width(DesignTokens.SCAN_LINE_THICKNESS).height('100%').backgroundColor(DesignTokens.PRIMARY_GREEN).align(Alignment.TopEnd)
        }
        .width(DesignTokens.SCAN_CORNER_SIZE)
        .height(DesignTokens.SCAN_CORNER_SIZE)
        .align(Alignment.BottomEnd)

        Text('')
          .width('70%')
          .height(DesignTokens.SCAN_LINE_THICKNESS)
          .backgroundColor(DesignTokens.PRIMARY_GREEN)
          .opacity(0.85)
        }
        .width('72%')
        .height('46%')
        .align(Alignment.Center)

        // 拍照、相册和闪光灯入口
        Column() {
          Blank().layoutWeight(1)
          Row() {
            Text('🖼️')
              .fontSize(DesignTokens.FONT_STATUS)
              .fontColor(DesignTokens.TEXT_ON_DARK)
              .width(DesignTokens.ACTION_SMALL_SIZE)
              .height(DesignTokens.ACTION_SMALL_SIZE)
              .border({ width: 2, color: DesignTokens.TEXT_ON_DARK })
              .borderRadius(DesignTokens.RADIUS_ACTION_SMALL)
              .textAlign(TextAlign.Center)
              .accessibilityText('从相册选择图片')
              .accessibilityRole(AccessibilityRoleType.BUTTON)
              .onClick(() => { this.pickPhoto(); })
              .margin({ right: DesignTokens.SPACE_5 })

            Text('⦿')
              .fontSize(DesignTokens.FONT_TITLE)
              .fontColor(DesignTokens.TEXT_PRIMARY)
              .width(DesignTokens.ACTION_LARGE_SIZE)
              .height(DesignTokens.ACTION_LARGE_SIZE)
              .backgroundColor(DesignTokens.CARD_WHITE)
              .borderRadius(DesignTokens.RADIUS_ACTION_LARGE)
              .textAlign(TextAlign.Center)
              .accessibilityText('拍照并开始识别')
              .accessibilityRole(AccessibilityRoleType.BUTTON)
              .onClick(() => { this.capturePhoto(); })
              .margin({ right: DesignTokens.SPACE_5 })

            Text(this.flashEnabled ? '💡' : '⚡')
              .fontSize(DesignTokens.FONT_STATUS)
              .fontColor(DesignTokens.TEXT_ON_DARK)
              .width(DesignTokens.ACTION_SMALL_SIZE)
              .height(DesignTokens.ACTION_SMALL_SIZE)
              .border({ width: 2, color: DesignTokens.TEXT_ON_DARK })
              .borderRadius(DesignTokens.RADIUS_ACTION_SMALL)
              .textAlign(TextAlign.Center)
              .accessibilityText(this.flashEnabled ? '关闭闪光灯' : '打开闪光灯')
              .accessibilityRole(AccessibilityRoleType.BUTTON)
              .onClick(() => { this.toggleFlash(); })
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
            .accessibilityText(`${item}模式${index === this.currentTab ? '，已选中' : ''}`)
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .onClick(() => {
              this.currentTab = index;
              this.actionMessage = `已切换到${item}模式`;
            })
        }, (item: string) => item)
      }
      .width('100%')
      .backgroundColor(DesignTokens.CAMERA_BG)

      if (this.actionMessage.length > 0) {
        Text(this.actionMessage)
          .width('100%')
          .fontSize(DesignTokens.FONT_STATUS)
          .fontColor(DesignTokens.SCAN_AMBER)
          .textAlign(TextAlign.Center)
          .padding({ top: DesignTokens.SPACE_2, bottom: DesignTokens.SPACE_2 })
          .accessibilityText(this.actionMessage)
      }
      if (this.recognitionLoading) {
        LoadingProgress()
          .color(DesignTokens.PRIMARY_GREEN)
          .width(24)
          .height(24)
          .accessibilityText('正在进行端侧识别')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(DesignTokens.CAMERA_BG)
  }
}
