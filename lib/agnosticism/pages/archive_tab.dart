import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/barrier_power_pair.dart';
import '../services/agnosticism_service.dart';
import '../../shared/localizations.dart';

class ArchiveTab extends StatelessWidget {
  ArchiveTab({super.key});

  final _service = AgnosticismService();

  void _restorePair(BuildContext context, Box<BarrierPowerPair> box, BarrierPowerPair pair) async {
    if (!_service.canAddPair(box)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(context, 'agnosticism_max_pairs_error')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    await _service.restorePair(box, pair.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t(context, 'agnosticism_pair_restored')),
      ),
    );
  }

  void _deletePair(BuildContext context, Box<BarrierPowerPair> box, BarrierPowerPair pair) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(context, 'agnosticism_delete_title')),
        content: Text(t(context, 'agnosticism_delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(t(context, 'delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.deletePair(box, pair.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(context, 'agnosticism_pair_deleted')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<BarrierPowerPair>('agnosticism_pairs');

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<BarrierPowerPair> box, _) {
        final archivedPairs = _service.getArchivedPairs(box);
        final canRestore = _service.canAddPair(box);

        if (archivedPairs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.archive_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  t(context, 'agnosticism_empty_archive'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 32),
          itemCount: archivedPairs.length,
          itemBuilder: (context, index) {
            final pair = archivedPairs[index];
            return _buildArchivedPairCard(context, box, pair, canRestore);
          },
        );
      },
    );
  }

  Widget _buildArchivedPairCard(BuildContext context, Box<BarrierPowerPair> box,
      BarrierPowerPair pair, bool canRestore) {
    final colorScheme = Theme.of(context).colorScheme;
    final archivedDate = pair.archivedAt != null
        ? '${pair.archivedAt!.day}/${pair.archivedAt!.month}/${pair.archivedAt!.year}'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Archived date
            Text(
              '${t(context, 'agnosticism_archived_on')}: $archivedDate',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            
            // Barrier section
            Row(
              children: [
                Icon(
                  Icons.block,
                  size: 16,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  t(context, 'agnosticism_barrier'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              pair.barrier,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            const Divider(height: 24),
            
            // Power section
            Row(
              children: [
                Icon(
                  Icons.bolt,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  t(context, 'agnosticism_power'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              pair.power,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Restore button
                TextButton.icon(
                  onPressed: canRestore 
                      ? () => _restorePair(context, box, pair)
                      : null,
                  icon: const Icon(Icons.restore),
                  label: Text(t(context, 'agnosticism_restore')),
                ),
                const SizedBox(width: 8),
                // Delete button
                IconButton(
                  onPressed: () => _deletePair(context, box, pair),
                  icon: const Icon(Icons.delete_forever),
                  color: colorScheme.error,
                  tooltip: t(context, 'delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
