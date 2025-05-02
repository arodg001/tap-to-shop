import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../providers/camera_provider.dart'; // Import the provider
import 'package:shopapp/services/vision_service.dart'; // Import VisionService
import 'package:shopapp/screens/results_screen.dart'; // Import ResultsScreen

// Provider for vision processing loading state
final _visionProcessingProvider = StateProvider<bool>((ref) => false);

// Provider to hold the latest vision results for passing to ResultsScreen
// This avoids passing complex data directly via Navigator arguments
final visionResultsProvider = StateProvider<List<MatchResultModel>?>((ref) => null);

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

  // Common function to handle image processing and navigation
  Future<void> _processImage(String imagePath) async {
    ref.read(_visionProcessingProvider.notifier).state = true;
    ref.read(visionResultsProvider.notifier).state = null; // Clear previous results
    try {
      final visionService = ref.read(visionServiceProvider);
      // Call the updated service method
      final List<MatchResultModel> results = await visionService.identifyProducts(imagePath);

      // Store results in the provider
      ref.read(visionResultsProvider.notifier).state = results;

      // Navigate to Results screen (no longer passing arguments directly)
      if (mounted) {
        Navigator.pushNamed(context, ResultsScreen.routeName);
      }
    } catch (e) {
      print('Error during vision processing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image processing failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        ref.read(_visionProcessingProvider.notifier).state = false;
      }
    }
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

      final CroppedFile? croppedFile = await _cropImage(imageFile.path);

      if (croppedFile != null) {
        print('Cropped picture saved to ${croppedFile.path}');
        await _processImage(croppedFile.path); // Process the cropped image
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

        final CroppedFile? croppedFile = await _cropImage(image.path);

        if (croppedFile != null) {
           print('Cropped image selected from gallery: ${croppedFile.path}');
           await _processImage(croppedFile.path); // Process the cropped image
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
    final isProcessing = ref.watch(_visionProcessingProvider);

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
      body: Stack(
        children: [
          cameraState.when(
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
          // Loading overlay for vision processing
          if (isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     CircularProgressIndicator(color: Colors.white),
                     SizedBox(height: 16),
                     Text('Processing image...', style: TextStyle(color: Colors.white, fontSize: 16)),
                   ],
                 ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    final isProcessing = ref.watch(_visionProcessingProvider);
    // Disable buttons while processing
    final VoidCallback? takePictureAction = isProcessing ? null : _onTakePictureButtonPressed;
    final VoidCallback? importAction = isProcessing ? null : _onImportFromGalleryPressed;

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
            onPressed: importAction,
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
              onPressed: ref.watch(cameraControllerProvider).isLoading ? null : takePictureAction,
              tooltip: 'Take Picture',
            ),
          ),
          const SizedBox(width: 40), // Placeholder for symmetry
        ],
      ),
    );
  }
} 