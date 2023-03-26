import 'package:autozoom/imageViewer.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'cameraview.dart';

class ObjectDetectorView extends StatefulWidget {
  @override
  State<ObjectDetectorView> createState() => _ObjectDetectorView();
}

class _ObjectDetectorView extends State<ObjectDetectorView> {
  // late ObjectDetector _objectDetector;
  CustomPaint? _customPaint;
  String? _text;
  CameraImage ?_image;
  bool isViewing=false;


  @override
  Widget build(BuildContext context) {
    return  Stack(
      children: [
        CameraView(
            title: 'Object Detector',
            customPaint: _customPaint,
            text: _text,
            onImage: (inputImage) async{

              // print(inputImage.height);
              // print(inputImage.width);
              _image=inputImage;
            },
            // onScreenModeChanged: (image){},
            initialDirection: CameraLensDirection.back,
          ),
        Positioned(
          bottom: 40,
            child:  MaterialButton(
              color: Colors.blue,
                onPressed: () {
                  if(_image!=null){
                  //   isViewing=true;
                  //   setState(() {});
                  // }
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>
                      ImageViewer(image: _image!)));
              }
                  else {
                    print('no image');
                  }
                }
            ),
        )
      ],
    );
  }
}