import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math' as math;
import '../models/barrier_power_pair.dart';
import '../services/agnosticism_service.dart';
import '../../shared/localizations.dart';
import 'pair_form_page.dart';

class PaperTab extends StatefulWidget {
  const PaperTab({super.key});

  @override
  State<PaperTab> createState() => _PaperTabState();
}

class _PaperTabState extends State<PaperTab> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showingFront = true;
  final _service = AgnosticismService();

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipPaper() {
    if (_showingFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _showingFront = !_showingFront;
    });
  }

  void _openAddForm(Box<BarrierPowerPair> box) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PairFormPage(box: box),
      ),
    );
  }

  void _openEditForm(Box<BarrierPowerPair> box, BarrierPowerPair pair) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PairFormPage(box: box, editingPair: pair),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<BarrierPowerPair>('agnosticism_pairs');

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<BarrierPowerPair> box, _) {
        final activePairs = _service.getActivePairs(box);
        final canAdd = _service.canAddPair(box);

        return Column(
          children: [
            // Paper title showing which side
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _showingFront 
                    ? t(context, 'agnosticism_barriers_title')
                    : t(context, 'agnosticism_powers_title'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // The flippable paper
            Expanded(
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final angle = _flipAnimation.value * math.pi;
                  final isFrontVisible = angle < math.pi / 2;
                  
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // perspective
                      ..rotateY(angle),
                    child: isFrontVisible
                        ? _buildPaperSide(context, box, activePairs, true)
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _buildPaperSide(context, box, activePairs, false),
                          ),
                  );
                },
              ),
            ),

            // Flip button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton.icon(
                onPressed: activePairs.isNotEmpty ? _flipPaper : null,
                icon: Icon(_showingFront ? Icons.flip_to_back : Icons.flip_to_front),
                label: Text(t(context, 'agnosticism_flip')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ),

            // Add button (only when less than 5 pairs)
            if (canAdd)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: () => _openAddForm(box),
                  icon: const Icon(Icons.add),
                  label: Text(t(context, 'agnosticism_add_pair')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPaperSide(BuildContext context, Box<BarrierPowerPair> box, 
      List<BarrierPowerPair> pairs, bool isFront) {
    if (pairs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              t(context, 'agnosticism_empty_paper'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 32),
      itemCount: pairs.length,
      itemBuilder: (context, index) {
        final pair = pairs[index];
        return _buildPairBox(context, box, pair, isFront);
      },
    );
  }

  Widget _buildPairBox(BuildContext context, Box<BarrierPowerPair> box, 
      BarrierPowerPair pair, bool isFront) {
    final text = isFront ? pair.barrier : pair.power;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isFront 
            ? colorScheme.errorContainer.withValues(alpha: 0.3)
            : colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border.all(
          color: isFront 
              ? colorScheme.error.withValues(alpha: 0.5)
              : colorScheme.primary.withValues(alpha: 0.5),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          tooltip: t(context, 'edit'),
          onPressed: () => _openEditForm(box, pair),
        ),
      ),
    );
  }
}
