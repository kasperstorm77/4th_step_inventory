import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/gratitude_entry.dart';
import '../services/gratitude_service.dart';
import '../../shared/localizations.dart';

class GratitudeTodayTab extends StatefulWidget {
  const GratitudeTodayTab({super.key});

  @override
  State<GratitudeTodayTab> createState() => _GratitudeTodayTabState();
}

class _GratitudeTodayTabState extends State<GratitudeTodayTab> {
  final GratitudeService _service = GratitudeService();
  final TextEditingController _towardsController = TextEditingController();
  final TextEditingController _forController = TextEditingController();
  GratitudeEntry? _editingEntry;

  @override
  void dispose() {
    _towardsController.dispose();
    _forController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_towardsController.text.trim().isEmpty || _forController.text.trim().isEmpty) return;

    final box = Hive.box<GratitudeEntry>('gratitude_box');
    
    if (_editingEntry != null) {
      // Update existing entry
      final index = box.values.toList().indexOf(_editingEntry!);
      if (index >= 0) {
        final updatedEntry = GratitudeEntry(
          date: _editingEntry!.date,
          gratitudeTowards: _towardsController.text.trim(),
          createdAt: _editingEntry!.createdAt,
          gratefulFor: _forController.text.trim(),
        );
        await _service.updateEntry(box, index, updatedEntry);
      }
    } else {
      // Create new entry
      final entry = GratitudeEntry(
        date: DateTime.now(),
        gratitudeTowards: _towardsController.text.trim(),
        createdAt: DateTime.now(),
        gratefulFor: _forController.text.trim(),
      );
      await _service.addEntry(box, entry);
    }

    _towardsController.clear();
    _forController.clear();
    setState(() {
      _editingEntry = null;
    });
  }

  void _editEntry(GratitudeEntry entry) {
    if (!entry.canEdit) return;
    
    setState(() {
      _editingEntry = entry;
      _towardsController.text = entry.gratitudeTowards;
      _forController.text = entry.gratefulFor;
    });
  }

  Future<void> _deleteEntry(GratitudeEntry entry) async {
    if (!entry.canDelete) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(context, 'gratitude_delete_title')),
        content: Text(t(context, 'gratitude_delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(t(context, 'delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final box = Hive.box<GratitudeEntry>('gratitude_box');
      final index = box.values.toList().indexOf(entry);
      if (index >= 0) {
        await _service.deleteEntry(box, index);
        if (_editingEntry == entry) {
          setState(() {
            _editingEntry = null;
            _towardsController.clear();
            _forController.clear();
          });
        }
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _editingEntry = null;
      _towardsController.clear();
      _forController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    
    return Column(
      children: [
        // Date header
        Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(DateFormat.yMMMMd().format(today)),
            subtitle: Text(t(context, 'gratitude_today_subtitle')),
          ),
        ),

        // Input form
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Text(
                  _editingEntry != null
                      ? t(context, 'gratitude_edit_entry')
                      : t(context, 'gratitude_add_entry'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _towardsController,
                  decoration: InputDecoration(
                    labelText: t(context, 'gratitude_towards_label'),
                    hintText: t(context, 'gratitude_towards_hint'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _forController,
                  decoration: InputDecoration(
                    labelText: t(context, 'gratitude_for_label'),
                    hintText: t(context, 'gratitude_for_hint'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _saveEntry(),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_editingEntry != null)
                      TextButton(
                        onPressed: _cancelEdit,
                        child: Text(t(context, 'cancel')),
                      ),
                    ElevatedButton(
                      onPressed: _saveEntry,
                      child: Text(
                        _editingEntry != null
                            ? t(context, 'update')
                            : t(context, 'add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

        const SizedBox(height: 8),

        // Today's entries list
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: Hive.box<GratitudeEntry>('gratitude_box').listenable(),
            builder: (context, Box<GratitudeEntry> box, _) {
              final entries = _service.getEntriesForDate(box, today);

              if (entries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t(context, 'gratitude_no_entries_today'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.favorite, color: Colors.pink),
                      title: Text(entry.gratitudeTowards),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (entry.gratefulFor.isNotEmpty)
                            Text(
                              entry.gratefulFor,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.jm().format(entry.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteEntry(entry),
                        color: Colors.red,
                      ),
                      onTap: () => _editEntry(entry),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
