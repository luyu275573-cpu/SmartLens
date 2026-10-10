import { camera } from '@kit.CameraKit';
import { Context } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { image } from '@kit.ImageKit';
import { ImageProcessingService } from './ImageProcessingService';

const DOMAIN = 0x0000;

export type CameraPreviewErrorCallback = (code: number) => void;

export interface CameraPreviewHandle {
  device: camera.CameraDevice;
  session: camera.PhotoSession;
  input: camera.CameraInput;
  output: camera.PreviewOutput;
  photoOutput?: camera.PhotoOutput;
  inputErrorCallback?: (error: BusinessError) => void;
  outputErrorCallback?: (error: BusinessError) => void;
  photoOutputErrorCallback?: (error: BusinessError) => void;
  sessionErrorCallback?: (error: BusinessError) => void;
  photoAvailableCallback?: (photo: camera.CapturePhoto) => Promise<void>;
}

/**
 * CameraKit 后置摄像头预览封装。
 * 负责创建、监听和释放预览资源，页面不直接处理 CameraManager 生命周期。
 */
export class CameraPreviewService {
  static async open(
    context: Context,
    surfaceId: string,
    onPhotoAvailable?: (pixelMap: image.PixelMap) => Promise<void>,
    onError?: CameraPreviewErrorCallback
  ): Promise<CameraPreviewHandle> {
    if (surfaceId.length === 0) {
      throw new Error('CAMERA_SURFACE_UNAVAILABLE');
    }

    hilog.info(DOMAIN, 'SmartLens', 'Camera preview surface: %{public}s', surfaceId);
    let manager: camera.CameraManager;
    try {
      manager = camera.getCameraManager(context);
    } catch {
      throw new Error('CAMERA_MANAGER_UNAVAILABLE');
    }
    const backCamera: camera.CameraDevice | undefined = manager.getSupportedCameras().find(
      (device: camera.CameraDevice) => device.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK
    );
    if (backCamera === undefined) {
      throw new Error('BACK_CAMERA_UNAVAILABLE');
    }

    const capability: camera.CameraOutputCapability = manager.getSupportedOutputCapability(
      backCamera,
      camera.SceneMode.NORMAL_PHOTO
    );
    const previewProfile: camera.Profile | undefined = capability.previewProfiles[0];
    if (previewProfile === undefined) {
      throw new Error('PREVIEW_PROFILE_UNAVAILABLE');
    }

    let input: camera.CameraInput | undefined;
    let output: camera.PreviewOutput | undefined;
    let photoOutput: camera.PhotoOutput | undefined;
    let session: camera.PhotoSession | undefined;
    let inputErrorCallback: ((error: BusinessError) => void) | undefined;
    let outputErrorCallback: ((error: BusinessError) => void) | undefined;
    let photoOutputErrorCallback: ((error: BusinessError) => void) | undefined;
    let sessionErrorCallback: ((error: BusinessError) => void) | undefined;
    let photoAvailableCallback: ((photo: camera.CapturePhoto) => Promise<void>) | undefined;

    try {
      input = manager.createCameraInput(backCamera);
      output = manager.createPreviewOutput(previewProfile, surfaceId);
      session = manager.createSession<camera.PhotoSession>(camera.SceneMode.NORMAL_PHOTO);

      const photoProfile: camera.Profile | undefined = capability.photoProfiles[0];
      if (photoProfile !== undefined) {
        try {
          photoOutput = manager.createPhotoOutput(photoProfile);
        } catch {
          // 设备可能只提供预览能力；保留预览，不把可选拍照能力当成启动失败。
          photoOutput = undefined;
        }
      }

      inputErrorCallback = (error: BusinessError): void => {
        hilog.error(DOMAIN, 'SmartLens', 'Camera input error: %{public}d', error.code);
        onError?.(error.code);
      };
      outputErrorCallback = (error: BusinessError): void => {
        hilog.error(DOMAIN, 'SmartLens', 'Camera preview output error: %{public}d', error.code);
        onError?.(error.code);
      };
      photoOutputErrorCallback = (error: BusinessError): void => {
        hilog.error(DOMAIN, 'SmartLens', 'Camera photo output error: %{public}d', error.code);
        onError?.(error.code);
      };
      sessionErrorCallback = (error: BusinessError): void => {
        hilog.error(DOMAIN, 'SmartLens', 'Camera session error: %{public}d', error.code);
        onError?.(error.code);
      };
      photoAvailableCallback = async (photo: camera.CapturePhoto): Promise<void> => {
        let pixelMap: image.PixelMap | undefined;
        try {
          hilog.info(DOMAIN, 'SmartLens', 'CapturePhoto callback received');
          pixelMap = await ImageProcessingService.fromCapturePhoto(photo);
          hilog.info(DOMAIN, 'SmartLens', 'CapturePhoto converted to RGBA PixelMap');
          if (onPhotoAvailable !== undefined) {
            await onPhotoAvailable(pixelMap);
          }
        } finally {
          if (pixelMap !== undefined) {
            await ImageProcessingService.release(pixelMap);
          }
          try {
            await photo.release();
          } catch {
            hilog.warn(DOMAIN, 'SmartLens', 'Captured photo release failed');
          }
        }
      };

      input.on('error', backCamera, inputErrorCallback);
      output.on('error', outputErrorCallback);
      if (photoOutput !== undefined && photoOutputErrorCallback !== undefined) {
        photoOutput.on('error', photoOutputErrorCallback);
      }
      session.on('error', sessionErrorCallback);
      if (photoOutput !== undefined) {
        photoOutput.onCapturePhotoAvailable(photoAvailableCallback);
      }

      await input.open();
      session.beginConfig();
      session.addInput(input);
      session.addOutput(output);
      if (photoOutput !== undefined) {
        session.addOutput(photoOutput);
      }
      await session.commitConfig();
      await session.start();
      hilog.info(DOMAIN, 'SmartLens', 'Camera preview session started');
      return {
        device: backCamera,
        session: session,
        input: input,
        output: output,
        photoOutput: photoOutput,
        inputErrorCallback: inputErrorCallback,
        outputErrorCallback: outputErrorCallback,
        photoOutputErrorCallback: photoOutputErrorCallback,
        sessionErrorCallback: sessionErrorCallback,
        photoAvailableCallback: photoAvailableCallback
      };
    } catch {
      hilog.error(DOMAIN, 'SmartLens', 'Camera preview session failed');
      await CameraPreviewService.releasePartial(
        backCamera,
        session,
        input,
        output,
        photoOutput,
        inputErrorCallback,
        outputErrorCallback,
        photoOutputErrorCallback,
        sessionErrorCallback,
        photoAvailableCallback
      );
      throw new Error('CAMERA_PREVIEW_START_FAILED');
    }
  }

  static async capture(handle: CameraPreviewHandle): Promise<void> {
    if (handle.photoOutput === undefined) {
      throw new Error('PHOTO_OUTPUT_UNAVAILABLE');
    }
    try {
      await handle.photoOutput.capture();
    } catch {
      throw new Error('PHOTO_CAPTURE_FAILED');
    }
  }

  static toggleFlash(handle: CameraPreviewHandle, enabled: boolean): void {
    const mode: camera.FlashMode = enabled ? camera.FlashMode.FLASH_MODE_OPEN : camera.FlashMode.FLASH_MODE_CLOSE;
    try {
      if (!handle.session.hasFlash()) {
        throw new Error('FLASH_UNAVAILABLE');
      }
      if (!handle.session.isFlashModeSupported(mode)) {
        throw new Error('FLASH_MODE_UNSUPPORTED');
      }
      handle.session.setFlashMode(mode);
    } catch {
      throw new Error('FLASH_UNAVAILABLE');
    }
  }

  static async release(handle: CameraPreviewHandle): Promise<void> {
    await CameraPreviewService.releasePartial(
      handle.device,
      handle.session,
      handle.input,
      handle.output,
      handle.photoOutput,
      handle.inputErrorCallback,
      handle.outputErrorCallback,
      handle.photoOutputErrorCallback,
      handle.sessionErrorCallback,
      handle.photoAvailableCallback
    );
  }

  private static async releasePartial(
    device: camera.CameraDevice,
    session: camera.PhotoSession | undefined,
    input: camera.CameraInput | undefined,
    output: camera.PreviewOutput | undefined,
    photoOutput: camera.PhotoOutput | undefined,
    inputErrorCallback: ((error: BusinessError) => void) | undefined,
    outputErrorCallback: ((error: BusinessError) => void) | undefined,
    photoOutputErrorCallback: ((error: BusinessError) => void) | undefined,
    sessionErrorCallback: ((error: BusinessError) => void) | undefined,
    photoAvailableCallback: ((photo: camera.CapturePhoto) => Promise<void>) | undefined
  ): Promise<void> {
    if (input !== undefined && inputErrorCallback !== undefined) {
      try { input.off('error', device, inputErrorCallback); } catch { /* 幂等释放 */ }
    }
    if (output !== undefined && outputErrorCallback !== undefined) {
      try { output.off('error', outputErrorCallback); } catch { /* 幂等释放 */ }
    }
    if (photoOutput !== undefined && photoOutputErrorCallback !== undefined) {
      try { photoOutput.off('error', photoOutputErrorCallback); } catch { /* 幂等释放 */ }
    }
    if (session !== undefined && sessionErrorCallback !== undefined) {
      try { session.off('error', sessionErrorCallback); } catch { /* 幂等释放 */ }
    }
    if (photoOutput !== undefined && photoAvailableCallback !== undefined) {
      try { photoOutput.offCapturePhotoAvailable(photoAvailableCallback); } catch { /* 幂等释放 */ }
    }
    if (session !== undefined) {
      try { await session.stop(); } catch { /* 会话未启动 */ }
      try { await session.release(); } catch { /* 释放应具备幂等性 */ }
    }
    if (photoOutput !== undefined) {
      try { await photoOutput.release(); } catch { /* 可能已由会话释放 */ }
    }
    if (output !== undefined) {
      try { await output.release(); } catch { /* 可能已由会话释放 */ }
    }
    if (input !== undefined) {
      try { await input.close(); } catch { /* 输入可能尚未成功打开 */ }
    }
    hilog.info(DOMAIN, 'SmartLens', 'Camera preview resources released');
  }
}
