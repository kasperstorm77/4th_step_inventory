import 'dart:convert';

// Serialize a list of entries for cloud sync. This runs in a background
// isolate when called via compute.
String serializeEntries(List<Map<String, dynamic>> entries) {
  final payload = {
    'schemaVersion': 1,
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
    'entries': entries,
  };

  return const JsonEncoder().convert(payload);
}
