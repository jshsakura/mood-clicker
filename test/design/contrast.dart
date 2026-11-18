import 'package:flutter/painting.dart';

/// 글자색(또는 그림 색)이 바탕 위에서 보이는 대비. WCAG 상대 휘도 비율이다.
/// 반투명한 색은 바탕에 합성한 색으로 잰다. 알파를 무시하면 안 보이는 색도 통과해 버린다.
double contrast(Color foreground, Color background) {
  assert(background.a == 1, '바탕은 불투명해야 합니다');
  final seen = Color.alphaBlend(foreground, background);
  final la = seen.computeLuminance();
  final lb = background.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
