import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/inventory_entry.dart';
import '../localizations.dart';

class ListTab extends StatefulWidget {
  final Box<InventoryEntry> box;
  final void Function(int index) onEdit;
  final void Function(int index)? onDelete;
  final bool isProcessing;

  const ListTab({
    super.key,
    required this.box,
    required this.onEdit,
    this.onDelete,
    this.isProcessing = false,
  });

  @override
  State<ListTab> createState() => _ListTabState();
}

class _ListTabState extends State<ListTab> {
  bool showTable = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(showTable ? Icons.list : Icons.table_chart),
                tooltip: showTable
                    ? t(context, 'switch_list_view')
                    : t(context, 'switch_table_view'),
                onPressed: () => setState(() => showTable = !showTable),
              ),
            ],
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: widget.box.listenable(),
              builder: (context, Box<InventoryEntry> box, _) {
                if (box.isEmpty) {
                  return Center(child: Text(t(context, 'no_entries')));
                }

                final entries = box.values.toList().reversed.toList();

                if (showTable) {
                  final headerColor =
                      theme.colorScheme.primaryContainer.withOpacity(0.8);
                  final rowBaseColor =
                      theme.colorScheme.surfaceContainerHighest.withOpacity(0.25);

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final columnWidth = constraints.maxWidth / 5;

                      return Column(
                        children: [
                          Container(
                            color: headerColor,
                            child: Row(
                              children: [
                                for (final header in [
                                  t(context, 'resentment'),
                                  t(context, 'reason'),
                                  t(context, 'affect'),
                                  t(context, 'part'),
                                  t(context, 'defect'),
                                ])
                                  Container(
                                    width: columnWidth,
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      header,
                                      softWrap: true,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: List.generate(entries.length, (i) {
                                  final e = entries[i];
                                  final rowColor = (i % 2 == 0)
                                      ? rowBaseColor.withOpacity(0.7)
                                      : rowBaseColor.withOpacity(0.4);

                                  return Container(
                                    color: rowColor,
                                    child: Row(
                                      children: [
                                        for (final text in [
                                          e.safeResentment,
                                          e.safeReason,
                                          e.safeAffect,
                                          e.safePart,
                                          e.safeDefect
                                        ])
                                          Container(
                                            width: columnWidth,
                                            padding: const EdgeInsets.all(8),
                                            child: Text(text, softWrap: true),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }

                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    final reversedIndex = box.length - 1 - index;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${t(context, 'resentment')}: ${e.safeResentment}"),
                            Text("${t(context, 'reason')}: ${e.safeReason}"),
                            Text("${t(context, 'affect')}: ${e.safeAffect}"),
                            Text("${t(context, 'part')}: ${e.safePart}"),
                            Text("${t(context, 'defect')}: ${e.safeDefect}"),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  tooltip: t(context, 'edit_entry'),
                                  onPressed: () => widget.onEdit(reversedIndex),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  tooltip: t(context, 'delete_entry'),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text(t(context, 'delete_entry')),
                                        content: Text(t(context, 'delete_confirm')),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(t(context, 'cancel')),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text(
                                              t(context, 'delete'),
                                              style: TextStyle(
                                                  color:
                                                      theme.colorScheme.error),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm ?? false) {
                                      if (reversedIndex >= 0 &&
                                          reversedIndex < box.length) {
                                        await box.deleteAt(reversedIndex);
                                        widget.onDelete?.call(reversedIndex);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  t(context, 'entry_deleted'))),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
