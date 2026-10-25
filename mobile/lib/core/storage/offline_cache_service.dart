import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/circles/models/circle_model.dart';
import '../../features/schedule/models/schedule_entry.dart';

final offlineCacheServiceProvider = Provider<OfflineCacheService>((ref) {
  return OfflineCacheService();
});

class OfflineCacheService {
  static const String _boxName = 'app_offline_cache';
  static const String _scheduleKey = 'cached_schedule_entries';
  static const String _circlesKey = 'cached_circles';

  Box? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }
  }

  Box? get box {
    try {
      if (_box == null || !_box!.isOpen) {
        if (Hive.isBoxOpen(_boxName)) {
          _box = Hive.box(_boxName);
        }
      }
      return _box;
    } catch (_) {
      return null;
    }
  }

  /// Cache user's personal schedule entries locally
  Future<void> saveSchedule(List<ScheduleEntry> entries) async {
    try {
      final jsonList = entries.map((e) => e.toJson()).toList();
      await box?.put(_scheduleKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// Retrieve cached personal schedule entries
  List<ScheduleEntry> getCachedSchedule() {
    try {
      final raw = box?.get(_scheduleKey);
      if (raw is String) {
        final decoded = jsonDecode(raw) as List;
        return decoded
            .map((item) => ScheduleEntry.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Cache user's circles list locally
  Future<void> saveCircles(List<CircleModel> circles) async {
    try {
      final jsonList = circles.map((c) => c.toJson()).toList();
      await box?.put(_circlesKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// Retrieve cached circles
  List<CircleModel> getCachedCircles() {
    try {
      final raw = box?.get(_circlesKey);
      if (raw is String) {
        final decoded = jsonDecode(raw) as List;
        return decoded
            .map((item) => CircleModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Clear offline cached data (e.g. upon user logout)
  Future<void> clearCache() async {
    try {
      await box?.delete(_scheduleKey);
      await box?.delete(_circlesKey);
    } catch (_) {}
  }
}
