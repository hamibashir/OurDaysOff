import 'dart:typed_data';

class PickedRotaFile {
  final String path;
  final String name;
  final Uint8List? bytes;
  final int sizeInBytes;

  const PickedRotaFile({
    required this.path,
    required this.name,
    this.bytes,
    required this.sizeInBytes,
  });

  /// Check whether the file is a standard image format
  bool get isImage {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.heic');
  }

  /// Check whether the file is a PDF document
  bool get isPdf => name.toLowerCase().endsWith('.pdf');

  /// Formatted file size string (e.g. "1.2 MB" or "450 KB")
  String get displaySize {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
