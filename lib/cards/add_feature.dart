// lib/cards/add_feature.dart

import 'package:flutter/material.dart';

/// A single parameter definition.
class ParamDefinition {
  String name;
  String type;      // “Text”, “Number”, or “Dropdown”
  String options;   // comma‑separated, only for dropdown
  ParamDefinition({this.name = '', this.type = 'Text', this.options = ''});
}

/// Bottom sheet for creating a new “feature” (category + parameter list).
class AddFeatureSheet extends StatefulWidget {
  /// Called when the user taps “Save Category”.
  final void Function(String categoryName, List<ParamDefinition> params)
  onSave;
  const AddFeatureSheet({required this.onSave, Key? key}) : super(key: key);

  @override
  State<AddFeatureSheet> createState() => _AddFeatureSheetState();
}

class _AddFeatureSheetState extends State<AddFeatureSheet> {
  final _nameCtrl = TextEditingController();
  final _paramDefs = <ParamDefinition>[];

  @override
  Widget build(BuildContext context) {
    // Wrap in Padding so keyboard doesn’t cover fields:
    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        builder: (_, ctl) => SingleChildScrollView(
          controller: ctl,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New Category',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Category name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('Parameters',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),

              // Parameter rows:
              for (var i = 0; i < _paramDefs.length; i++)
                _ParamRow(
                  def: _paramDefs[i],
                  onDelete: () => setState(() => _paramDefs.removeAt(i)),
                ),

              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add parameter'),
                onPressed: () =>
                    setState(() => _paramDefs.add(ParamDefinition())),
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                child: const Text('Save Category'),
                onPressed: () {
                  final name = _nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  widget.onSave(name, List.from(_paramDefs));
                  Navigator.pop(context);  // <-- this already closes the sheet
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row in the parameters list.
class _ParamRow extends StatelessWidget {
  final ParamDefinition def;
  final VoidCallback onDelete;
  const _ParamRow({required this.def, required this.onDelete, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Name field
          Flexible(
            flex: 3,
            child: TextField(
              onChanged: (v) => def.name = v,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Type dropdown
          Flexible(
            flex: 2,
            child: DropdownButtonFormField<String>(
              isExpanded: true,    // ← this fixes the overflow
              value: def.type,
              items: const ['Text','Number','Dropdown']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => def.type = v!,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // If it’s a dropdown parameter, show options field
          if (def.type == 'Dropdown')
            Flexible(
              flex: 4,
              child: TextField(
                onChanged: (v) => def.options = v,
                decoration: const InputDecoration(
                  labelText: 'Options (comma‑sep)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),

          const SizedBox(width: 8),

          // Delete button
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
