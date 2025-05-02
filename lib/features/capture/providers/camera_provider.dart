import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to get the list of available cameras
final availableCamerasProvider = FutureProvider<List<CameraDescription>>((ref) async {
  return await availableCameras();
});

// StateNotifier for Camera Controller state
class CameraControllerNotifier extends StateNotifier<AsyncValue<CameraController>> {
  CameraControllerNotifier(this._ref)
      : super(const AsyncLoading()); // Start in loading state

  final Ref _ref;
  CameraController? _controller;

  Future<void> initializeCamera() async {
    state = const AsyncLoading(); // Set loading state
    try {
      final cameras = await _ref.read(availableCamerasProvider.future);
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }
      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false, // Audio not needed for this app
      );

      await _controller!.initialize();
      state = AsyncData(_controller!); // Set data state with controller
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace); // Set error state
    }
  }

  // Expose the controller directly for easier access in the UI
  CameraController? get controller => _controller;

  @override
  void dispose() {
    _controller?.dispose(); // Dispose controller when notifier is disposed
    super.dispose();
  }
}

// Provider for the CameraControllerNotifier
final cameraControllerProvider =
    StateNotifierProvider<CameraControllerNotifier, AsyncValue<CameraController>>((ref) {
  return CameraControllerNotifier(ref);
}); 