import 'package:hive/hive.dart';

part 'inventory_entry.g.dart';

/// Category types for 4th Step inventory entries
/// Each category has different labels but uses the same internal field structure
@HiveType(typeId: 14)
enum InventoryCategory {
  @HiveField(0)
  resentment,  // Default - "I'm resentful at", "The cause", etc.
  
  @HiveField(1)
  fear,        // "I'm fearful of", "Why do I have the fear?", etc.
  
  @HiveField(2)
  harms,       // "Who did I hurt?", "What did I do?", etc.
  
  @HiveField(3)
  sexualHarms; // "Who did I hurt?", "What did I do?", etc. (sexual context)
}

@HiveType(typeId: 0)
class InventoryEntry extends HiveObject {
  @HiveField(0)
  String? resentment;  // Field 1: "I'm resentful at" / "I'm fearful of" / "Who did I hurt?"

  @HiveField(1)
  String? reason;      // Field 2: "The cause" / "Why do I have the fear?" / "What did I do?"

  @HiveField(2)
  String? affect;      // Field 3: "Affects my" (same for all categories)

  @HiveField(3)
  String? part;        // Field 4: "My part" (same for all categories)

  @HiveField(4)
  String? defect;      // Field 5: "Shortcoming(s)" (same for all categories)

  @HiveField(5)
  String? iAmId;       // Links to IAmDefinition by ID

  @HiveField(6)
  InventoryCategory? category;  // Category type (defaults to resentment for backward compatibility)

  InventoryEntry(
    this.resentment,
    this.reason,
    this.affect,
    this.part,
    this.defect, {
    this.iAmId,
    this.category,
  });

  /// Get the effective category (defaults to resentment for backward compatibility)
  InventoryCategory get effectiveCategory => category ?? InventoryCategory.resentment;

  // Safe getters that provide empty strings for null values
  String get safeResentment => resentment ?? '';
  String get safeReason => reason ?? '';
  String get safeAffect => affect ?? '';
  String get safePart => part ?? '';
  String get safeDefect => defect ?? '';
  
  // Convenience getters with new names
  String? get myTake => part;
  set myTake(String? value) => part = value;
  
  String? get shortcomings => defect;
  set shortcomings(String? value) => defect = value;

  // JSON serialization
  Map<String, dynamic> toJson() => {
    'resentment': resentment,
    'reason': reason,
    'affect': affect,
    'part': part,
    'defect': defect,
    if (iAmId != null && iAmId != 'null') 'iAmId': iAmId,
    if (category != null) 'category': category!.name,  // Store as string for JSON compatibility
  };

  factory InventoryEntry.fromJson(Map<String, dynamic> json) {
    // Handle the case where iAmId might be the string "null" instead of null
    final iAmIdValue = json['iAmId'];
    final String? parsedIAmId = (iAmIdValue == null || iAmIdValue == 'null') ? null : iAmIdValue as String?;
    
    // Parse category from string (backward compatible - null means resentment)
    InventoryCategory? parsedCategory;
    if (json['category'] != null) {
      final categoryStr = json['category'] as String;
      parsedCategory = InventoryCategory.values.where((c) => c.name == categoryStr).firstOrNull;
    }
    
    return InventoryEntry(
      json['resentment'] as String?,
      json['reason'] as String?,
      json['affect'] as String?,
      json['part'] as String?,
      json['defect'] as String?,
      iAmId: parsedIAmId,
      category: parsedCategory,
    );
  }
}
