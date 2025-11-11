import 'package:hive/hive.dart';

part 'inventory_entry.g.dart';

@HiveType(typeId: 0)
class InventoryEntry extends HiveObject {
  @HiveField(0)
  String? resentment;

  @HiveField(1)
  String? reason;

  @HiveField(2)
  String? affect;

  @HiveField(3)
  String? part;

  @HiveField(4)
  String? defect;

  InventoryEntry(
    this.resentment,
    this.reason,
    this.affect,
    this.part,
    this.defect,
  );

  // Safe getters that provide empty strings for null values
  String get safeResentment => resentment ?? '';
  String get safeReason => reason ?? '';
  String get safeAffect => affect ?? '';
  String get safePart => part ?? '';
  String get safeDefect => defect ?? '';
}
