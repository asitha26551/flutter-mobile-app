import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.black54)),
      ),
    ),
  );
}
