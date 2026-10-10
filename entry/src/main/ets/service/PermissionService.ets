import { abilityAccessCtrl, Context, PermissionRequestResult, Permissions } from '@kit.AbilityKit';

export interface PermissionSummary {
  permissions: string[];
  authResults: number[];
  dialogShownResults: boolean[];
  errorReasons: number[];
  allGranted: boolean;
}

/**
 * 运行时权限基础层。
 * 只在需要访问受保护资源的场景请求对应权限，避免启动时一次申请全部权限。
 */
export class PermissionService {
  static readonly CAMERA: Permissions = 'ohos.permission.CAMERA';
  static readonly READ_MEDIA: Permissions = 'ohos.permission.READ_MEDIA';

  static async request(context: Context, permissions: Permissions[]): Promise<PermissionSummary> {
    try {
      const manager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      const result: PermissionRequestResult = await manager.requestPermissionsFromUser(context, permissions);
      const authResults: number[] = result.authResults ?? [];
      return {
        permissions: result.permissions ?? permissions,
        authResults: authResults,
        dialogShownResults: result.dialogShownResults ?? [],
        errorReasons: result.errorReasons ?? [],
        allGranted: authResults.length === permissions.length && authResults.every((status: number) => status === 0)
      };
    } catch {
      return {
        permissions: permissions,
        authResults: [],
        dialogShownResults: [],
        errorReasons: [],
        allGranted: false
      };
    }
  }
}

