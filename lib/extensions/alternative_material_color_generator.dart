import 'package:flutter/material.dart';

extension AlternativeMaterialColorGenerator on Color {
  MaterialColor toMaterialColorAlt() {
    final double r = red.toDouble();
    final double g = green.toDouble();
    final double b = blue.toDouble();

    final Map<int, Color> swatch = {};
    final List<double> strengths = <double>[.05]; // For shade 50

    // Add strengths for shades 100 through 900
    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (final double strength in strengths) {
      final double ds = 0.5 - strength; // Strength relative to 500 (0.5)
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        (r + (ds < 0 ? r : (255 - r)) * ds).round().clamp(0, 255),
        (g + (ds < 0 ? g : (255 - g)) * ds).round().clamp(0, 255),
        (b + (ds < 0 ? b : (255 - b)) * ds).round().clamp(0, 255),
        1.0,
      );
    }
    // Ensure the 500 shade is exactly the original color,
    // in case of any floating point inaccuracies from the calculation.
    swatch[500] = this;
    return MaterialColor(value, swatch);
  }
}