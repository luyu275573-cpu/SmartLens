import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { PermissionService } from '../service/PermissionService';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'SmartLens', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'SmartLens', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    AppStorage.setOrCreate('cameraPermissionState', 'pending');
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'SmartLens', 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'SmartLens', 'Succeeded in loading content');
    });
    this.requestCameraPermission();
  }

  private async requestCameraPermission(): Promise<void> {
    const summary = await PermissionService.request(this.context, [PermissionService.CAMERA]);
    AppStorage.setOrCreate('cameraPermissionState', summary.allGranted ? 'granted' : 'denied');
    hilog.info(DOMAIN, 'SmartLens', 'Camera permission granted: %{public}s', JSON.stringify(summary.allGranted));
    if (!summary.allGranted) {
      hilog.warn(DOMAIN, 'SmartLens', 'Camera permission denied or unavailable: %{public}s', JSON.stringify(summary));
    }
  }

  onWindowStageDestroy(): void {}

  onForeground(): void {}

  onBackground(): void {}
}
