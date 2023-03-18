import 'package:autozoom/imageViewer.dart';
import 'package:autozoom/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:camera/camera.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // late InputImage inputImage;

  late CameraController cameraController=CameraController(cameras![0], ResolutionPreset.max);


  initCamera() async{
    await cameraController.initialize().then((_) async{
      if (!mounted) {
        return;
      }
      setState(() {});
  });
  }

  // Future<List<Widget>> detectAndArrange(screen) async {
    // final WriteBuffer allBytes=WriteBuffer();
    // for( final Plane plane in image.planes){
    //   allBytes.putUint8List(plane.bytes);
    // }
    // final bytes=allBytes.done().buffer.asUint8List();
    //
    // final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    // final InputImageRotation? imageRotation =
    // InputImageRotationValue.fromRawValue(cameras![0].sensorOrientation);
    //
    // final InputImageFormat? inputImageFormat =
    // InputImageFormatValue.fromRawValue(image.format.raw);
    //
    // final planeData = image.planes.map(
    //       (Plane plane) {
    //     return InputImagePlaneMetadata(
    //       bytesPerRow: plane.bytesPerRow,
    //       height: plane.height,
    //       width: plane.width,
    //     );
    //   },
    // ).toList();
    //
    // final inputImageData = InputImageData(
    //   size: imageSize,
    //   imageRotation: imageRotation!,
    //   inputImageFormat: inputImageFormat!,
    //   planeData: planeData,
    // );

    //inputImage = InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    // return displayBoxesAroundRecognizedObjects(screen);
  // }

  @override
  void initState() {
    super.initState();
    initCamera();
  }



  @override
  Widget build(BuildContext context) {


    Size size = MediaQuery.of(context).size;
    List<Widget> list = [];

    list.add(
      Positioned(
        top: 0.0,
        left: 0.0,
        width: size.width,
        height: size.height - 100,
        child: SizedBox(
          height: size.height - 100,
          child: (!cameraController.value.isInitialized)
              ? Container()
              : AspectRatio(
              aspectRatio: cameraController.value.aspectRatio,
              child: CameraPreview(cameraController),
          ),
        ),
      ),
    );

    // if (objects.isNotEmpty) {
    //
    // }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          margin: const EdgeInsets.only(top: 50),
          color: Colors.black,
          child: Stack(
            children: [
              ...list,
              Positioned(
                bottom: 10,
                child: MaterialButton(
                  onPressed: ()async {
                     cameraController.takePicture().then((image)async{
                       Navigator.push(context, MaterialPageRoute(
                           builder: (context,)=>
                               ImageViewer(image:image)));
                    });
                  },
                  child: Text('take photo'),

                ),
              )
            ]
          ),

        ),
      ),
    );
  }

}