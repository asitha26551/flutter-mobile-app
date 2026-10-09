import 'package:flutter/material.dart';

import '../../screens/counselor/counselor_theme.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: dashboardGreen),
        if (message != null) ...[
          const SizedBox(height: 14),
          Text(
            message!,
            style: const TextStyle(
              color: dashboardGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    ),
  );
}
