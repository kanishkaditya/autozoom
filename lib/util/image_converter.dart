import 'package:camera/camera.dart';
import 'package:image/image.dart' as imglib;
Future<List<int>?> convertImagetoPng(CameraImage image) async {
  try {
    imglib.Image ?img=null;
    if (image.format.group == ImageFormatGroup.yuv420) {
      img = _convertYUV420(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      img = _convertBGRA8888(image);
    }

    imglib.PngEncoder pngEncoder = new imglib.PngEncoder();

    // Convert to png
    List<int> png = pngEncoder.encode(img!);
    return png;
  } catch (e) {
    print(">>>>>>>>>>>> ERROR:" + e.toString());
  }
  return null;
}

// CameraImage BGRA8888 -> PNG
// Color
imglib.Image _convertBGRA8888(CameraImage image) {
  return imglib.Image.fromBytes(
    width:image.width,
    height:image.height,
    bytes:image.planes[0].bytes.buffer,
    format: imglib.Format.uint8,
  );
}

// CameraImage YUV420_888 -> PNG -> Image (compresion:0, filter: none)
// Black
imglib.Image _convertYUV420(CameraImage image) {
  var img = imglib.Image(width:image.width, height:image.height); // Create Image buffer

  Plane plane = image.planes[0];
  const int shift = (0xFF << 24);

  // Fill image buffer with plane[0] from YUV420_888
  for (int x = 0; x < image.width; x++) {
    for (int planeOffset = 0;
    planeOffset < image.height * image.width;
    planeOffset += image.width) {
      final pixelColor = plane.bytes[planeOffset + x];
      // color: 0x FF  FF  FF  FF
      //           A   B   G   R
      // Calculate pixel color
      // var newVal = shift | ( << 16) | (pixelColor << 8) | pixelColor;
      img.setPixelRgba(x, planeOffset~/image.width, (pixelColor << 16), (pixelColor << 8), (pixelColor), shift);
      // img.data!.[planeOffset + x] = newVal;
    }
  }

  return img;
}