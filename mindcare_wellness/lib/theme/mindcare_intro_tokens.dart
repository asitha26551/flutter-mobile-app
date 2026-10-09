import 'package:flutter/material.dart';

abstract final class MindCareIntroTokens {
  static const primary = Color(0xFF0B7A14);
  static const mint = Color(0xFF4ADE60);
  static const softGreen = Color(0xFFD9F7DC);
  static const paleGreen = Color(0xFFEAFBEC);
  static const scaffold = Color(0xFFF9FBFF);
  static const ink = Color(0xFF1A1F1B);
  static const muted = Color(0xFF5E6B61);
  static const darkGreen = Color(0xFF07520D);

  static const pageBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5FFF6), Color(0xFFE5F9E8)],
  );

  static const splashBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B7A14), Color(0xFF07520D)],
  );
}
