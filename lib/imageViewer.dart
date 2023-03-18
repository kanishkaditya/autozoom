import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';


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
  final XFile image;
   ImageViewer({Key? key, required this.image}) : super(key: key);

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late ObjectDetector objectDetector;
  List<DetectedObject>objects=[];

  void initDetector()async{
    const mode = DetectionMode.stream;
    final modelPath = await _getModel('assets/ml/efficientnet2.tflite');
    final options = LocalObjectDetectorOptions(
        modelPath: modelPath,
        classifyObjects: true,
        multipleObjects: true,
        mode:mode
    );

    objectDetector = ObjectDetector(options: options);
    objects = await objectDetector.processImage(InputImage.fromFilePath(widget.image.path));
    // print(objects);
    setState(() {});
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {

    // double factorX = screen.width;
    // double factorY = screen.height;
    // print(objects.length);

    Color colorPick = Colors.pink;
    if(objects.isEmpty) {
      return [];
    } else if(objects[0].labels.isEmpty){
      // for(DetectedObject result in objects){
      //   for(Label label in result.labels)
      //
      //     print(label.text);
      // }
      return [];
    }

    // return objects.map((result) {
    final rect=objects[0].boundingBox;
    // if(objects[0].labels[0].text!='computer keyboard') return [];
    return [
      Positioned(
        left: rect.left ,
        top: rect.top,
        width: rect.width,
        height: rect.height,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),

          ),
          child: Text(
            "${objects[0].labels[0].text} ${(objects[0].labels[0].confidence * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.black,
              fontSize: 18.0,
            ),
          ),
        ),
      )
    ];
    // }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>list=[];
    list.add(Image.file(File(widget.image.path)));
    if(objects.isNotEmpty){
      list.addAll(displayBoxesAroundRecognizedObjects(MediaQuery.of(context).size));
    }
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
    // list.addAll());
  }
}
