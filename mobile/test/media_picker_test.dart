import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/features/rota_import/models/picked_rota_file.dart';
import 'package:our_days_off/features/rota_import/services/media_picker_service.dart';
import 'package:our_days_off/features/rota_import/views/widgets/image_source_picker_modal.dart';

class MockMediaPickerService extends Fake implements MediaPickerService {
  bool cameraCalled = false;
  bool galleryCalled = false;
  bool documentCalled = false;

  @override
  Future<PickedRotaFile?> pickFromCamera({
    int imageQuality = 85,
    double maxWidth = 2048,
    double maxHeight = 2048,
  }) async {
    cameraCalled = true;
    return const PickedRotaFile(
      path: '/mock/camera_rota.jpg',
      name: 'camera_rota.jpg',
      sizeInBytes: 1024 * 500, // 500 KB
    );
  }

  @override
  Future<PickedRotaFile?> pickFromGallery({
    int imageQuality = 85,
    double maxWidth = 2048,
    double maxHeight = 2048,
  }) async {
    galleryCalled = true;
    return const PickedRotaFile(
      path: '/mock/gallery_rota.png',
      name: 'gallery_rota.png',
      sizeInBytes: 1024 * 1024 * 2, // 2 MB
    );
  }

  @override
  Future<PickedRotaFile?> pickDocument() async {
    documentCalled = true;
    return const PickedRotaFile(
      path: '/mock/schedule.pdf',
      name: 'schedule.pdf',
      sizeInBytes: 1024 * 150, // 150 KB
    );
  }
}

void main() {
  group('PickedRotaFile Model Tests', () {
    test('correctly identifies image extensions', () {
      const fileJpg = PickedRotaFile(
        path: '/tmp/test.jpg',
        name: 'test.jpg',
        sizeInBytes: 2048,
      );
      expect(fileJpg.isImage, isTrue);
      expect(fileJpg.isPdf, isFalse);

      const filePng = PickedRotaFile(
        path: '/tmp/photo.PNG',
        name: 'photo.PNG',
        sizeInBytes: 2048,
      );
      expect(filePng.isImage, isTrue);
    });

    test('correctly identifies PDF files', () {
      const filePdf = PickedRotaFile(
        path: '/tmp/hospital_rota.pdf',
        name: 'hospital_rota.pdf',
        sizeInBytes: 500000,
      );
      expect(filePdf.isPdf, isTrue);
      expect(filePdf.isImage, isFalse);
    });

    test('formats display size into readable units', () {
      const fileBytes = PickedRotaFile(path: '', name: 'a.txt', sizeInBytes: 512);
      expect(fileBytes.displaySize, '512 B');

      const fileKb = PickedRotaFile(path: '', name: 'b.jpg', sizeInBytes: 1024 * 250);
      expect(fileKb.displaySize, '250.0 KB');

      const fileMb = PickedRotaFile(path: '', name: 'c.pdf', sizeInBytes: 1024 * 1024 * 3);
      expect(fileMb.displaySize, '3.0 MB');
    });
  });

  group('ImageSourcePickerModal Widget Tests', () {
    testWidgets('renders all three upload sources and handles selection', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockPicker = MockMediaPickerService();
      PickedRotaFile? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ImageSourcePickerModal.show(
                    context,
                    mediaPicker: mockPicker,
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Import Rota & Shifts'), findsOneWidget);
      expect(find.text('Take Photo of Rota'), findsOneWidget);
      expect(find.text('Choose from Photo Library'), findsOneWidget);
      expect(find.text('Upload PDF Document'), findsOneWidget);

      // Tap on Take Photo
      await tester.tap(find.text('Take Photo of Rota'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(mockPicker.cameraCalled, isTrue);
      expect(result?.name, 'camera_rota.jpg');
      expect(result?.isImage, isTrue);
    });
  });
}
