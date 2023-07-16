import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'detector_view.dart';
import 'painters/face_detector_painter.dart';

class FaceDetectorView extends StatefulWidget {
  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.front;
  late Scene _scene;
  Object? _earth;

  void _onSceneCreated(Scene scene) {
    _scene = scene;
    _scene.camera.position.z = 35;
    _scene.camera.zoom = 25;
    _earth = Object(
      fileName: "assets/gun.obj",
      lighting: true,
    );
    _scene.light.position.setFrom(Vector3(0, 0, 16));
    _scene.world.add(_earth!);
  }

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              child: Center(
                child: Cube(
                  onSceneCreated: _onSceneCreated,
                ),
              ),
            ),
          ),
          Expanded(
            child: DetectorView(
              title: 'Face Detector',
              customPaint: _customPaint,
              text: _text,
              onImage: _processImage,
              initialCameraLensDirection: _cameraLensDirection,
              onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final faces = await _faceDetector.processImage(inputImage);
    if (inputImage.metadata?.size != null && inputImage.metadata?.rotation != null) {
      final painter = FaceDetectorPainter(
        faces,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      if (faces.isEmpty) {
        _text = 'No faces found';
      } else {
        print('Rotation: ${faces.first.headEulerAngleY}');
        if (_earth != null) {
          _earth!.rotation.y = faces.first.headEulerAngleY!.toDouble() * math.pi - 90;
          _earth!.rotation.z = -(faces.first.headEulerAngleX!.toDouble() * math.pi);
          _earth!.updateTransform();
          _scene.update();
        }
      }

      _customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'Faces found: ${faces.length}\n\n';
      for (final face in faces) {
        text += 'face: ${face.boundingBox}\n\n';
      }
      _text = text;
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
