import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/haptic_feedback.dart';
import '../models/plan_model.dart';

String _formatIcsDate(DateTime? dt) {
  if (dt == null) return '';
  final u = dt.toUtc();
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${u.year}${pad(u.month)}${pad(u.day)}T${pad(u.hour)}${pad(u.minute)}${pad(u.second)}Z';
}

/// Escapes text strings for RFC 5545 format
String escapeIcsText(String text) {
  return text
      .replaceAll(r'\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', '');
}

/// Generates RFC 5545 compliant .ics string for calendar export
String generateIcsContent(PlanModel plan, {String? locationName}) {
  final now = DateTime.now().toUtc();
  final dtStamp = _formatIcsDate(now);
  final dtStart = _formatIcsDate(plan.startAt ?? now);
  final dtEnd = _formatIcsDate(
    plan.endAt ?? plan.startAt ?? now.add(const Duration(hours: 2)),
  );
  final uid = 'plan-${plan.id}-${now.millisecondsSinceEpoch}@ourdaysoff.com';
  final venue = locationName ??
      (plan.hasLocation ? plan.primaryLocation!.name : 'TBD');

  final lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Our Days Off//Schedule Coordination Platform//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'BEGIN:VEVENT',
    'UID:$uid',
    'DTSTAMP:$dtStamp',
    'DTSTART:$dtStart',
    'DTEND:$dtEnd',
    'SUMMARY:${escapeIcsText(plan.title)}',
    'DESCRIPTION:${escapeIcsText(plan.description ?? "Meetup coordinated via Our Days Off")}',
    'LOCATION:${escapeIcsText(venue)}',
    'STATUS:CONFIRMED',
    'END:VEVENT',
    'END:VCALENDAR',
  ];

  return lines.join('\r\n');
}

/// Exports the plan to native calendar or file share sheet
Future<void> exportPlanIcs(PlanModel plan, {String? locationName}) async {
  AppHaptics.medium();
  final content = generateIcsContent(plan, locationName: locationName);
  final tempDir = await getTemporaryDirectory();
  final safeTitle =
      plan.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
  final file = File('${tempDir.path}/$safeTitle.ics');
  await file.writeAsString(content);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/calendar')],
    subject: plan.title,
    text: 'Calendar invite for ${plan.title}',
  );
}
