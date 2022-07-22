import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:nyobavirpa/displaybesidebody.dart';

import 'main.dart';

class BesideBodyCamera extends StatefulWidget {
  final bool isCameraOverlayCircle;

  const BesideBodyCamera({Key? key, required this.isCameraOverlayCircle})
      : super(key: key);

  @override
  _BesideBodyCameraState createState() => _BesideBodyCameraState();
}

class _BesideBodyCameraState extends State<BesideBodyCamera> {
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

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
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
            return Stack(fit: StackFit.expand, children: [
              CameraPreview(controller),
            ]);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and then get the location
            // where the image file is saved.
            // final image = await controller.takePicture();
            await controller.takePicture().then((value) {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => SideBodyImage(
                        imagePath: value.path,
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

  Widget cameraOverlay(
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
      return Stack(
        fit: StackFit.expand,
        children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Container(width: horizontalPadding, color: color)),
          Align(
              alignment: Alignment.centerRight,
              child: Container(width: horizontalPadding, color: color)),
          Align(
              alignment: Alignment.topCenter,
              child: Container(
                  margin: EdgeInsets.only(
                      left: horizontalPadding, right: horizontalPadding),
                  height: verticalPadding,
                  color: color)),
          Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                  margin: EdgeInsets.only(
                      left: horizontalPadding, right: horizontalPadding),
                  height: verticalPadding,
                  color: color)),
          Container(
            margin: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: verticalPadding),
            decoration: BoxDecoration(border: Border.all(color: Colors.cyan)),
          )
        ],
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
