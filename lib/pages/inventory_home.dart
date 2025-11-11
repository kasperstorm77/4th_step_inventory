import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/inventory_entry.dart';
import 'form_tab.dart';
import 'list_tab.dart';
import 'settings_tab.dart';
import '../localizations.dart';
import '../services/drive_service.dart';
 

class InventoryHome extends StatefulWidget {
  final Locale? currentLocale;
  final void Function(Locale)? setLocale;

  const InventoryHome({super.key, this.currentLocale, this.setLocale});

  @override
  State<InventoryHome> createState() => _InventoryHomeState();
}

class _InventoryHomeState extends State<InventoryHome>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Box<InventoryEntry> box = Hive.box<InventoryEntry>('entries');

  // Text controllers
  final _resentmentController = TextEditingController();
  final _reasonController = TextEditingController();
  final _affectController = TextEditingController();
  final _partController = TextEditingController();
  final _defectController = TextEditingController();

  int? editingIndex;
  bool get isEditing => editingIndex != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    DriveService.instance.loadSyncState();
    // Note: No longer listening to all upload events to avoid showing notifications
    // for background sync. User-initiated actions in Settings show their own notifications.
  }

  @override
  void dispose() {
    // No upload subscription to cancel anymore
    _resentmentController.dispose();
    _reasonController.dispose();
    _affectController.dispose();
    _partController.dispose();
    _defectController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _editEntry(int index) {
    if (index < 0 || index >= box.length) return;

    final entry = box.getAt(index);
    if (entry == null) return;

    _resentmentController.text = entry.safeResentment;
    _reasonController.text = entry.safeReason;
    _affectController.text = entry.safeAffect;
    _partController.text = entry.safePart;
    _defectController.text = entry.safeDefect;

    setState(() => editingIndex = index);
    _tabController.index = 0;
  }

  void _resetForm() {
    editingIndex = null;
    _resentmentController.clear();
    _reasonController.clear();
    _affectController.clear();
    _partController.clear();
    _defectController.clear();
    _tabController.index = 1; // Return to list tab
    setState(() {});
  }

  Future<void> _saveEntry() async {
    final entry = InventoryEntry(
      _resentmentController.text,
      _reasonController.text,
      _affectController.text,
      _partController.text,
      _defectController.text,
    );
    if (isEditing && editingIndex != null && editingIndex! < box.length) {
      await box.putAt(editingIndex!, entry);
    } else {
      await box.add(entry);
    }

  // Schedule a debounced upload via DriveService so rapid consecutive
  // changes are coalesced and serialization runs off the main thread.
  DriveService.instance.scheduleUploadFromBox(box);

    _resetForm();
  }

  Future<void> _deleteEntry(int index) async {
    if (index < 0 || index >= box.length) return;

  await box.deleteAt(index);
  DriveService.instance.scheduleUploadFromBox(box);
  }

  // Note: explicit, immediate sync calls are now handled through
  // DriveService.scheduleUploadFromBox(box) which debounces and offloads
  // serialization. Keep this space in case we need a manual immediate sync
  // API in the future.

  void _changeLanguage(String langCode) {
    widget.setLocale?.call(Locale(langCode));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'app_title')),
        actions: [
          PopupMenuButton<String>(
            onSelected: _changeLanguage,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'da', child: Text('Dansk')),
            ],
            icon: const Icon(Icons.language),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t(context, 'form_title')),
            Tab(text: t(context, 'entries_title')),
            Tab(text: t(context, 'settings_title')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FormTab(
            box: box,
            resentmentController: _resentmentController,
            reasonController: _reasonController,
            affectController: _affectController,
            partController: _partController,
            defectController: _defectController,
            editingIndex: editingIndex,
            onSave: _saveEntry,
            onCancel: _resetForm,
          ),
          ListTab(
            box: box,
            onEdit: _editEntry,
            onDelete: _deleteEntry,
          ),
          SettingsTab(box: box),
        ],
      ),
    );
  }
}
