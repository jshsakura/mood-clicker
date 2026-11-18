import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/parts/line_icon.dart';
import 'package:mood_clicker/design/parts/pressable_surface.dart';
import 'package:mood_clicker/design/tokens.g.dart';

Widget host(Widget child) => MaterialApp(
  theme: buildTheme(lightPalette),
  home: Scaffold(body: Center(child: child)),
);

double scaleOf(WidgetTester tester) =>
    tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

void main() {
  testWidgets('a card shrinks to 0.98 while pressed and back after', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        PressableSurface(
          kind: PressableKind.card,
          onTap: () => taps++,
          child: const SizedBox(width: 200, height: 80),
        ),
      ),
    );
    expect(scaleOf(tester), 1);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PressableSurface)),
    );
    await tester.pump();
    expect(scaleOf(tester), 0.98);
    await gesture.up();
    await tester.pump();
    expect(scaleOf(tester), 1);
    expect(taps, 1);
  });

  testWidgets('an icon button is a 44 px circle that shrinks to 0.92', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        PressableSurface.icon(
          icon: LineIcons.back,
          onTap: () {},
          semanticLabel: 'back',
        ),
      ),
    );
    expect(tester.getSize(find.byType(PressableSurface)), const Size(44, 44));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PressableSurface)),
    );
    await tester.pump();
    expect(scaleOf(tester), 0.92);
    await gesture.up();
  });

  testWidgets('a press that slides away cancels without a tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        PressableSurface(
          kind: PressableKind.card,
          onTap: () => taps++,
          child: const SizedBox(width: 200, height: 80),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PressableSurface)),
    );
    await tester.pump();
    await gesture.moveBy(const Offset(0, 300));
    await gesture.up();
    await tester.pump();
    expect(taps, 0);
    expect(scaleOf(tester), 1);
  });

  testWidgets('with no onTap it does not react', (tester) async {
    await tester.pumpWidget(
      host(
        const PressableSurface(
          kind: PressableKind.card,
          onTap: null,
          child: SizedBox(width: 200, height: 80),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PressableSurface)),
    );
    await tester.pump();
    expect(scaleOf(tester), 1);
    await gesture.up();
  });

  testWidgets('it uses no ink splash and no rectangular highlight', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        PressableSurface(
          kind: PressableKind.card,
          onTap: () {},
          child: const SizedBox(width: 200, height: 80),
        ),
      ),
    );
    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(Ink), findsNothing);
  });

  testWidgets('the press time is the tap motion token', (tester) async {
    await tester.pumpWidget(
      host(
        PressableSurface(
          kind: PressableKind.card,
          onTap: () {},
          child: const SizedBox(width: 200, height: 80),
        ),
      ),
    );
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
      Motion.tap,
    );
  });
}
