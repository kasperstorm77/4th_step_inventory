import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/inventory_entry.dart';
import '../localizations.dart';

class FormTab extends StatelessWidget {
  final Box<InventoryEntry> box;
  final TextEditingController resentmentController;
  final TextEditingController reasonController;
  final TextEditingController affectController;
  final TextEditingController partController;
  final TextEditingController defectController;
  final int? editingIndex;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  const FormTab({
    super.key,
    required this.box,
    required this.resentmentController,
    required this.reasonController,
    required this.affectController,
    required this.partController,
    required this.defectController,
    this.editingIndex,
    this.onSave,
    this.onCancel,
  });

  bool get isEditing => editingIndex != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(context, resentmentController, 'resentment'),
            _buildTextField(context, reasonController, 'reason'),
            _buildTextField(context, affectController, 'affect'),
            _buildTextField(context, partController, 'part'),
            _buildTextField(context, defectController, 'defect'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(isEditing ? Icons.save : Icons.add),
              onPressed: onSave,
              label: Text(
                isEditing ? t(context, 'save_changes') : t(context, 'add_entry'),
              ),
            ),
            if (isEditing && onCancel != null)
              TextButton.icon(
                icon: const Icon(Icons.cancel),
                onPressed: onCancel,
                label: Text(t(context, 'cancel_edit')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      BuildContext context, TextEditingController controller, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: t(context, key),
          border: const OutlineInputBorder(),
          suffixIcon: key == 'part' 
            ? GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(t(context, key)),
                      content: Text(t(context, 'part_tooltip')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(t(context, 'close')),
                        ),
                      ],
                    ),
                  );
                },
                child: const Icon(
                  Icons.help_outline,
                  size: 20,
                  color: Colors.grey,
                ),
              )
            : null,
        ),
      ),
    );
  }
}
