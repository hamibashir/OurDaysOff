import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/picked_rota_file.dart';

final mediaPickerServiceProvider = Provider<MediaPickerService>((ref) {
  return MediaPickerService(
    imagePicker: ImagePicker(),
  );
});

class MediaPickerService {
  final ImagePicker _imagePicker;

  MediaPickerService({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  /// Capture a physical rota photo using the device camera
  Future<PickedRotaFile?> pickFromCamera({
    int imageQuality = 85,
    double maxWidth = 2048,
    double maxHeight = 2048,
  }) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (file == null) return null;

      final length = await file.length();
      return PickedRotaFile(
        path: file.path,
        name: file.name,
        sizeInBytes: length,
      );
    } catch (_) {
      return null;
    }
  }

  /// Select a roster photo or screenshot from the photo gallery
  Future<PickedRotaFile?> pickFromGallery({
    int imageQuality = 85,
    double maxWidth = 2048,
    double maxHeight = 2048,
  }) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (file == null) return null;

      final length = await file.length();
      return PickedRotaFile(
        path: file.path,
        name: file.name,
        sizeInBytes: length,
      );
    } catch (_) {
      return null;
    }
  }

  /// Select a PDF roster document using system document picker
  Future<PickedRotaFile?> pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final platformFile = result.files.first;
      final path = platformFile.path;
      if (path == null) return null;

      int size = platformFile.size;
      if (size <= 0) {
        final ioFile = File(path);
        if (await ioFile.exists()) {
          size = await ioFile.length();
        }
      }

      return PickedRotaFile(
        path: path,
        name: platformFile.name,
        bytes: platformFile.bytes,
        sizeInBytes: size,
      );
    } catch (_) {
      return null;
    }
  }
}
