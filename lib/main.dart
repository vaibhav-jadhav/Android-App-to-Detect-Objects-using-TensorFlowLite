import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(MyApp());
}

const String ssd = "SSD MobileNet";
const String yolo = "Tiny YOLOv2";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TfliteHome(),
    );
  }
}

class TfliteHome extends StatefulWidget {
  @override
  _TfliteHomeState createState() => _TfliteHomeState();
}

class _TfliteHomeState extends State<TfliteHome> {
  String _model = ssd ;
  File _image;
  int _currentIndex = 0;
  final List<Widget> _children = [];
  double _imageWidth;
  double _imageHeight;
  bool _busy = false;

  List _recognitions;

  @override
  void initState() {
    super.initState();
    _busy = true;

    loadModel().then((val) {
      setState(() {
        _busy = false;
      });
    });
  }

  loadModel() async {
    Tflite.close();
    try {
      String res;
      if (_model == yolo) {
        res = await Tflite.loadModel(
          model: "assets/tflite/yolov2_tiny.tflite",
          labels: "assets/tflite/yolov2_tiny.txt",
        );
      } else {
        res = await Tflite.loadModel(
          model: "assets/tflite/ssd_mobilenet.tflite",
          labels: "assets/tflite/ssd_mobilenet.txt",
        );
      }
      print(res);
    } on PlatformException {
      print("Failed to load the model");
    }
  }
////////////////////////////////////////////////////////
  selectFromImagePicker() async
   {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _busy = true;
    });
    predictImage(image);
  }
  /////////////////////////////////
  void onTabTapped(int index)async
   {
     print(index);
   setState(()async
    {
      var image;
     _currentIndex = index;
     if(index == 0)
         image = await ImagePicker.pickImage(source: ImageSource.camera);
    if(index==1)
         image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if(index == 2)
    {
        showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog( 
                  elevation: 16.0,
                  title: Center(child: Text('Hello There ')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        
                        child: Text(
                          "Which model do you want to use ?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          FlatButton(
                              
                              child: Text('ssd'),
                              onPressed: () 
                              {
                               // _model=ssd;
                                Navigator.of(context).pop();
                              }),
                          FlatButton(
                              child: Text('yolo'),
                              onPressed: ()
                               {
                                //_model=yolo;
                                Navigator.of(context).pop();
                              })
                        ])
                    ],
                  ),
                );
              });
    }
    if (image == null) return;
    setState(() {
      _busy = true;
    });
    predictImage(image);

   });
 }
////////////////////////
  predictImage(File image) async
   {
    if (image == null) return;
    print("@@@@@@@@@@@@@@@@@@@@@");
    print(_model);
    if (_model == yolo) {
      await yolov2Tiny(image);
    } else {
      await ssdMobileNet(image);
    }

    FileImage(image)
        .resolve(ImageConfiguration())
        .addListener((ImageStreamListener((ImageInfo info, bool _) {
          setState(()
           {
            _imageWidth = info.image.width.toDouble();
            _imageHeight = info.image.height.toDouble();
          });
        })));

    setState(() {
      _image = image;
      _busy = false;
    });
  }

  yolov2Tiny(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
        path: image.path,
        model: "YOLO",
        threshold: 0.3,
        imageMean: 0.0,
        imageStd: 255.0,
        numResultsPerClass: 1);

    setState(() {
      _recognitions = recognitions;
    });
  }

  ssdMobileNet(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
        path: image.path, numResultsPerClass: 1);

    setState(() {
      _recognitions = recognitions;
    });
  }

  List<Widget> renderBoxes(Size screen) {
    if (_recognitions == null) return [];
    if (_imageWidth == null || _imageHeight == null) return [];

    double factorX = screen.width;
    double factorY = _imageHeight / _imageHeight * screen.width;

    Color blue = Colors.red;

    return _recognitions.map((re) {
      return Positioned(
        left: re["rect"]["x"] * factorX,
        top: re["rect"]["y"] * factorY,
        width: re["rect"]["w"] * factorX,
        height: re["rect"]["h"] * factorY,
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(
            color: blue,
            width: 3,
          )),
          child: Text(
            "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = blue,
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    List<Widget> stackChildren = [];
     //////
    stackChildren.add(Positioned(
      top: 0.0,
      left: 0.0,
      width: size.width,
      child: _image == null ? Text("Select an Image") : Image.file(_image),
    ));

    stackChildren.addAll(renderBoxes(size));



    if (_busy) {
      stackChildren.add(Center(



        child: CircularProgressIndicator(),
      ));
    }

    return Scaffold(
        backgroundColor: Color.fromARGB(255, 236, 217, 217),
       appBar: AppBar(

         backgroundColor: Colors.blue[300],
         title: Text("Object Detection using Tensorflow Lite"),
         bottomOpacity: 1,
       ),
      
      //  floatingActionButton: FloatingActionButton(
      //    child: Icon(Icons.camera_alt),
      //    tooltip: "Pick Image from gallery",
      //    onPressed: selectFromImagePicker,
      //  ),
      body: Stack(
        children: stackChildren,
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue[300],
         onTap: onTabTapped,
        currentIndex: _currentIndex,
       
        items: [
          BottomNavigationBarItem(
            icon: new Icon(Icons.camera_alt),
            title: new Text("Camera")
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.photo_album),
            title: new Text("Gallery"),
            
          ),
           BottomNavigationBarItem(
            icon: new Icon(Icons.settings_applications),
            title: new Text("Set Model",
            style: TextStyle(
              fontSize: 12,
            ),
            

            
          ),
           )
        ],
      ),
    );
  }
}
