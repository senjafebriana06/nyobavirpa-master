import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';


class CroppingPage extends StatefulWidget {
  @override
  State<CroppingPage> createState() => _CroppingPageState();
}

class _CroppingPageState extends State<CroppingPage> {
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

      // Finish edit, convert to image render
      final ui.Picture picture = recorder.endRecording();
      final ui.Image img =
          await picture.toImage(rect.width.toInt(), rect.height.toInt());
      final ByteData? byteData2 = await img.toByteData(format: ui.ImageByteFormat.png);
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
  Widget build(BuildContext context) {
    return  Stack(
        fit: StackFit.expand,
        children: <Widget>[
          RepaintBoundary(
            key: _backgroundImgKey,
            child: Image.network(
              'https://wallpaperplay.com/walls/full/e/5/3/13586.jpg',
              fit: BoxFit.cover,
            ),
          ),
          ColorFiltered(
            // This one will create the magic
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.8), BlendMode.srcOut),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Container(
                  decoration: const BoxDecoration(
                      color: Colors.black,
                      // This one will handle background + difference out
                      backgroundBlendMode: BlendMode.dstOut),
                ),
                _WDraggable(
                  key: Key("1"),
                  child: Container(
                    key: _circleViewKey,
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Hello World',
                    style: TextStyle(fontSize: 70, fontWeight: FontWeight.w600),
                  ),
                )
              ],
            ),
          ),
          if (imgBytes != null)
            IgnorePointer(
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
          Center(
            child: RaisedButton(
              onPressed: () {
                _capturePng();
              },
              child: const Text('Capture'),
            ),
          )
        ],
    );
  }
  }

/// Draggable widget
class _WDraggable extends StatefulWidget {
  const _WDraggable({required Key key, required this.child, this.valueChanged}) : super(key: key);

  final Widget child;
  final ValueChanged<Offset>? valueChanged;

  @override
  _WDraggableState createState() => _WDraggableState();
}

class _WDraggableState extends State<_WDraggable> {
  ValueNotifier<Offset> valueListener = ValueNotifier<Offset>(const Offset(1, 1));

  @override
  void initState() {
    valueListener.addListener(_notifyParent);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        final GestureDetector handle = GestureDetector(
          onPanUpdate: (DragUpdateDetails details) {
            final double dx = (valueListener.value.dx +
                (details.delta.dx / context.size!.width))
                    .clamp(0.0, 1.0)
                    .toDouble();
            final double dy = (valueListener.value.dy -
                (details.delta.dy / context.size!.height))
                    .clamp(0.0, 1.0)
                    .toDouble();
            valueListener.value = Offset(dx, dy);
          },
          child: widget.child,
        );

        return AnimatedBuilder(
          animation: valueListener,
          builder: (_, Widget? child) {
            return Align(
              alignment: Alignment(valueListener.value.dx * 2 - 1,
                  1 - valueListener.value.dy * 2),
              child: child,
            );
          },
          child: handle,
        );
      },
    );
  }

  // Notify change to parent
  void _notifyParent() {
    if(widget.valueChanged != null) {
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
