import 'package:flutter/material.dart';

class CounterWidget extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onIncrement;

  const CounterWidget({
    super.key,
    required this.label,
    required this.value,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall,  // Small text for label
        ),
        Text(
          '$value',
          style: Theme.of(context).textTheme.headlineLarge,  // Large text for number
        ),
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
