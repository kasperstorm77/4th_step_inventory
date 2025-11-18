import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/reflection_entry.dart';
import '../services/reflection_service.dart';
import '../../shared/localizations.dart';

class EveningRitualFormTab extends StatefulWidget {
  final DateTime selectedDate;

  const EveningRitualFormTab({
    super.key,
    required this.selectedDate,
  });

  @override
  State<EveningRitualFormTab> createState() => _EveningRitualFormTabState();
}

class _EveningRitualFormTabState extends State<EveningRitualFormTab> {
  ReflectionEntry? _editingEntry;
  final _detailController = TextEditingController();
  ReflectionType? _selectedType;
  double _thinkingFocusValue = 0.5;

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  void _editEntry(ReflectionEntry entry) {
    setState(() {
      _editingEntry = entry;
      _selectedType = entry.type;
      _detailController.text = entry.safeDetail;
      if (entry.thinkingFocus != null) {
        _thinkingFocusValue = entry.thinkingFocus! / 10.0;
      }
    });
  }

  void _resetForm() {
    setState(() {
      _editingEntry = null;
      _selectedType = null;
      _detailController.clear();
      _thinkingFocusValue = 0.5;
    });
  }

  Future<void> _saveEntry() async {
    if (_selectedType == null) return;

    final entry = ReflectionEntry(
      internalId: _editingEntry?.internalId,
      date: widget.selectedDate,
      type: _selectedType!,
      detail: _detailController.text.isEmpty ? null : _detailController.text,
      thinkingFocus: null,
    );

    await ReflectionService.addReflection(entry);
    _resetForm();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(context, 'reflection_saved')),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _deleteEntry(ReflectionEntry entry) async {
    await ReflectionService.deleteReflection(entry.internalId);
    if (_editingEntry?.internalId == entry.internalId) {
      _resetForm();
    }
  }

  Future<void> _saveThinkingFocus() async {
    final entries = ReflectionService.getReflectionsByDate(widget.selectedDate);
    var thinkingEntry = entries.where((e) => e.thinkingFocus != null).firstOrNull;

    if (thinkingEntry == null) {
      thinkingEntry = ReflectionEntry(
        date: widget.selectedDate,
        type: ReflectionType.godsForgiveness,
        detail: null,
        thinkingFocus: (_thinkingFocusValue * 10).round(),
      );
      await ReflectionService.addReflection(thinkingEntry);
    } else {
      thinkingEntry.thinkingFocus = (_thinkingFocusValue * 10).round();
      await ReflectionService.updateReflection(thinkingEntry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              DateFormat.yMMMMd().format(widget.selectedDate),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        Expanded(
          child: ValueListenableBuilder(
            valueListenable: ReflectionService.getBox().listenable(),
            builder: (context, Box<ReflectionEntry> box, _) {
              final entries = ReflectionService.getReflectionsByDate(widget.selectedDate);
              final regularEntries = entries.where((e) => e.thinkingFocus == null).toList();
              final thinkingEntry = entries.where((e) => e.thinkingFocus != null).firstOrNull;

              if (thinkingEntry != null && _editingEntry == null) {
                _thinkingFocusValue = thinkingEntry.thinkingFocus! / 10.0;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildThinkingSlider(context),

                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_selectedType == null)
                              DropdownButtonFormField<ReflectionType>(
                                value: _selectedType,
                                decoration: InputDecoration(
                                  labelText: t(context, 'select_reflection_type'),
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                ),
                                isExpanded: true,
                                selectedItemBuilder: (BuildContext context) {
                                  return ReflectionType.values.map((type) {
                                    return Container(
                                      alignment: Alignment.centerLeft,
                                      constraints: const BoxConstraints(maxWidth: 280),
                                      child: Text(
                                        t(context, type.labelKey()),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    );
                                  }).toList();
                                },
                                items: ReflectionType.values.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(
                                      t(context, type.labelKey()),
                                      overflow: TextOverflow.visible,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedType = value;
                                  });
                                },
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _detailController,
                                    decoration: InputDecoration(
                                      labelText: t(context, _selectedType!.labelKey()),
                                      border: const OutlineInputBorder(),
                                    ),
                                    maxLines: 3,
                                    autofocus: true,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: Icon(_editingEntry != null ? Icons.save : Icons.add),
                                          onPressed: _saveEntry,
                                          label: Text(
                                            _editingEntry != null
                                                ? t(context, 'save_changes')
                                                : t(context, 'add_reflection'),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: _resetForm,
                                        child: Text(t(context, 'cancel')),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (regularEntries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          t(context, 'no_reflections_hint'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...regularEntries.map((entry) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(t(context, entry.type.labelKey())),
                              subtitle: entry.detail != null && entry.detail!.isNotEmpty
                                  ? Text(
                                      entry.detail!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _editEntry(entry),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _confirmDelete(entry),
                                  ),
                                ],
                              ),
                            ),
                          )),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThinkingSlider(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t(context, 'thinking_focus_question'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    t(context, 'thinking_self'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Slider(
                    value: _thinkingFocusValue,
                    onChanged: (value) {
                      setState(() {
                        _thinkingFocusValue = value;
                      });
                    },
                    onChangeEnd: (value) {
                      _saveThinkingFocus();
                    },
                    divisions: 10,
                    label: _getSliderLabel(_thinkingFocusValue),
                  ),
                ),
                Expanded(
                  child: Text(
                    t(context, 'thinking_others'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            Center(
              child: Text(
                _getSliderLabel(_thinkingFocusValue),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSliderLabel(double value) {
    if (value == 0.0) return t(context, 'slider_completely_self');
    if (value <= 0.2) return t(context, 'slider_mostly_self');
    if (value < 0.5) return t(context, 'slider_leaning_self');
    if (value == 0.5) return t(context, 'slider_balanced');
    if (value < 0.8) return t(context, 'slider_leaning_others');
    if (value < 1.0) return t(context, 'slider_mostly_others');
    return t(context, 'slider_completely_others');
  }

  void _confirmDelete(ReflectionEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(context, 'delete_reflection')),
        content: Text(t(context, 'delete_reflection_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteEntry(entry);
            },
            child: Text(
              t(context, 'delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
