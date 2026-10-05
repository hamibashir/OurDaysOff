import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/core/network/api_client.dart';
import 'package:our_days_off/core/storage/secure_storage_service.dart';
import 'package:our_days_off/features/rota_import/models/import_preview_entry.dart';
import 'package:our_days_off/features/rota_import/models/picked_rota_file.dart';
import 'package:our_days_off/features/rota_import/providers/rota_import_notifier.dart';
import 'package:our_days_off/features/rota_import/providers/rota_import_state.dart';
import 'package:our_days_off/features/rota_import/repositories/rota_import_repository.dart';
import 'package:our_days_off/features/rota_import/services/media_picker_service.dart';
import 'package:our_days_off/features/rota_import/views/rota_import_screen.dart';
import 'package:our_days_off/features/rota_import/views/widgets/edit_preview_entry_sheet.dart';
import 'package:our_days_off/features/schedule/data/schedule_repository.dart';
import 'package:our_days_off/features/schedule/data/shift_template_repository.dart';
import 'package:our_days_off/features/schedule/models/availability_block.dart';
import 'package:our_days_off/features/schedule/models/schedule_entry.dart';
import 'package:our_days_off/features/schedule/models/shift_template.dart';

class MockSecureStorage extends Fake implements SecureStorageService {
  @override
  Future<String?> getAuthToken() async => 'fake_token';
}

class FakeApiClient extends ApiClient {
  dynamic nextGetResponse;
  dynamic nextPostResponse;
  dynamic nextUploadResponse;

  String? lastGetPath;
  String? lastPostPath;
  String? lastUploadPath;
  dynamic lastPostData;

  FakeApiClient() : super(storage: MockSecureStorage());

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastGetPath = path;
    return nextGetResponse;
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    return nextPostResponse;
  }

  @override
  Future<dynamic> upload(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onSendProgress,
  }) async {
    lastUploadPath = path;
    return nextUploadResponse;
  }
}

class MockMediaPickerService extends Fake implements MediaPickerService {
  @override
  Future<PickedRotaFile?> pickFromCamera({
    int imageQuality = 85,
    double maxWidth = 2048,
    double maxHeight = 2048,
  }) async {
    return const PickedRotaFile(
      path: '/test/camera.jpg',
      name: 'camera.jpg',
      sizeInBytes: 1024 * 50,
    );
  }
}

class MockScheduleRepository extends Fake implements ScheduleRepository {
  bool getSchedulesCalled = false;

  @override
  Future<List<ScheduleEntry>> getSchedules({DateTime? startDate, DateTime? endDate}) async {
    getSchedulesCalled = true;
    return [];
  }

  @override
  Future<List<AvailabilityOverride>> getOverrides({DateTime? startDate, DateTime? endDate}) async => [];
}

class MockShiftTemplateRepository extends Fake implements ShiftTemplateRepository {
  @override
  Future<List<ShiftTemplate>> getTemplates() async => [];
}

void main() {
  late FakeApiClient fakeApiClient;
  late RotaImportRepository repository;

  setUp(() {
    fakeApiClient = FakeApiClient();
    repository = RotaImportRepository(apiClient: fakeApiClient);
  });

  group('ImportPreviewEntry Model Tests', () {
    test('parses complete JSON correctly', () {
      final json = {
        'date': '2026-10-15',
        'shift_label': 'Night Shift',
        'start_time': '22:00',
        'end_time': '06:00',
        'entry_type': 'work',
        'is_overnight': true,
      };

      final entry = ImportPreviewEntry.fromJson(json);
      expect(entry.date, '2026-10-15');
      expect(entry.shiftLabel, 'Night Shift');
      expect(entry.startTime, '22:00');
      expect(entry.endTime, '06:00');
      expect(entry.entryType, 'work');
      expect(entry.isOvernight, isTrue);
      expect(entry.isDayOff, isFalse);
    });

    test('auto-detects overnight when end_time < start_time and is_overnight is omitted', () {
      final json = {
        'date': '2026-10-16',
        'shift_label': 'Graveyard',
        'start_time': '23:00',
        'end_time': '07:00',
      };

      final entry = ImportPreviewEntry.fromJson(json);
      expect(entry.isOvernight, isTrue);
    });

    test('correctly identifies day off entry_type', () {
      final json = {
        'date': '2026-10-17',
        'label': 'Day Off',
        'start_time': '00:00',
        'end_time': '23:59',
        'entry_type': 'off',
      };

      final entry = ImportPreviewEntry.fromJson(json);
      expect(entry.isDayOff, isTrue);
      expect(entry.shiftLabel, 'Day Off');
    });

    test('copyWith updates specified fields', () {
      const entry = ImportPreviewEntry(
        date: '2026-10-18',
        shiftLabel: 'Early',
        label: 'Early',
        startTime: '07:00',
        endTime: '15:00',
      );

      final updated = entry.copyWith(shiftLabel: 'Late Shift', startTime: '15:00', endTime: '23:00');
      expect(updated.shiftLabel, 'Late Shift');
      expect(updated.startTime, '15:00');
      expect(updated.endTime, '23:00');
      expect(updated.date, '2026-10-18');
    });
  });

  group('RotaImportRepository Tests', () {
    test('checkPremiumStatus returns true when premium', () async {
      fakeApiClient.nextGetResponse = {'is_premium': true};

      final isPrem = await repository.checkPremiumStatus();
      expect(isPrem, isTrue);
      expect(fakeApiClient.lastGetPath, '/subscription/status');
    });

    test('redeemCoupon calls endpoint with coupon code', () async {
      fakeApiClient.nextPostResponse = {'is_premium': true};

      final success = await repository.redeemCoupon('VIPTEST');
      expect(success, isTrue);
      expect(fakeApiClient.lastPostPath, '/subscription/redeem');
      expect(fakeApiClient.lastPostData, {'coupon_code': 'VIPTEST'});
    });

    test('confirmBatchImport posts entries to /imports/confirm', () async {
      fakeApiClient.nextPostResponse = {
        'message': 'Success',
        'data': [
          {'id': 1, 'date': '2026-10-20', 'label': 'Shift'}
        ],
      };

      const entry = ImportPreviewEntry(
        date: '2026-10-20',
        shiftLabel: 'Shift',
        label: 'Shift',
        startTime: '08:00',
        endTime: '16:00',
      );

      final result = await repository.confirmBatchImport([entry]);
      expect(result.length, 1);
      expect(fakeApiClient.lastPostPath, '/imports/confirm');
      expect(fakeApiClient.lastPostData['entries'], isA<List>());
    });

    test('parseExternalAiJson parses standard JSON with markdown fences', () {
      const rawWithFences = '''```json
{
  "entries": [
    {
      "date": "2026-10-20",
      "shift_label": "Morning Shift",
      "start_time": "08:00",
      "end_time": "16:00",
      "entry_type": "work",
      "is_overnight": false
    }
  ]
}
```''';

      final entries = repository.parseExternalAiJson(rawWithFences);
      expect(entries.length, 1);
      expect(entries.first.date, '2026-10-20');
      expect(entries.first.shiftLabel, 'Morning Shift');
    });

    test('parseExternalAiJson throws FormatException on invalid date format', () {
      const invalidDateJson = '''{
  "entries": [
    {
      "date": "20-10-2026",
      "shift_label": "Shift",
      "start_time": "08:00",
      "end_time": "16:00"
    }
  ]
}''';

      expect(
        () => repository.parseExternalAiJson(invalidDateJson),
        throwsA(isA<FormatException>()),
      );
    });

    test('parseExternalAiJson throws FormatException on invalid time format', () {
      const invalidTimeJson = '''{
  "entries": [
    {
      "date": "2026-10-20",
      "shift_label": "Shift",
      "start_time": "8 AM",
      "end_time": "4 PM"
    }
  ]
}''';

      expect(
        () => repository.parseExternalAiJson(invalidTimeJson),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('RotaImportNotifier State Tests', () {
    test('setSelectedFile and clear updates state', () {
      final notifier = RotaImportNotifier(repository);
      const file = PickedRotaFile(path: '/mock/file.png', name: 'file.png', sizeInBytes: 100);

      notifier.setSelectedFile(file);
      expect(notifier.state.selectedFile, file);

      notifier.setSelectedFile(null);
      expect(notifier.state.selectedFile, isNull);
    });

    test('parseExternalJson sets extracted status and entries', () {
      final notifier = RotaImportNotifier(repository);
      const json = '''{
  "entries": [
    {
      "date": "2026-10-22",
      "shift_label": "Day Shift",
      "start_time": "09:00",
      "end_time": "17:00",
      "entry_type": "work"
    }
  ]
}''';

      notifier.parseExternalJson(json);
      expect(notifier.state.status, RotaImportStatus.extracted);
      expect(notifier.state.previewEntries.length, 1);
      expect(notifier.state.previewEntries.first.shiftLabel, 'Day Shift');
    });

    test('addManualEntry and updatePreviewEntry modify entry list', () {
      final notifier = RotaImportNotifier(repository);
      const entry1 = ImportPreviewEntry(
        date: '2026-10-23',
        shiftLabel: 'Early',
        label: 'Early',
        startTime: '07:00',
        endTime: '15:00',
      );

      notifier.addManualEntry(entry1);
      expect(notifier.state.previewEntries.length, 1);

      final updated = entry1.copyWith(shiftLabel: 'Super Early');
      notifier.updatePreviewEntry(0, updated);
      expect(notifier.state.previewEntries.first.shiftLabel, 'Super Early');
    });

    test('confirmImport updates state to confirmed with count', () async {
      final notifier = RotaImportNotifier(repository);
      fakeApiClient.nextPostResponse = {
        'message': 'Saved',
        'data': [],
      };

      const entry = ImportPreviewEntry(
        date: '2026-10-24',
        shiftLabel: 'Duty',
        label: 'Duty',
        startTime: '10:00',
        endTime: '18:00',
      );
      notifier.addManualEntry(entry);

      final success = await notifier.confirmImport();
      expect(success, isTrue);
      expect(notifier.state.isConfirmed, isTrue);
      expect(notifier.state.confirmedCount, 1);
    });

    test('removePreviewEntry removes entry and adjusts status if empty', () {
      final notifier = RotaImportNotifier(repository);
      const json = '''{
  "entries": [
    {
      "date": "2026-10-22",
      "shift_label": "Day Shift",
      "start_time": "09:00",
      "end_time": "17:00"
    }
  ]
}''';

      notifier.parseExternalJson(json);
      expect(notifier.state.previewEntries.length, 1);

      notifier.removePreviewEntry(0);
      expect(notifier.state.previewEntries.isEmpty, isTrue);
      expect(notifier.state.status, RotaImportStatus.idle);
    });
  });

  group('EditPreviewEntrySheet Widget Tests', () {
    testWidgets('allows editing shift name and returns updated model on save', (WidgetTester tester) async {
      ImportPreviewEntry? savedResult;

      const initial = ImportPreviewEntry(
        date: '2026-10-28',
        shiftLabel: 'Original Shift',
        label: 'Original Shift',
        startTime: '08:00',
        endTime: '16:00',
        entryType: 'work',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  savedResult = await EditPreviewEntrySheet.show(
                    context,
                    initialEntry: initial,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Extracted Shift'), findsOneWidget);
      expect(find.text('Original Shift'), findsOneWidget);

      // Edit shift name
      final labelFinder = find.widgetWithText(TextField, 'Original Shift');
      await tester.enterText(labelFinder, 'ICU Day Shift');
      await tester.pumpAndSettle();

      // Tap Save Changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(savedResult, isNotNull);
      expect(savedResult!.shiftLabel, 'ICU Day Shift');
    });
  });

  group('RotaImportScreen Widget Tests', () {
    testWidgets('renders tabs, switches to external AI, parses JSON, and confirms import', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeApiClient.nextGetResponse = {'is_premium': true};
      fakeApiClient.nextPostResponse = {
        'message': 'Success',
        'data': [],
      };

      final mockScheduleRepo = MockScheduleRepository();
      final mockTemplateRepo = MockShiftTemplateRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeApiClient),
            mediaPickerServiceProvider.overrideWithValue(MockMediaPickerService()),
            scheduleRepositoryProvider.overrideWithValue(mockScheduleRepo),
            shiftTemplateRepositoryProvider.overrideWithValue(mockTemplateRepo),
          ],
          child: const MaterialApp(
            home: RotaImportScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title & tabs
      expect(find.text('Import Rota & Shifts'), findsOneWidget);
      expect(find.text('AI Vision Scanner'), findsOneWidget);
      expect(find.text('Use Any AI Tool'), findsOneWidget);

      // Switch to "Use Any AI Tool" tab
      await tester.tap(find.text('Use Any AI Tool'));
      await tester.pumpAndSettle();

      expect(find.text('Step 1: Copy AI Prompt'), findsOneWidget);
      expect(find.text('Step 2: Paste AI JSON Output'), findsOneWidget);

      // Enter valid JSON in TextField
      const json = '''{
  "entries": [
    {
      "date": "2026-10-25",
      "shift_label": "Early Flight",
      "start_time": "06:00",
      "end_time": "14:00",
      "entry_type": "work"
    }
  ]
}''';

      await tester.enterText(find.byType(TextField).last, json);
      await tester.pumpAndSettle();

      // Tap Parse & Preview Shifts
      await tester.tap(find.text('Parse & Preview Shifts'));
      await tester.pumpAndSettle();

      // Verify preview section appears
      expect(find.text('1 Shifts Extracted'), findsOneWidget);
      expect(find.text('Early Flight'), findsOneWidget);
      expect(find.text('2026-10-25'), findsOneWidget);
      expect(find.text('Confirm & Import to Calendar'), findsOneWidget);

      // Tap Confirm & Import to Calendar
      await tester.tap(find.text('Confirm & Import to Calendar'));
      await tester.pumpAndSettle();

      // Verify success dialog
      expect(find.text('Import Successful!'), findsOneWidget);
      expect(find.text('View on Calendar'), findsOneWidget);
    });
  });
}
