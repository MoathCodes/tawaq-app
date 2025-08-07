// import 'package:flutter/material.dart';
// import 'package:forui/forui.dart';

// class GradientBackground extends StatelessWidget {
//   final Widget child;

//   const GradientBackground({super.key, required this.child});

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.theme.colors;
//     final backgroundLuminance = colors.background.computeLuminance();

//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             _adaptColorToTheme(colors.foreground, backgroundLuminance, 0.02),
//             Colors.transparent,
//           ],
//         ),
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: RadialGradient(
//             center: const Alignment(0.7, -0.7), // 85% 15%
//             radius: 2.5, // Equivalent to 900px/500px coverage
//             colors: [
//               _adaptColorToTheme(colors.primary, backgroundLuminance, 0.25),
//               Colors.transparent,
//             ],
//             stops: const [0.0, 0.6],
//           ),
//         ),
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: RadialGradient(
//               center: const Alignment(-0.8, 0.6), // 10% 80%
//               radius: 2.0, // Equivalent to 700px/450px coverage
//               colors: [
//                 _adaptColorToTheme(colors.secondary, backgroundLuminance, 0.2),
//                 Colors.transparent,
//               ],
//               stops: const [0.0, 0.6],
//             ),
//           ),
//           child: Container(
//             decoration: BoxDecoration(
//               gradient: RadialGradient(
//                 center: const Alignment(0.0, -1.2), // 50% -10%
//                 radius: 3.0, // Equivalent to 1200px/700px coverage
//                 colors: [
//                   _adaptColorToTheme(_generateComplementaryColor(colors),
//                       backgroundLuminance, 0.12),
//                   Colors.transparent,
//                 ],
//                 stops: const [0.0, 0.7],
//               ),
//             ),
//             child: child,
//           ),
//         ),
//       ),
//     );
//   }

//   /// Adapts gradient colors to work well with both light and dark themes
//   Color _adaptColorToTheme(
//       Color baseColor, double backgroundLuminance, double baseOpacity) {
//     // For very dark themes (background luminance < 0.1), use the colors as-is
//     // For light themes, we might want to adjust the colors to be more subtle

//     if (backgroundLuminance > 0.7) {
//       // Light theme - make colors more subtle and darker
//       final hsv = HSVColor.fromColor(baseColor);
//       final adjustedColor = hsv
//           .withSaturation((hsv.saturation * 0.6).clamp(0.0, 1.0))
//           .withValue((hsv.value * 0.7).clamp(0.0, 1.0))
//           .toColor();
//       return adjustedColor.withOpacity(baseOpacity * 0.8);
//     } else if (backgroundLuminance > 0.3) {
//       // Medium theme - slight adjustment
//       return baseColor.withOpacity(baseOpacity * 0.9);
//     } else {
//       // Dark theme - use colors as-is or slightly enhanced
//       return baseColor.withOpacity(baseOpacity);
//     }
//   }

//   /// Generates a complementary color based on the theme's primary color
//   Color _generateComplementaryColor(FColors colors) {
//     final primaryHsv = HSVColor.fromColor(colors.primary);
//     // Shift hue by 120-180 degrees for a complementary/triadic color
//     final complementaryHue = (primaryHsv.hue + 150) % 360;
//     return primaryHsv
//         .withHue(complementaryHue)
//         .withSaturation((primaryHsv.saturation * 0.8).clamp(0.0, 1.0))
//         .toColor();
//   }
// }
