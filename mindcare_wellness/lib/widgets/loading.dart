import 'package:flutter/material.dart';

import '../../screens/counselor/counselor_theme.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: dashboardGreen));
}
