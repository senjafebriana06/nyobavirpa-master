import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nyobavirpa/displayimage.dart';
import 'package:path_provider/path_provider.dart';

class HeadCroppingPage extends StatefulWidget {
  final String headImage;

  const HeadCroppingPage({Key? key, required this.headImage}) : super(key: key);

  @override
  State<HeadCroppingPage> createState() => _HeadCroppingPageState();
}

class _HeadCroppingPageState extends State<HeadCroppingPage> {
  final GlobalKey _backgroundImgKey = GlobalKey();
  final GlobalKey _circleViewKey = GlobalKey();
  Uint8List? imgBytes;

  ByteData _readFromFile(File file) {
    final Uint8List bytes = file.readAsBytesSync();
    return ByteData.view(bytes.buffer);
  }

  Future<File> _writeToFile(ByteData data) async {
    // https://pub.dev/packages/path_provider
    final String dir = (await getTemporaryDirectory()).path;
    final String filePath = '$dir/tempImage.jpg';
    final ByteBuffer buffer = data.buffer;
    return File(filePath).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  Future<ui.Image> _loadImageSource(File imageSource) async {
    // ByteData data = await rootBundle.load(asset);
    final ByteData data = _readFromFile(imageSource);
    final ui.Codec codec =
        await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  String generateRandomString(int len) {
    var r = Random();
    return String.fromCharCodes(
        List.generate(len, (index) => r.nextInt(33) + 89));
  }

  Future<Uint8List?> _capturePng() async {
    await Future.delayed(Duration(seconds: 1));
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
    WidgetsBinding.instance?.addPostFrameCallback((_) => _capturePng());
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    _backgroundImgKey.currentState?.dispose();
    _circleViewKey.currentState?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            RepaintBoundary(
              key: _backgroundImgKey,
              child: Image.file(
                File(widget.headImage),
                fit: BoxFit.cover,
              ),
            ),
            ColorFiltered(
              // This one will create the magic
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5), BlendMode.srcOut),
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
                    key: Key(generateRandomString(10)),
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
          ],
        ),
        floatingActionButton: FloatingActionButton(
          // Provide an onPressed callback.
          onPressed: () async {
            // Take the Picture in a try / catch block. If anything goes wrong,
            // catch the error.
            try {
              final tempDir = await getTemporaryDirectory();
              File file = await File('${tempDir.path}/image.png').create();
              file.writeAsBytesSync(imgBytes!.toList());

              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => DisplayImage(
                        imagePath: file.path,
                      )));
            } catch (e) {
              // If an error occurs, log the error to the console.
              print(e);
            }
          },
          child: const Icon(Icons.check),
        ));
  }
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
            return Align(
              //Atur posisi
              alignment: Alignment(0, 0),
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

bool validateAndSave() {
  var globalFromKey;
  final from = globalFromKey.currentState;
  if (from!.validate()) {
    from.save();
    return true;
  } else {
    return false;
  }
}
