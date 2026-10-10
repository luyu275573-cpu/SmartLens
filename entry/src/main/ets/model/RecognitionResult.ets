/**
 * SmartLens 的识别场景类型。
 * 具体视觉能力由 service/capability 层负责，页面只依赖这个数据契约。
 */
export enum RecognitionType {
  OBJECT = 'object',
  TEXT = 'text',
  DOCUMENT = 'document',
  BARCODE = 'barcode'
}

export interface RecognizedItem {
  label: string;
  value: string;
  score: number;
}

export interface RecognitionResult {
  id: string;
  type: RecognitionType;
  imageUri: string;
  content: string;
  items: RecognizedItem[];
  confidence: number;
  needsManualConfirmation: boolean;
  timestamp: number;
}

