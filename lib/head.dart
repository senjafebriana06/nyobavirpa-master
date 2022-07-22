import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:nyobavirpa/headcropping.dart';
import 'displayimage.dart';
import 'main.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class HeadCamera extends StatefulWidget {
  final bool isCameraOverlayCircle;

  const HeadCamera({Key? key, required this.isCameraOverlayCircle})
      : super(key: key);

  @override
  _HeadCameraState createState() => _HeadCameraState();
}

class _HeadCameraState extends State<HeadCamera> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController controller;
  late Future<void> _initializeControllerFuture;

  final GlobalKey _backgroundImgKey = GlobalKey();
  final GlobalKey _circleViewKey = GlobalKey();
  Uint8List? imgBytes;

  ByteData _readFromFile(File file) {
    final Uint8List bytes = file.readAsBytesSync();
    return ByteData.view(bytes.buffer);
  }

  Future<Uint8List?> _capturePng() async {
    try {
      final RenderBox circleBoundary =
          _circleViewKey.currentContext!.findRenderObject() as RenderBox;
      final Size circleBoundarySize = circleBoundary.size;
      final Offset globalTopLeft = circleBoundary.localToGlobal(Offset.zero);

      final RenderRepaintBoundary backgroundBoundary =
          _backgroundImgKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      // Background to image
      const double scale = 2.0;
      final double outputW = circleBoundarySize.width * scale;
      final double outputH = circleBoundarySize.height * scale;
      final double srcLeft = globalTopLeft.dx * scale;
      final double srcTop = globalTopLeft.dy * scale;
      final ui.Image image =
          await backgroundBoundary.toImage(pixelRatio: scale);

      // Edit background image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Rect rect = Rect.fromLTWH(0, 0, outputW, outputH);
      final Canvas canvas = Canvas(recorder, rect);
      final Paint paint = Paint();

      // Clip circle
      final Path path = Path()..addOval(Rect.fromLTWH(0, 0, outputW, outputH));
      // Requires save and restore canvas to local clipPath
      canvas.save();
      canvas.clipPath(path);
      canvas.drawImageRect(
          image,
          Rect.fromLTWH(srcLeft, srcTop, outputW, outputH),
          Rect.fromLTWH(0, 0, outputW, outputH),
          paint);
      canvas.restore();

      final ui.Picture picture = recorder.endRecording();
      final ui.Image img =
          await picture.toImage(rect.width.toInt(), rect.height.toInt());
      final ByteData? byteData2 =
          await img.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes2 = byteData2!.buffer.asUint8List();
      final String bs642 = base64Encode(pngBytes2);
      print(pngBytes2);
      print(bs642);
      setState(() {
        imgBytes = pngBytes2;
      });
      return pngBytes2;
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.high);
    _initializeControllerFuture = controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                RepaintBoundary(
                  key: _backgroundImgKey,
                  child: CameraPreview(controller),
                ),
                ColorFiltered(
                  // This one will create the magic
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.6), BlendMode.srcOut),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Container(
                        decoration: const BoxDecoration(
                            color: Colors.black,
                            // This one will handle background + difference out
                            backgroundBlendMode: BlendMode.dstOut),
                      ),
                      //Atur Ukuran
                      _WDraggable(
                        key: Key("1"),
                        child: Container(
                          key: _circleViewKey,
                          height: 300,
                          width: 300,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(150),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (imgBytes != null)
                  Center(
                    child: IgnorePointer(
                      child: Container(
                        alignment: Alignment.bottomCenter,
                        child: Image.memory(
                          imgBytes!,
                          height: 200,
                          width: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
              ],
            );
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            await controller.takePicture().then((value) {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => HeadCroppingPage(
                        headImage: value.path,
                      )));
            });
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Widget cameraOverlayCircle(
      {required double padding,
      required double aspectRatio,
      required Color color}) {
    return LayoutBuilder(builder: (context, constraints) {
      double parentAspectRatio = constraints.maxWidth / constraints.maxHeight;
      double horizontalPadding;
      double verticalPadding;

      if (parentAspectRatio < aspectRatio) {
        horizontalPadding = padding;
        verticalPadding = (constraints.maxHeight -
                ((constraints.maxWidth - 2 * padding) / aspectRatio)) /
            2;
      } else {
        verticalPadding = padding;
        horizontalPadding = (constraints.maxWidth -
                ((constraints.maxHeight - 2 * padding) * aspectRatio)) /
            2;
      }
      return 
          IgnorePointer(
            child: ClipPath(
              clipper: InvertedCircleClipper(),
              child: Container(
                color: const Color.fromRGBO(0, 0, 0, 0.5),
              ),
            ),
          );
    });
  }
}

class InvertedCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..addOval(Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width * 0.45))
      ..addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Draggable widget
class _WDraggable extends StatefulWidget {
  const _WDraggable({required Key key, required this.child, this.valueChanged})
      : super(key: key);

  final Widget child;
  final ValueChanged<Offset>? valueChanged;

  @override
  _WDraggableState createState() => _WDraggableState();
}

class _WDraggableState extends State<_WDraggable> {
  ValueNotifier<Offset> valueListener =
      ValueNotifier<Offset>(const Offset(1, 1));

  @override
  void initState() {
    valueListener.addListener(_notifyParent);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return AnimatedBuilder(
          animation: valueListener,
          builder: (_, Widget? child) {
            //Atur posisi
            return Align(
              alignment: Alignment(0,0),
              child: child,
            );
          },
          child: widget.child,
        );
      },
    );
  }

  // Notify change to parent
  void _notifyParent() {
    if (widget.valueChanged != null) {
      if (widget.valueChanged != null) {
        widget.valueChanged!(valueListener.value);
      }
    }
  }
}
