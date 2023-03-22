import 'dart:io';
import 'package:autozoom/util/image_converter.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'main.dart';


Future<String> _getModel(String assetPath) async {
  if (Platform.isAndroid) {
    return 'flutter_assets/$assetPath';
  }
  final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
  await Directory(dirname(path)).create(recursive: true);
  final file = File(path);
  if (!await file.exists()) {
    final byteData = await rootBundle.load(assetPath);
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  }
  return file.path;
}


class ImageViewer extends StatefulWidget {
  final CameraImage image;
   const ImageViewer({Key? key, required this.image}) : super(key: key);

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late ObjectDetector objectDetector;
  List<DetectedObject>objects=[];
  List<int> ?rgbimage;

  void initDetector()async{
    const mode = DetectionMode.single;
    final modelPath = await _getModel('assets/ml/efficientnet2.tflite');
    final options = LocalObjectDetectorOptions(
        modelPath: modelPath,
        classifyObjects: true,
        multipleObjects: true,
        mode:mode
    );

    objectDetector = ObjectDetector(options: options);
    // print(widget.image.height, widget.image.);
    // print('hi');
    InputImage img=await _processCameraImage(widget.image);
    objects = await objectDetector.processImage(img);
    for(DetectedObject obj in objects)
      for(Label l in obj.labels)
        print(l.text);
    setState(() {});
  }
  Future _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
    Size(image.width.toDouble(), image.height.toDouble());

    final camera = cameras![0];
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
  // List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
  //
  //   // double factorX = screen.width;
  //   // double factorY = screen.height;
  //   // print(objects.length);
  //
  //   Color colorPick = Colors.pink;
  //   if(objects.isEmpty) {
  //     return [];
  //   } else if(objects[0].labels.isEmpty){
  //     // for(DetectedObject result in objects){
  //     //   for(Label label in result.labels)
  //     //
  //     //     print(label.text);
  //     // }
  //     return [];
  //   }
  //
  //   // return objects.map((result) {
  //   final rect=objects[0].boundingBox;
  //   // if(objects[0].labels[0].text!='computer keyboard') return [];
  //   return [
  //     Positioned(
  //       left: rect.left ,
  //       top: rect.top,
  //       width: rect.width,
  //       height: rect.height,
  //       child: Container(
  //         decoration: BoxDecoration(
  //           borderRadius: const BorderRadius.all(Radius.circular(10.0)),
  //           border: Border.all(color: Colors.pink, width: 2.0),
  //
  //         ),
  //         child: Text(
  //           "${objects[0].labels[0].text} ${(objects[0].labels[0].confidence * 100).toStringAsFixed(0)}%",
  //           style: TextStyle(
  //             background: Paint()..color = colorPick,
  //             color: Colors.black,
  //             fontSize: 18.0,
  //           ),
  //         ),
  //       ),
  //     )
  //   ];
  //   // }).toList();
  // }

  @override
  Widget build(BuildContext context) {
    List<Widget>list=[];
    // print(widget.image.bytes);
    // Size s=widget.image.inputImageData!.size;
    // Bitmap bitmap=Bitmap.fromHeadful(s.width.toInt(), s.height.toInt(), widget.image.bytes!);
    // Uint8List headedBitmap=bitmap.buildHeaded();
    // print()
    if(rgbimage!=null)
    list.add(Image.memory(Uint8List.fromList(rgbimage!)));
    // if(objects.isNotEmpty){
    //   list.addAll(displayBoxesAroundRecognizedObjects(MediaQuery.of(context).size));
    // }
    return Scaffold(
      body: Stack(
        children:list
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    initDetector();
    changeformat();
    // list.addAll());
  }
  void changeformat()async{
    rgbimage=await convertImagetoPng(widget.image);
    setState(() {});
  }
}
