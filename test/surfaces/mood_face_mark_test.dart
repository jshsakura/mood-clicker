import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/surfaces/mood_face_mark.dart';

void main() {
  testWidgets('every mood draws a face without layout errors', (tester) async {
    for (final mood in Mood.values) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: MoodFaceMark(mood: mood, size: 120)),
        ),
      );
      expect(tester.takeException(), isNull, reason: mood.id);
      expect(tester.getSize(find.byType(MoodFaceMark)), const Size.square(120));
    }
  });

  testWidgets('the face is a flat disc: no gradient, shadow or blur', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MoodFaceMark(mood: Mood.happy),
      ),
    );
    expect(find.byType(DecoratedBox), findsNothing);
    expect(find.byType(PhysicalModel), findsNothing);
  });
}
