import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../providers/camera_provider.dart'; // Import the provider

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  static const String routeName = '/capture'; // Add route name

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {

  @override
  void initState() {
    super.initState();
    // Initialize camera when the widget is first built
    // Use WidgetsBinding to ensure it runs after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeCamera();
    });
  }

  // No need for dispose method here as the provider handles controller disposal

  Future<void> _initializeCamera() async {
    // Trigger initialization via the provider
    await ref.read(cameraControllerProvider.notifier).initializeCamera();
  }

  // Cropping Logic
  Future<CroppedFile?> _cropImage(String filePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: filePath,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90, // Adjust quality as needed
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Crop Image',
          // TODO: Potentially add aspect ratio presets if needed
        ),
        // WebUiSettings is available too if needed
      ],
    );
    return croppedFile;
  }

  void _onTakePictureButtonPressed() async {
    final controller = ref.read(cameraControllerProvider.notifier).controller;
    if (controller == null || !controller.value.isInitialized) {
      print('Error: select a camera first.');
      return;
    }

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return;
    }

    try {
      final XFile imageFile = await controller.takePicture();
      if (!mounted) return;

      // Crop the taken picture
      final CroppedFile? croppedFile = await _cropImage(imageFile.path);

      if (croppedFile != null) {
        // TODO: Navigate or process the CROPPED image
        print('Cropped picture saved to ${croppedFile.path}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cropped Picture: ${croppedFile.path}')),
        );
      } else {
        print('Image cropping cancelled.');
      }

    } on CameraException catch (e) {
      print('Error taking picture: ${e.code}\n${e.description}');
       if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error taking picture: ${e.description}'))
        );
    }
  }

  void _onImportFromGalleryPressed() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
          if (!mounted) return;

          // Crop the selected image
          final CroppedFile? croppedFile = await _cropImage(image.path);

          if (croppedFile != null) {
            // TODO: Navigate or process the CROPPED image
            print('Cropped image selected from gallery: ${croppedFile.path}');
             if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cropped Image: ${croppedFile.path}')),
            );
          } else {
             print('Image cropping cancelled.');
          }
      }
    } catch (e) {
       print('Error picking image from gallery: $e');
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error selecting image: $e'))
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraControllerProvider);

    return Scaffold(
      // Use a transparent AppBar for fullscreen feel
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Tap to Capture',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: cameraState.when(
        data: (controller) {
          if (!controller.value.isInitialized) {
             // This state should ideally not be reached if initialization is handled correctly
             return const Center(child: Text('Camera not initialized'));
          }
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Ensure CameraPreview is built before the controls
              Center(
                child: AspectRatio(
                  // Use aspect ratio from controller to prevent distortion
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
              ),
              // Controls Overlay
              _buildControlsOverlay(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Failed to initialize camera:\n$error',
                style: const TextStyle(color: Colors.red)),
            ),
          ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned(
      bottom: 30.0,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.photo_library, size: 40),
            color: Colors.white,
            onPressed: _onImportFromGalleryPressed,
            tooltip: 'Import from Gallery',
          ),
          Container(
             decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, size: 60),
              color: Colors.white,
              onPressed: ref.watch(cameraControllerProvider).isLoading ? null : _onTakePictureButtonPressed,
              tooltip: 'Take Picture',
            ),
          ),
          const SizedBox(width: 40), // Placeholder for symmetry
        ],
      ),
    );
  }
} 