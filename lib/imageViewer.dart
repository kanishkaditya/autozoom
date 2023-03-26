import 'dart:isolate';

import 'package:autozoom/tflite/classifier.dart';
import 'package:autozoom/tflite/recognition.dart';
import 'package:autozoom/util/image_converter.dart';
import 'package:autozoom/util/isolate_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

// Future<String> _getModel(String assetPath) async {
//   if (Platform.isAndroid) {
//     return 'flutter_assets/$assetPath';
//   }
//   final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
//   await Directory(pt.dirname(path)).create(recursive: true);
//   final file = File(path);
//   if (!await file.exists()) {
//     final byteData = await rootBundle.load(assetPath);
//     await file.writeAsBytes(byteData.buffer
//         .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
//   }
//   return file.path;
// }

class ImageViewer extends StatefulWidget {
  final CameraImage image;

  const ImageViewer({Key? key, required this.image}) : super(key: key);

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> with WidgetsBindingObserver {
  late ObjectDetector objectDetector;
  Uint8List? rgbimage;
  IsolateUtils ?isolateUtils;
  Classifier ?classifier;
  List<Recognition>?recognition;

  void initStateAsync() async {
    WidgetsBinding.instance.addObserver(this);
    isolateUtils = IsolateUtils();
    await isolateUtils?.start();
    classifier = Classifier();
    Future.delayed(Duration(seconds: 3),()async{
      await detectImage(widget.image);
    });

  }

  detectImage(CameraImage cameraImage) async {
    // print(classifier!.interpreter);
    // print(classifier!.labels);
    if (classifier!.interpreter != null && classifier!.labels != null) {
      // If previous inference has not completed then return
      // print('bi');
      var uiThreadTimeStart = DateTime.now().millisecondsSinceEpoch;

      // Data to be passed to inference isolate
      var isolateData = IsolateData(
          cameraImage, classifier!.interpreter.address, classifier!.labels);
      Map<String, dynamic> inferenceResults = await inference(isolateData);

      var uiThreadInferenceElapsedTime =
          DateTime.now().millisecondsSinceEpoch - uiThreadTimeStart;

      // pass results to HomeView
      recognition=inferenceResults["recognitions"];
      print(recognition![0].label);
      if(recognition!=null){
        print(recognition![0].location);
        rgbimage =  convertCameraImage(widget.image, MediaQuery.of(context).size,recognition![0].location );

      }
      setState(() {});
      // // pass stats to HomeView
      // widget.statsCallback((inferenceResults["stats"] as Stats)
      //   ..totalElapsedTime = uiThreadInferenceElapsedTime);

    }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  Future<Map<String, dynamic>> inference(IsolateData isolateData) async {
    ReceivePort responsePort = ReceivePort();
    isolateUtils!.sendPort
        .send(isolateData..responsePort = responsePort.sendPort);
    var results = await responsePort.first;
    return results;
  }
  // void initDetector() async {
  //   const mode = DetectionMode.single;
  //   final modelPath = await _getModel('assets/ml/mobilenet.tflite');
  //   final options = LocalObjectDetectorOptions(
  //       modelPath: modelPath,
  //       classifyObjects: true,
  //       multipleObjects: true,
  //       mode: mode);
  //
  //   objectDetector = ObjectDetector(options: options);
  //   // print(widget.image.height, widget.image.);
  //   // print('hi');
  //   InputImage img = await processCameraImage(widget.image);
  //   objects = await objectDetector.processImage(img);
  //   if(objects.isNotEmpty) {
  //     rgbimage =  convertCameraImage(widget.image, MediaQuery.of(context).size, objects[0].boundingBox);
  //   }
  //
  //   print('-------------------------------------------------------------------');
  //   for (DetectedObject obj in objects)
  //     {
  //       for (Label l in obj.labels) {
  //       print(l.text);
  //       print('${obj.boundingBox.top} ${obj.boundingBox.left}');
  //     }
  //     }
  //   print('-------------------------------------------------------------------');
  //   setState(() {});
  // }


  // List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
  //   // double factorX = screen.width;
  //   // double factorY = screen.height;
  //   // print(objects.length);
  //
  //   Color colorPick = Colors.pink;
  //   if (objects.isEmpty) {
  //     return [];
  //   } else if (objects[0].labels.isEmpty) {
  //     // for(DetectedObject result in objects){
  //     //   for(Label label in result.labels)
  //     //
  //     //     print(label.text);
  //     // }
  //     return [];
  //   }
  //
  //   // return objects.map((result) {
  //   final rect = objects[0].boundingBox;
  //   // if(objects[0].labels[0].text!='computer keyboard') return [];
  //   return [
  //     Positioned(
  //       left: rect.left,
  //       top: rect.top,
  //       width: rect.width,
  //       height: rect.height,
  //       child: Container(
  //         decoration: BoxDecoration(
  //           borderRadius: const BorderRadius.all(Radius.circular(10.0)),
  //           border: Border.all(color: Colors.pink, width: 2.0),
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
    List<Widget> list = [];
    if (rgbimage != null) {
      list.add(Image.memory(rgbimage!));
    }
    return Scaffold(

      // body: Zoom(
      //   // maxZoomWidth: 1800,
      //   // maxZoomHeight: 1800,
      //   canvasColor: Colors.grey,
      //   backgroundColor: Colors.orange,
      //   colorScrollBars: Colors.purple,
      //   opacityScrollBars: 0.9,
      //   scrollWeight: 10.0,
      //   // initPosition: objects.isNotEmpty?Offset(objects[0].boundingBox.left, objects[0].boundingBox.top):Offset(0,0),
      //   centerOnScale: false,
      //   enableScroll: false,
      //   doubleTapZoom: false,
      //   zoomSensibility: 0.05,
      //   // initPosition: Offset(280,280),
      //   onTap: () {
      //     // print("Widget clicked");
      //   },
      //   // onPositionUpdate: (position) {
      //   //   setState(() {
      //   //     x = position.dx;
      //   //     y = position.dy;
      //   //   });
      //   // },
      //   // onScaleUpdate: (scale, zoom) {
      //   //   setState(() {
      //   //     // _zoom = zoom;
      //   //   });
      //   // },
      //
      //   child: list[0]
      // ),
      // body: InteractiveViewer(
      //   o
      //   child: list[0],
      // ),
      // body: Transform(
      //   transform:  Matrix4.diagonal3(vector.Vector3(2,2,1)),
      //   // alignment: FractionalOffset.center,
      //   origin: objects.isNotEmpty?Offset(objects[0].boundingBox.left, objects[0].boundingBox.top):Offset(0,0),
      //   child: list.isNotEmpty?list[0]:Container(height: 280,width: 280,)
      // ),

      body:Stack(
        children:list
      )
    );
  }

  @override
  void initState() {
    super.initState();
    initStateAsync();
    // detectImage(widget.image);
  }

}
