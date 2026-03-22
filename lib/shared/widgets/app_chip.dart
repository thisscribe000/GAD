import 'package:flutter/material.dart';

enum ChipType { filter, choice, action }

class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final ChipType type;

  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.type = ChipType.filter,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ChipType.filter:
        return FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onSelected(),
          backgroundColor: Colors.grey[200],
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.primary,
        );
      case ChipType.choice:
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onSelected(),
          backgroundColor: Colors.grey[200],
          selectedColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black,
          ),
        );
      case ChipType.action:
        return ActionChip(
          label: Text(label),
          onPressed: onSelected,
          backgroundColor: Colors.grey[200],
        );
    }
  }
}
