import 'package:flutter/material.dart';

class IosPatternBackground extends StatelessWidget {
  final Widget child;

  const IosPatternBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFE5E5E7)),
      child: Stack(
        children: [
          // The dot pattern
          Positioned.fill(child: CustomPaint(painter: _PatternPainter())),
          child,
        ],
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D1D6)
      ..strokeWidth = 1.0;

    const spacing = 4.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        if ((x / spacing).floor() % 2 == (y / spacing).floor() % 2) {
          canvas.drawRect(Rect.fromLTWH(x, y, 1.5, 1.5), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
