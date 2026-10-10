import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { RecognizedItem, RecognitionResult, RecognitionType } from '../model/RecognitionResult';

const STORE_NAME: string = 'smartlens_history';
const STORE_KEY: string = 'results';
const MAX_HISTORY: number = 100;
const MAX_SERIALIZED_SIZE: number = 1024 * 1024;

/** 端侧历史记录单一写入入口。仅保存识别文本和元数据，不保存 PixelMap。 */
export class HistoryService {
  private static writeQueue: Promise<void> = Promise.resolve();

  static async list(context: Context): Promise<RecognitionResult[]> {
    const store: preferences.Preferences = await preferences.getPreferences(context, STORE_NAME);
    const stored: preferences.ValueType = await store.get(STORE_KEY, '[]');
    if (typeof stored !== 'string' || stored.length > MAX_SERIALIZED_SIZE) {
      return [];
    }
    return HistoryService.parse(stored);
  }

  static async save(context: Context, result: RecognitionResult): Promise<void> {
    const operation: Promise<void> = HistoryService.enqueue(async (): Promise<void> => {
      const current: RecognitionResult[] = await HistoryService.list(context);
      const next: RecognitionResult[] = [result].concat(current).slice(0, MAX_HISTORY);
      const store: preferences.Preferences = await preferences.getPreferences(context, STORE_NAME);
      await store.put(STORE_KEY, JSON.stringify(next));
      await store.flush();
    });
    await operation;
  }

  static async remove(context: Context, id: string): Promise<void> {
    const operation: Promise<void> = HistoryService.enqueue(async (): Promise<void> => {
      const current: RecognitionResult[] = await HistoryService.list(context);
      const next: RecognitionResult[] = current.filter((item: RecognitionResult) => item.id !== id);
      const store: preferences.Preferences = await preferences.getPreferences(context, STORE_NAME);
      await store.put(STORE_KEY, JSON.stringify(next));
      await store.flush();
    });
    await operation;
  }

  private static parse(serialized: string): RecognitionResult[] {
    try {
      const value: Object = JSON.parse(serialized) as Object;
      if (!Array.isArray(value)) {
        return [];
      }
      const rawResults: Array<Object> = value as Array<Object>;
      const results: RecognitionResult[] = [];
      for (const item of rawResults) {
        const result: RecognitionResult | undefined = HistoryService.parseResult(item as Object);
        if (result !== undefined) {
          results.push(result);
        }
      }
      return results.slice(0, MAX_HISTORY);
    } catch {
      return [];
    }
  }

  private static parseResult(raw: Object): RecognitionResult | undefined {
    if (raw === null || typeof raw !== 'object') {
      return undefined;
    }
    const data: Record<string, Object> = raw as Record<string, Object>;
    const id: Object | undefined = data['id'];
    const type: Object | undefined = data['type'];
    const imageUri: Object | undefined = data['imageUri'];
    const content: Object | undefined = data['content'];
    const confidence: Object | undefined = data['confidence'];
    const needsManualConfirmation: Object | undefined = data['needsManualConfirmation'];
    const timestamp: Object | undefined = data['timestamp'];
    if (typeof id !== 'string' || id.length === 0 || id.length > 256 ||
      typeof type !== 'string' || !HistoryService.isRecognitionType(type as string) ||
      typeof imageUri !== 'string' || imageUri.length > 4096 ||
      typeof content !== 'string' || content.length > 1024 * 1024 ||
      typeof confidence !== 'number' || confidence < 0 || confidence > 1 ||
      typeof needsManualConfirmation !== 'boolean' || typeof timestamp !== 'number' ||
      timestamp < 0 || timestamp > Number.MAX_SAFE_INTEGER) {
      return undefined;
    }
    const items: RecognizedItem[] = [];
    const rawItems: Object | undefined = data['items'];
    if (Array.isArray(rawItems)) {
      const rawItemList: Array<Object> = rawItems as Array<Object>;
      for (const rawItem of rawItemList) {
        const item: Record<string, Object> = rawItem as Record<string, Object>;
        if (item !== null && typeof item === 'object' &&
          typeof item['label'] === 'string' && typeof item['value'] === 'string' &&
          typeof item['score'] === 'number' && (item['score'] as number) >= 0 && (item['score'] as number) <= 1 &&
          items.length < 200) {
          items.push({
            label: (item['label'] as string).slice(0, 128),
            value: (item['value'] as string).slice(0, 4096),
            score: item['score'] as number
          });
        }
      }
    }
    return {
      id: id as string,
      type: type as RecognitionType,
      imageUri: imageUri as string,
      content: content as string,
      items: items,
      confidence: confidence as number,
      needsManualConfirmation: needsManualConfirmation as boolean,
      timestamp: timestamp as number
    };
  }

  private static isRecognitionType(type: string): boolean {
    return type === RecognitionType.OBJECT || type === RecognitionType.TEXT ||
      type === RecognitionType.DOCUMENT || type === RecognitionType.BARCODE;
  }

  private static enqueue(operation: () => Promise<void>): Promise<void> {
    const next: Promise<void> = HistoryService.writeQueue.catch(() => {}).then(operation);
    // 让一次写入失败不会毒化后续保存/删除操作，但把本次失败继续返回给调用方。
    HistoryService.writeQueue = next.catch(() => {});
    return next;
  }
}
