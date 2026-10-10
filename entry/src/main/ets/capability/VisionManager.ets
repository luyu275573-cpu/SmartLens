import { objectDetection, textRecognition, visionBase } from '@kit.CoreVisionKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { RecognizedItem } from '../model/RecognitionResult';

const DOMAIN = 0x0000;

/**
 * Core Vision Kit 能力封装。所有输入都必须是 RGBA_8888 PixelMap，
 * 不包含网络回退，也不生成演示用的假结果。
 */
export class VisionManager {
  private static ocrInitPromise: Promise<boolean> | undefined = undefined;

  static async recognizeObject(pixelMap: image.PixelMap): Promise<RecognizedItem[]> {
    let detector: objectDetection.ObjectDetector | undefined;
    try {
      detector = await objectDetection.ObjectDetector.create();
      const response: objectDetection.ObjectDetectionResponse = await detector.process(
        VisionManager.request(pixelMap)
      );
      const items: RecognizedItem[] = [];
      for (const detected of response.objects) {
        if (!VisionManager.isValidScore(detected.score) || detected.labels.length === 0) {
          continue;
        }
        const label: number = detected.labels[0];
        items.push({
          label: '物体',
          value: VisionManager.objectLabel(label),
          score: detected.score
        });
      }
      return items;
    } catch (error) {
      hilog.warn(DOMAIN, 'SmartLens', 'Core Vision object detection unavailable: %{public}s', VisionManager.errorText(error));
      throw new Error('VISION_OBJECT_FAILED');
    } finally {
      if (detector !== undefined) {
        await detector.destroy();
      }
    }
  }

  static async recognizeText(pixelMap: image.PixelMap): Promise<RecognizedItem[]> {
    const initialized: boolean = await VisionManager.ensureOcr();
    if (!initialized) {
      throw new Error('OCR_SERVICE_UNAVAILABLE');
    }
    let result: textRecognition.TextRecognitionResult;
    try {
      result = await textRecognition.recognizeText({ pixelMap: pixelMap }, {
        isDirectionDetectionSupported: true
      });
    } catch (error) {
      hilog.warn(DOMAIN, 'SmartLens', 'Core Vision OCR unavailable: %{public}s', VisionManager.errorText(error));
      throw new Error('VISION_OCR_FAILED');
    }
    const items: RecognizedItem[] = [];
    for (const block of result.blocks) {
      for (const line of block.lines) {
        const value: string = line.value.trim();
        if (value.length > 0) {
          // Core Vision Kit OCR API 不返回逐字置信度；服务成功且返回有效行时使用 1.0。
          items.push({ label: '文字', value: value, score: 1.0 });
        }
      }
    }
    if (items.length === 0 && result.value.trim().length > 0) {
      items.push({ label: '文字', value: result.value.trim(), score: 1.0 });
    }
    return items;
  }

  static async recognizeDocument(pixelMap: image.PixelMap): Promise<RecognizedItem[]> {
    // 票据模式以 OCR 为主；物体模型不可用时仍允许输出真实 OCR 字段。
    let detected: RecognizedItem[] = [];
    try {
      detected = await VisionManager.recognizeObject(pixelMap);
    } catch {
      detected = [];
    }
    const text: RecognizedItem[] = await VisionManager.recognizeText(pixelMap);
    const documentItems: RecognizedItem[] = [];
    for (const item of detected) {
      if (item.value === '文档' || item.value === '卡片') {
        documentItems.push({ label: '文档类型', value: item.value, score: item.score });
      }
    }
    return documentItems.concat(VisionManager.extractDocumentFields(text)).concat(text);
  }

  private static request(pixelMap: image.PixelMap): visionBase.Request {
    const request: visionBase.Request = new visionBase.Request();
    request.inputData = { pixelMap: pixelMap };
    return request;
  }

  private static async ensureOcr(): Promise<boolean> {
    if (VisionManager.ocrInitPromise === undefined) {
      VisionManager.ocrInitPromise = textRecognition.init().then((initialized: boolean): boolean => {
        if (!initialized) {
          hilog.warn(DOMAIN, 'SmartLens', 'Core Vision OCR initialization returned false');
        }
        return initialized;
      }).catch((error: Object): boolean => {
        hilog.warn(DOMAIN, 'SmartLens', 'Core Vision OCR initialization failed: %{public}s', VisionManager.errorText(error));
        return false;
      });
    }
    return await VisionManager.ocrInitPromise;
  }

  private static errorText(error: Object): string {
    try {
      return JSON.stringify(error).slice(0, 256);
    } catch {
      return 'unknown';
    }
  }

  private static isValidScore(score: number): boolean {
    return score === score && score >= 0 && score <= 1;
  }

  private static objectLabel(label: number): string {
    switch (label) {
      case 0: return '场景';
      case 1: return '动物';
      case 2: return '植物';
      case 3: return '建筑';
      case 5: return '人脸';
      case 6: return '桌面';
      case 7: return '文字区域';
      case 8: return '人物';
      case 9: return '猫';
      case 10: return '狗';
      case 11: return '食物';
      case 12: return '汽车';
      case 13: return '人物';
      case 21: return '文档';
      case 22: return '卡片';
      default: return `类别 ${label}`;
    }
  }

  private static extractDocumentFields(text: RecognizedItem[]): RecognizedItem[] {
    const fields: RecognizedItem[] = [];
    for (const item of text) {
      const value: string = item.value.trim();
      VisionManager.addField(fields, '发票代码', VisionManager.match(value, /发票代码\s*[:：]?\s*([0-9]{6,20})/));
      VisionManager.addField(fields, '发票号码', VisionManager.match(value, /发票号码\s*[:：]?\s*([0-9]{6,20})/));
      VisionManager.addField(fields, '金额', VisionManager.match(value, /金额\s*[:：]?\s*[¥￥]?\s*([0-9]+(?:\.[0-9]{1,2})?)/));
      VisionManager.addField(fields, '税额', VisionManager.match(value, /税额\s*[:：]?\s*[¥￥]?\s*([0-9]+(?:\.[0-9]{1,2})?)/));
      VisionManager.addField(fields, '价税合计', VisionManager.match(value, /价税合计(?:小写)?\s*[:：]?\s*[¥￥]?\s*([0-9]+(?:\.[0-9]{1,2})?)/));
      VisionManager.addField(fields, '开票日期', VisionManager.match(value, /(?:开票日期|日期)\s*[:：]?\s*([0-9]{4}[年\/-][0-9]{1,2}[月\/-][0-9]{1,2}日?)/));
      const seller: string | undefined = VisionManager.match(value, /(?:销售方|销货单位|名称)\s*[:：]\s*(.+)/);
      VisionManager.addField(fields, '销售方', seller);
    }
    return fields;
  }

  private static match(value: string, pattern: RegExp): string | undefined {
    const match: RegExpMatchArray | null = value.match(pattern);
    return match !== null && match.length > 1 && match[1].trim().length > 0 ? match[1].trim() : undefined;
  }

  private static addField(fields: RecognizedItem[], label: string, value: string | undefined): void {
    if (value === undefined || fields.some((item: RecognizedItem) => item.label === label)) {
      return;
    }
    fields.push({ label: label, value: value, score: 1.0 });
  }
}
