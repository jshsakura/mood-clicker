import 'package:flutter/painting.dart';

/// How visible a text (or graphic) color is on its background: the WCAG relative luminance ratio.
/// A translucent color is measured as composited over the background. Ignoring alpha would let invisible colors pass.
double contrast(Color foreground, Color background) {
  assert(background.a == 1, 'the background must be opaque');
  final seen = Color.alphaBlend(foreground, background);
  final la = seen.computeLuminance();
  final lb = background.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
