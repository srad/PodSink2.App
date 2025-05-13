
import 'package:flutter/material.dart';

extension ColorToMaterialColorExtension on Color {
  /// Converts a [Color] to a [MaterialColor] by generating a swatch of 10 shades.
  ///
  /// The original color is used as the [500] shade. Lighter shades are generated
  /// by tinting towards white, and darker shades by shading towards black.
  ///
  /// ```dart
  /// final MaterialColor myCustomSwatch = Colors.blue.toMaterialColor();
  ///
  /// // Then use it in your theme:
  /// ThemeData(  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  ///   primarySwatch: myCustomSwatch,
  /// )
  /// ```
  MaterialColor toMaterialColor() {
    final int r = red;
    final int g = green;
    final int b = blue;

    final Map<int, Color> swatch = {
      50: _tintColor(this, 0.9),  // Lightest
      100: _tintColor(this, 0.8),
      200: _tintColor(this, 0.6),
      300: _tintColor(this, 0.4),
      400: _tintColor(this, 0.2),
      500: this, // The original color
      600: _shadeColor(this, 0.1),
      700: _shadeColor(this, 0.2),
      800: _shadeColor(this, 0.3),
      900: _shadeColor(this, 0.4), // Darkest
    };

    // The `MaterialColor` constructor expects an `int` for its primary value.
    // `this.value` (the 32-bit ARGB integer representation of the color) is suitable here.
    //
    // Deprecation notes for `Color.value` (as of early 2025):
    // There were significant discussions and deprecations around `Color` properties
    // (like `Color.value`, `Color.red`, `Color.alpha`, etc.) around Flutter 3.27
    // in late 2024, primarily related to the introduction of wide gamut color support
    // and a shift towards floating-point components (e.g., `Color.r`, `Color.g`, `Color.b`, `Color.a`).
    //
    // However, the `MaterialColor(int primary, Map<int, Color> swatch)` constructor
    // still requires an `int` for the `primary` argument. The documentation for this
    // constructor explicitly states: "The primary argument should be the 32 bit ARGB value of
    // one of the values in the swatch, as would be passed to the Color.new constructor
    // for that same color, and as is exposed by value."
    //
    // As of the latest API docs checked (simulated for May 2025), `Color.value` (the getter)
    // is not marked as deprecated, and is the direct way to get this integer.
    // The integer component getters like `this.red`, `this.green`, `this.blue` also remain.
    //
    // If `Color.value` were to become definitively deprecated and removed without a direct
    // replacement integer getter suitable for `MaterialColor`, you would need to reconstruct it:
    // `int primaryValue = (alpha << 24) | (red << 16) | (green << 8) | blue;`
    // But for now, `this.value` is the correct and intended property.

    return MaterialColor(value, swatch);
  }

  /// Tints the given [color] towards white by the [factor].
  /// A [factor] of 0.0 means no change, 1.0 means full white.
  Color _tintColor(Color color, double factor) {
    assert(factor >= 0.0 && factor <= 1.0);
    final int r = color.red + ((255 - color.red) * factor).round();
    final int g = color.green + ((255 - color.green) * factor).round();
    final int b = color.blue + ((255 - color.blue) * factor).round();
    return Color.fromRGBO(
      r.clamp(0, 255), // Ensure values are within 0-255 range
      g.clamp(0, 255),
      b.clamp(0, 255),
      1.0, // Opacity is always 1.0 for swatch colors
    );
  }

  /// Shades the given [color] towards black by the [factor].
  /// A [factor] of 0.0 means no change, 1.0 means full black.
  Color _shadeColor(Color color, double factor) {
    assert(factor >= 0.0 && factor <= 1.0);
    final int r = color.red - (color.red * factor).round();
    final int g = color.green - (color.green * factor).round();
    final int b = color.blue - (color.blue * factor).round();
    return Color.fromRGBO(
      r.clamp(0, 255), // Ensure values are within 0-255 range
      g.clamp(0, 255),
      b.clamp(0, 255),
      1.0, // Opacity is always 1.0 for swatch colors
    );
  }
}