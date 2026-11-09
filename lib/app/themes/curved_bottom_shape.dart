import 'package:flutter/material.dart';

class CurvedBottomShape extends ContinuousRectangleBorder {
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    const physicalDepth = 14.0;
    const controlPointDepth = physicalDepth * 2;
    const cutoutRadius = 62.0;

    double center = rect.width / 2;

    Path path = Path();
    path.lineTo(0, rect.height);

    // Draw line to start of cutout
    path.lineTo(center - cutoutRadius, rect.height);

    // Swoop down to tightly wrap the bottom of the circle
    path.quadraticBezierTo(
      center,
      rect.height + controlPointDepth,
      center + cutoutRadius,
      rect.height,
    );

    // Draw line to end
    path.lineTo(rect.width, rect.height);
    path.lineTo(rect.width, 0);
    path.close();

    return path;
  }
}
