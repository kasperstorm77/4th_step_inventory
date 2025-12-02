import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/reflection_entry.dart';
import '../services/reflection_service.dart';
import '../../shared/localizations.dart';

class EveningRitualListTab extends StatelessWidget {
  final Function(DateTime) onDateSelected;

  const EveningRitualListTab({
    super.key,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ReflectionService.getBox().listenable(),
      builder: (context, Box<ReflectionEntry> box, _) {
        final allEntries = ReflectionService.getAllReflections();
        
        if (allEntries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  t(context, 'no_reflections'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(context, 'no_reflections_hint'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Group by date
        final Map<DateTime, List<ReflectionEntry>> groupedByDate = {};
        for (final entry in allEntries) {
          final dateOnly = DateTime(entry.date.year, entry.date.month, entry.date.day);
          groupedByDate.putIfAbsent(dateOnly, () => []).add(entry);
        }

        final sortedDates = groupedByDate.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(8, 8, 8, MediaQuery.of(context).padding.bottom + 32),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final entriesForDate = groupedByDate[date]!;
            return _buildDateCard(context, date, entriesForDate);
          },
        );
      },
    );
  }

  Widget _buildDateCard(BuildContext context, DateTime date, List<ReflectionEntry> entries) {
    final regularEntries = entries.where((e) => e.thinkingFocus == null).toList();
    final thinkingEntry = entries.where((e) => e.thinkingFocus != null).firstOrNull;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => onDateSelected(date),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Date indicator
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat.MMM().format(date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat.d().format(date),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat.y().format(date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Content summary
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              DateFormat.EEEE().format(date),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${regularEntries.length}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (regularEntries.isNotEmpty) ...[
                          ...regularEntries.take(2).map((entry) => Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${t(context, entry.type.labelKey())}${entry.detail != null && entry.detail!.isNotEmpty ? ': ${entry.detail}' : ''}',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                          if (regularEntries.length > 2)
                            Text(
                              '+${regularEntries.length - 2} more',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                        ],
                        if (thinkingEntry != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${t(context, 'thinking_focus_question')} ${thinkingEntry.thinkingFocus}/10',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            // Delete button in top right corner
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _confirmDeleteDay(context, date, entries),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.delete,
                      size: 16,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDay(BuildContext context, DateTime date, List<ReflectionEntry> entries) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(context, 'delete_day')),
        content: Text(t(context, 'confirm_delete_day')
            .replaceAll('{date}', DateFormat.yMMMMd().format(date))
            .replaceAll('{count}', '${entries.length}')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t(context, 'cancel')),
          ),
          TextButton(
            onPressed: () async {
              // Delete all entries for this day
              for (final entry in entries) {
                await ReflectionService.deleteReflection(entry.internalId);
              }
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t(context, 'day_deleted')),
                  duration: const Duration(seconds: 2),
                ),
              );
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
