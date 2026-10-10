import { image } from '@kit.ImageKit';
import { camera } from '@kit.CameraKit';

/**
 * 将相机和系统相册输出统一转换为 Core Vision Kit 要求的 RGBA PixelMap。
 * 这里不保存原图；调用方负责在识别完成后释放 PixelMap。
 */
export class ImageProcessingService {
  static async fromCapturePhoto(photo: camera.CapturePhoto): Promise<image.PixelMap> {
    const main: image.Image | image.Picture = photo.main;
    if (ImageProcessingService.isPicture(main)) {
      const picture: image.Picture = main as image.Picture;
      const pixelMap: image.PixelMap = await picture.getMainPixelmap().clone();
      return await ImageProcessingService.toRgba(pixelMap);
    }

    const photoImage: image.Image = main as image.Image;
    const jpegComponent: image.Component = await photoImage.getComponent(image.ComponentType.JPEG);
    const source: image.ImageSource = image.createImageSource(jpegComponent.byteBuffer);
    try {
      const pixelMap: image.PixelMap = await source.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });
      return await ImageProcessingService.toRgba(pixelMap);
    } finally {
      await source.release();
    }
  }

  static async fromUri(uri: string): Promise<image.PixelMap> {
    if (uri.length === 0) {
      throw new Error('IMAGE_URI_EMPTY');
    }
    const source: image.ImageSource = image.createImageSource(uri);
    try {
      const pixelMap: image.PixelMap = await source.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });
      return await ImageProcessingService.toRgba(pixelMap);
    } finally {
      await source.release();
    }
  }

  static async release(pixelMap: image.PixelMap): Promise<void> {
    try {
      await pixelMap.release();
    } catch {
      // 释放需要具备幂等性；识别失败时不影响页面降级提示。
    }
  }

  private static async toRgba(pixelMap: image.PixelMap): Promise<image.PixelMap> {
    try {
      const info: image.ImageInfo = pixelMap.getImageInfoSync();
      if (info.pixelFormat === image.PixelMapFormat.RGBA_8888) {
        return pixelMap;
      }
      await pixelMap.convertPixelFormat(image.PixelMapFormat.RGBA_8888);
      return pixelMap;
    } catch {
      await ImageProcessingService.release(pixelMap);
      throw new Error('PIXELMAP_RGBA_CONVERSION_FAILED');
    }
  }

  private static isPicture(value: image.Image | image.Picture): boolean {
    return typeof (value as image.Picture).getMainPixelmap === 'function';
  }
}
