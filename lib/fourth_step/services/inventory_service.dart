import 'package:hive_flutter/hive_flutter.dart';
import '../models/inventory_entry.dart';
import '../../shared/services/all_apps_drive_service.dart';

class InventoryService {
  final Box<InventoryEntry> _box = Hive.box<InventoryEntry>('entries');

  // Get all entries in reverse order (newest first)
  List<InventoryEntry> getAllEntries() {
    return _box.values.toList().reversed.toList();
  }

  // Add new entry
  Future<void> addEntry(InventoryEntry entry) async {
    await _box.add(entry);
    AllAppsDriveService.instance.scheduleUploadFromBox(_box);
  }

  // Update entry at index
  Future<void> updateEntry(int index, InventoryEntry entry) async {
    if (index >= 0 && index < _box.length) {
      await _box.putAt(index, entry);
      AllAppsDriveService.instance.scheduleUploadFromBox(_box);
    }
  }

  // Delete entry at index
  Future<void> deleteEntry(int index) async {
    if (index >= 0 && index < _box.length) {
      await _box.deleteAt(index);
      AllAppsDriveService.instance.scheduleUploadFromBox(_box);
    }
  }

  // Clear all entries
  Future<void> clearAllEntries() async {
    await _box.clear();
    AllAppsDriveService.instance.scheduleUploadFromBox(_box);
  }

  // Get entry at index
  InventoryEntry? getEntryAt(int index) {
    if (index >= 0 && index < _box.length) {
      return _box.getAt(index);
    }
    return null;
  }

  // Get number of entries
  int get entryCount => _box.length;

  // Stream of entry changes
  Stream<BoxEvent> get entriesStream => _box.watch();
}