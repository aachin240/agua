import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraCaptureScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraCaptureScreen({
    super.key,
    required this.camera,
  });

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  late CameraController controller;
  bool listo = false;
  bool tomando = false;

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      widget.camera,
      ResolutionPreset.max,
      enableAudio: false,
    );

    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        listo = true;
      });
    }).catchError((e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cámara: $e')),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> capturar() async {
    if (!controller.value.isInitialized || controller.value.isTakingPicture) {
      return;
    }

    setState(() {
      tomando = true;
    });

    try {
      final XFile file = await controller.takePicture();
      if (!mounted) return;
      Navigator.pop(context, file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al capturar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          tomando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tomar foto')),
      body: listo
          ? Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(controller),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: FloatingActionButton(
                onPressed: tomando ? null : capturar,
                child: const Icon(Icons.camera_alt),
              ),
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}