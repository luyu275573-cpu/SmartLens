import { RecognizedItem, RecognitionResult, RecognitionType } from '../model/RecognitionResult';
import { image } from '@kit.ImageKit';
import { VisionManager } from '../capability/VisionManager';
import { util } from '@kit.ArkTS';

/**
 * 识别结果编排层。
 * Core Vision Kit 接入后，只需把 SDK 输出转换为 RecognizedItem[]。
 */
export class RecognitionService {
  static readonly MIN_CONFIDENCE: number = 0.6;

  static async run(pixelMap: image.PixelMap, type: RecognitionType, imageUri: string): Promise<RecognitionResult> {
    let items: RecognizedItem[];
    switch (type) {
      case RecognitionType.OBJECT:
        items = await VisionManager.recognizeObject(pixelMap);
        break;
      case RecognitionType.TEXT:
        items = await VisionManager.recognizeText(pixelMap);
        break;
      case RecognitionType.DOCUMENT:
        items = await VisionManager.recognizeDocument(pixelMap);
        break;
      case RecognitionType.BARCODE:
        throw new Error('BARCODE_VISION_UNAVAILABLE');
      default:
        throw new Error('RECOGNITION_TYPE_UNSUPPORTED');
    }
    return RecognitionService.createResult(type, imageUri, items);
  }

  static createResult(type: RecognitionType, imageUri: string, items: RecognizedItem[], timestamp: number = Date.now()): RecognitionResult {
    const safeItems: RecognizedItem[] = RecognitionService.sanitizeItems(items);
    const safeTimestamp: number = timestamp === timestamp && timestamp >= 0 && timestamp <= Number.MAX_SAFE_INTEGER ? timestamp : Date.now();
    const confidence: number = RecognitionService.highestConfidence(safeItems);
    const needsManualConfirmation: boolean = confidence < RecognitionService.MIN_CONFIDENCE;
    return {
      id: RecognitionService.createId(type, safeTimestamp),
      type: type,
      imageUri: imageUri.slice(0, 4096),
      content: RecognitionService.contentOf(safeItems),
      items: safeItems,
      confidence: confidence,
      needsManualConfirmation: needsManualConfirmation,
      timestamp: safeTimestamp
    };
  }

  private static sanitizeItems(items: RecognizedItem[]): RecognizedItem[] {
    const safeItems: RecognizedItem[] = [];
    for (const item of items) {
      if (safeItems.length >= 200 || item.score !== item.score || item.score < 0 || item.score > 1) {
        continue;
      }
      const label: string = item.label.trim().slice(0, 128);
      const value: string = item.value.trim().slice(0, 4096);
      if (label.length === 0 && value.length === 0) {
        continue;
      }
      safeItems.push({
        label: label,
        value: value,
        score: item.score
      });
    }
    return safeItems;
  }

  private static highestConfidence(items: RecognizedItem[]): number {
    let highest: number = 0;
    for (const item of items) {
      if (item.score > highest) {
        highest = item.score;
      }
    }
    return highest;
  }

  private static contentOf(items: RecognizedItem[]): string {
    const values: string[] = [];
    for (const item of items) {
      values.push(item.value);
    }
    return values.join('\n');
  }

  private static createId(type: RecognitionType, timestamp: number): string {
    try {
      return `${type}-${timestamp}-${util.generateRandomUUID(false)}`;
    } catch {
      // UUID 生成失败时仍保持跨进程可区分，时间戳加随机片段只作为最后降级路径。
      return `${type}-${timestamp}-${Math.floor(Math.random() * 1000000000)}`;
    }
  }
}

