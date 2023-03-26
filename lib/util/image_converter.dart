//@dart=2.9
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as imglib;
import 'package:flutter/material.dart';
import 'package:autozoom/main.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';


List<int> convertImagetoPng(CameraImage image)  {
  try {
    imglib.Image img;
    if (image.format.group == ImageFormatGroup.yuv420) {
      img = _convertYUV420(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      img = _convertBGRA8888(image);
    }

    imglib.PngEncoder pngEncoder = new imglib.PngEncoder();

    // Convert to png
    List<int> png = pngEncoder.encodeImage(img);
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
     image.width,
    image.height,
    image.planes[0].bytes,
    format: imglib.Format.bgra,
  );
}

// CameraImage YUV420_888 -> PNG -> Image (compresion:0, filter: none)
// Black
imglib.Image _convertYUV420(CameraImage image) {
  var img = imglib.Image(
       image.width,image.height); // Create Image buffer

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
      img.setPixelRgba(x, planeOffset ~/ image.width, (pixelColor << 16),
          (pixelColor << 8), (pixelColor), shift);
      // img.data!.[planeOffset + x] = newVal;
    }
  }

  return img;
}

Uint8List convertCameraImage(CameraImage image, Size size, Rect box) {
  int width = image.width;
  int height = image.height;
// imglib -> Image package from https://pub.dartlang.org/packages/image
  var img = imglib.Image(width, height); // Create Image buffer
  const int hexFF = 0xFF << 24;
  final int uvyButtonStride = image.planes[1].bytesPerRow;
  final int uvPixelStride = image.planes[1].bytesPerPixel;
  for (int x = 0; x < width; x++) {
    for (int y = 0; y < height; y++) {
      final int uvIndex =
          uvPixelStride * (x / 2).floor() + uvyButtonStride * (y / 2).floor();
      final int index = y * width + x;
      final yp = image.planes[0].bytes[index];
      final up = image.planes[1].bytes[uvIndex];
      final vp = image.planes[2].bytes[uvIndex];
// Calculate pixel color
      int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
      int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
          .round()
          .clamp(0, 255);
      int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
// color: 0x FF  FF  FF  FF
//           A   B   G   R
      img.setPixelRgba(x, y, r, g << 8, b << 16, hexFF);
    }
  }
// Rotate 90 degrees to upright
  var img1 = imglib.copyRotate(img, 90);
  double mediaHeight = size.height;
  imglib.Image fullImage = imglib.copyResize(img1,
      height: mediaHeight.round());
  fullImage=imglib.copyCrop(fullImage,  box.left.toInt(), box.top.toInt(), box.width.toInt(),  box.height.toInt());
  var _snapShot = imglib.encodePng(fullImage);
  // setState(() {_showSnapshot = true;});
  // Future.delayed(const Duration(seconds: 4), () {
  //   setState(() {_showSnapshot = false;});
  // });
  return _snapShot;
}

Future processCameraImage(CameraImage image) async {
  final WriteBuffer allBytes = WriteBuffer();
  for (final Plane plane in image.planes) {
    allBytes.putUint8List(plane.bytes);
  }
  final bytes = allBytes.done().buffer.asUint8List();

  final Size imageSize =
  Size(image.width.toDouble(), image.height.toDouble());

  final camera = cameras[0];
  final imageRotation =
  InputImageRotationValue.fromRawValue(camera.sensorOrientation);
  if (imageRotation == null) return;

  final inputImageFormat =
  InputImageFormatValue.fromRawValue(image.format.raw);
  if (inputImageFormat == null) return;

  final planeData = image.planes.map(
        (Plane plane) {
      return InputImagePlaneMetadata(
        bytesPerRow: plane.bytesPerRow,
        height: plane.height,
        width: plane.width,
      );
    },
  ).toList();

  final inputImageData = InputImageData(
    size: imageSize,
    imageRotation: imageRotation,
    inputImageFormat: inputImageFormat,
    planeData: planeData,
  );

  final inputImage =
  InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

  return inputImage;
}