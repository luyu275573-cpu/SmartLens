import { camera } from '@kit.CameraKit';
import { Context } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

export interface CameraPreviewHandle {
  session: camera.PhotoSession;
  input: camera.CameraInput;
  output: camera.PreviewOutput;
}

/**
 * CameraKit 后置摄像头预览封装。
 * 只负责打开和释放预览资源，页面不直接处理 CameraManager 生命周期。
 */
export class CameraPreviewService {
  static async open(context: Context, surfaceId: string): Promise<CameraPreviewHandle> {
    hilog.info(DOMAIN, 'SmartLens', 'Camera preview surface: %{public}s', surfaceId);
    const manager: camera.CameraManager = camera.getCameraManager(context);
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
    const profile: camera.Profile | undefined = capability.previewProfiles[0];
    if (profile === undefined) {
      throw new Error('PREVIEW_PROFILE_UNAVAILABLE');
    }

    const input: camera.CameraInput = manager.createCameraInput(backCamera);
    const output: camera.PreviewOutput = manager.createPreviewOutput(profile, surfaceId);
    const session: camera.PhotoSession = manager.createSession<camera.PhotoSession>(camera.SceneMode.NORMAL_PHOTO);

    try {
      await input.open();
      session.beginConfig();
      session.addInput(input);
      session.addOutput(output);
      await session.commitConfig();
      await session.start();
      hilog.info(DOMAIN, 'SmartLens', 'Camera preview session started');
      return { session: session, input: input, output: output };
    } catch {
      hilog.error(DOMAIN, 'SmartLens', 'Camera preview session failed');
      await CameraPreviewService.release({ session: session, input: input, output: output });
      throw new Error('CAMERA_PREVIEW_START_FAILED');
    }
  }

  static async release(handle: CameraPreviewHandle): Promise<void> {
    try {
      await handle.session.stop();
    } catch {
      // 会话未启动时允许继续释放其它资源。
    }
    try {
      await handle.session.release();
    } catch {
      // 释放应具备幂等性，避免页面退出被相机服务错误阻塞。
    }
    try {
      await handle.output.release();
    } catch {
      // 输出可能已由会话释放。
    }
    try {
      await handle.input.close();
    } catch {
      // 输入可能尚未成功打开。
    }
    hilog.info(DOMAIN, 'SmartLens', 'Camera preview resources released');
  }
}
