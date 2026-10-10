import { RecognizedItem, RecognitionResult, RecognitionType } from '../model/RecognitionResult';

/**
 * 识别结果编排层。
 * Core Vision Kit 接入后，只需把 SDK 输出转换为 RecognizedItem[]。
 */
export class RecognitionService {
  static readonly MIN_CONFIDENCE: number = 0.6;
  private static nextId: number = 0;

  static createResult(type: RecognitionType, imageUri: string, items: RecognizedItem[], timestamp: number = Date.now()): RecognitionResult {
    const safeItems: RecognizedItem[] = RecognitionService.sanitizeItems(items);
    const safeTimestamp: number = timestamp === timestamp && timestamp >= 0 ? timestamp : Date.now();
    const confidence: number = RecognitionService.highestConfidence(safeItems);
    const needsManualConfirmation: boolean = confidence < RecognitionService.MIN_CONFIDENCE;
    RecognitionService.nextId = (RecognitionService.nextId + 1) % Number.MAX_SAFE_INTEGER;
    return {
      id: `${type}-${safeTimestamp}-${RecognitionService.nextId}`,
      type: type,
      imageUri: imageUri,
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
      if (item.score !== item.score || item.score < 0 || item.score > 1) {
        continue;
      }
      safeItems.push({
        label: item.label,
        value: item.value,
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
}

