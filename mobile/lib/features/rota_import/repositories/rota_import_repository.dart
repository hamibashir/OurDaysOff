import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/import_preview_entry.dart';
import '../models/picked_rota_file.dart';

class RotaImportRepository {
  final ApiClient apiClient;

  static const String externalPromptTemplate = '''Please read the provided work rota schedule and extract all shift entries. Output the result ONLY as a valid JSON object matching this exact schema:

{
  "entries": [
    {
      "date": "YYYY-MM-DD",
      "shift_label": "e.g. Early Shift, Night, Off",
      "start_time": "HH:MM",
      "end_time": "HH:MM",
      "entry_type": "work",
      "is_overnight": false
    }
  ]
}

Rules:
- `entry_type` must be one of: "work", "leave", "off", "personal", "other".
- `is_overnight` must be true if the shift ends on the following calendar day.
- Do not include any markdown formatting, explanations, or text outside the JSON object. Just the raw JSON.''';

  RotaImportRepository({required this.apiClient});

  /// Uploads a rota image or PDF document to `/imports/rota` for AI parsing.
  Future<List<ImportPreviewEntry>> uploadAndExtractRota(
    PickedRotaFile file, {
    ProgressCallback? onSendProgress,
  }) async {
    final multipartFile = await MultipartFile.fromFile(
      file.path,
      filename: file.name,
    );

    final formData = FormData.fromMap({
      'file': multipartFile,
    });

    final response = await apiClient.upload(
      '/imports/rota',
      formData: formData,
      onSendProgress: onSendProgress,
    );

    final data = response['data'] as Map<String, dynamic>?;
    final previewList = data?['preview_entries'] as List<dynamic>? ?? [];

    return previewList
        .map((entry) => ImportPreviewEntry.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  /// Parses and validates JSON produced by external AI models (ChatGPT, Claude, Gemini, etc.)
  List<ImportPreviewEntry> parseExternalAiJson(String rawText) {
    if (rawText.trim().isEmpty) {
      throw const FormatException('Please paste the AI JSON response.');
    }

    String cleanText = rawText.trim();
    // Remove markdown code blocks like ```json ... ``` or ``` ... ```
    if (cleanText.startsWith('```json')) {
      cleanText = cleanText.substring(7);
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
    } else if (cleanText.startsWith('```')) {
      cleanText = cleanText.substring(3);
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
    }
    cleanText = cleanText.trim();

    dynamic decoded;
    try {
      decoded = jsonDecode(cleanText);
    } catch (e) {
      throw FormatException('Invalid JSON format: ${e.toString()}');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON root object with an "entries" array.');
    }

    final entriesRaw = decoded['entries'];
    if (entriesRaw is! List || entriesRaw.isEmpty) {
      throw const FormatException('Missing or empty "entries" array in the JSON response.');
    }

    const validTypes = ['work', 'leave', 'off', 'personal', 'other'];
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    final timeRegex = RegExp(r'^\d{2}:\d{2}$');

    final result = <ImportPreviewEntry>[];

    for (int i = 0; i < entriesRaw.length; i++) {
      final item = entriesRaw[i];
      if (item is! Map<String, dynamic>) {
        throw FormatException('Entry ${i + 1} is not a valid JSON object.');
      }

      final date = item['date']?.toString() ?? '';
      if (!dateRegex.hasMatch(date)) {
        throw FormatException('Entry ${i + 1} has an invalid date format ("$date"). Expected YYYY-MM-DD.');
      }

      final startTime = item['start_time']?.toString() ?? '';
      if (!timeRegex.hasMatch(startTime)) {
        throw FormatException('Entry ${i + 1} has an invalid start_time ("$startTime"). Expected HH:MM.');
      }

      final endTime = item['end_time']?.toString() ?? '';
      if (!timeRegex.hasMatch(endTime)) {
        throw FormatException('Entry ${i + 1} has an invalid end_time ("$endTime"). Expected HH:MM.');
      }

      final rawType = item['entry_type']?.toString().toLowerCase() ?? 'work';
      final entryType = validTypes.contains(rawType) ? rawType : 'work';

      result.add(ImportPreviewEntry.fromJson({
        ...item,
        'entry_type': entryType,
      }));
    }

    return result;
  }

  /// Checks if the current user has an active premium subscription
  Future<bool> checkPremiumStatus() async {
    final response = await apiClient.get('/subscription/status');
    return response['is_premium'] == true;
  }

  /// Redeems a coupon promo code to grant VIP access
  Future<bool> redeemCoupon(String couponCode) async {
    final response = await apiClient.post(
      '/subscription/redeem',
      data: {'coupon_code': couponCode.trim()},
    );
    return response['is_premium'] == true;
  }

  /// Confirms and persists extracted preview shifts to the database via /imports/confirm
  Future<List<dynamic>> confirmBatchImport(List<ImportPreviewEntry> entries) async {
    final payload = {
      'entries': entries.map((e) => e.toJson()).toList(),
    };

    final response = await apiClient.post(
      '/imports/confirm',
      data: payload,
    );

    return response['data'] as List<dynamic>? ?? [];
  }
}

final rotaImportRepositoryProvider = Provider<RotaImportRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RotaImportRepository(apiClient: apiClient);
});
