import { RecognizedItem, RecognitionResult, RecognitionType } from '../model/RecognitionResult';

/**
 * 识别结果编排层。
 * Core Vision Kit 接入后，只需把 SDK 输出转换为 RecognizedItem[]。
 */
export class RecognitionService {
  static readonly MIN_CONFIDENCE: number = 0.6;

  static createResult(type: RecognitionType, imageUri: string, items: RecognizedItem[], timestamp: number = Date.now()): RecognitionResult {
    const confidence: number = RecognitionService.highestConfidence(items);
    const needsManualConfirmation: boolean = confidence < RecognitionService.MIN_CONFIDENCE;
    return {
      id: `${type}-${timestamp}`,
      type: type,
      imageUri: imageUri,
      content: RecognitionService.contentOf(items),
      items: items,
      confidence: confidence,
      needsManualConfirmation: needsManualConfirmation,
      timestamp: timestamp
    };
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

