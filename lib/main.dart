import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';

import 'data/image_item.dart';
import 'main.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> {
  Uint8List? imageData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAsset("image.jpeg");
  }

  void loadAsset(String name) async {
    var data = await rootBundle.load('assets/$name');
    setState(() {
      imageData = data.buffer.asUint8List();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: isLoading ? CircularProgressIndicator() : DocEditor(image: imageData),
    );
  }
}

@protected
final scaffoldGlobalKey = GlobalKey<ScaffoldState>();





class DocEditor extends StatefulWidget {
  final dynamic image;
  const DocEditor({super.key, this.image});

  @override
  State<DocEditor> createState() => _DocEditorState();
}

class _DocEditorState extends State<DocEditor> {


  ImageItem currentImage = ImageItem();

  ScreenshotController screenshotController = ScreenshotController();
  int rotateValue = 0;
  late Size viewportSize;

  @override
  void initState() {
    if (widget.image != null) {
      loadImage(widget.image!);
    }
    super.initState();
  }

  Future<void> loadImage(dynamic imageFile) async {
    await currentImage.load(imageFile);
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    viewportSize = MediaQuery.of(context).size;

    return Scaffold(
      key: scaffoldGlobalKey,
      body: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: const Icon(Icons.check),
              onPressed: () async {

              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Screenshot(
                controller: screenshotController,
                child: RotatedBox(
                  quarterTurns: rotateValue,
                  child:  Image.memory(
                    currentImage.bytes,
                  )
                ),
              ),
            ),

            Container(
              color: Colors.grey,
              width: viewportSize.width,
              height: 100,
              child: Row(
                children: [

                  IconButton(
                    icon: const Icon(Icons.rotate_right),
                    onPressed: () {
                      setState(() {
                        rotateValue = (rotateValue + 1) % 4;
                      });
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.crop),
                    onPressed: () async {

                      Uint8List? croppedImage = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageCropper(
                            image: currentImage.bytes,
                          ),
                        ),
                      );

                      if (croppedImage == null) return;
                      rotateValue = 0;

                      await currentImage.load(croppedImage);
                      setState(() {});
                    },
                  ),
                ],

              ),

            )

          ],
        ),
      ),

    );
  }
}


class ImageCropper extends StatefulWidget {
  final Uint8List image;
  final List<AspectRatio> availableRatios;

  const ImageCropper({
    super.key,
    required this.image,
    this.availableRatios = const [
      AspectRatio(title: 'Freeform'),
      AspectRatio(title: '1:1', ratio: 1),
      AspectRatio(title: '4:3', ratio: 4 / 3),
      AspectRatio(title: '5:4', ratio: 5 / 4),
      AspectRatio(title: '7:5', ratio: 7 / 5),
      AspectRatio(title: '16:9', ratio: 16 / 9),
    ],
  });

  @override
  createState() => _ImageCropperState();
}

class _ImageCropperState extends State<ImageCropper> {
  final GlobalKey<ExtendedImageEditorState> _controller = GlobalKey<ExtendedImageEditorState>();

  double? currentRatio;
  bool isLandscape = true;
  int rotateAngle = 0;

  double? get aspectRatio => currentRatio == null
      ? null
      : isLandscape
      ? currentRatio!
      : (1 / currentRatio!);

  @override
  void initState() {
    if (widget.availableRatios.isNotEmpty) {
      currentRatio = widget.availableRatios.first.ratio;
    }
    _controller.currentState?.rotate(right: true);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.currentState != null) {
      // _controller.currentState?.
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            icon: const Icon(Icons.check),
            onPressed: () async {
              var state = _controller.currentState;

              if (state == null || state.getCropRect() == null) {
                Navigator.pop(context);
              }

              var data = await cropImageWithThread(
                imageBytes: state!.rawImageData,
                rect: state.getCropRect()!,
              );

              if (mounted) Navigator.pop(context, data);
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: ExtendedImage.memory(
          widget.image,
          cacheRawData: true,
          fit: BoxFit.contain,
          extendedImageEditorKey: _controller,
          mode: ExtendedImageMode.editor,
          initEditorConfigHandler: (state) {
            return EditorConfig(
              cropAspectRatio: aspectRatio,
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          height: 80,
          child: Container(
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.black
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // if (currentRatio != null && currentRatio != 1)
                  //   IconButton(
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 8,
                  //       vertical: 4,
                  //     ),
                  //     icon: Icon(
                  //       Icons.portrait,
                  //       color: isLandscape ? Colors.grey : Colors.white,
                  //     ),
                  //     onPressed: () {
                  //       isLandscape = false;
                  //
                  //       setState(() {});
                  //     },
                  //   ),
                  // if (currentRatio != null && currentRatio != 1)
                  //   IconButton(
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 8,
                  //       vertical: 4,
                  //     ),
                  //     icon: Icon(
                  //       Icons.landscape,
                  //       color: isLandscape ? Colors.white : Colors.grey,
                  //     ),
                  //     onPressed: () {
                  //       isLandscape = true;
                  //
                  //       setState(() {});
                  //     },
                  //   ),
                  for (var ratio in widget.availableRatios)
                    TextButton(
                      onPressed: () {
                        currentRatio = ratio.ratio;
                        setState(() {});
                      },
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Text(
                            ratio.title,
                            style: TextStyle(
                              color: currentRatio == ratio.ratio
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          )),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> cropImageWithThread({
    required Uint8List imageBytes,
    required Rect rect,
  }) async {
    img.Command cropTask = img.Command();
    cropTask.decodeImage(imageBytes);

    cropTask.copyCrop(
      x: rect.topLeft.dx.ceil(),
      y: rect.topLeft.dy.ceil(),
      height: rect.height.ceil(),
      width: rect.width.ceil(),
    );

    img.Command encodeTask = img.Command();
    encodeTask.subCommand = cropTask;
    encodeTask.encodeJpg();

    return encodeTask.getBytesThread();
  }
}

class AspectRatio {
  final String title;
  final double? ratio;

  const AspectRatio({required this.title, this.ratio});
}