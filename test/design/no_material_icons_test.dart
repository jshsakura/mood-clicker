import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Every icon of the app is a line icon from assets/icons. This pins that no screen falls back to
// Material icons or emoji characters.
void main() {
  final sources = [
    for (final entity in Directory('lib').listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart')) entity,
  ];

  final emoji = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B50}\u{2B06}\u{2705}]|\\u\{1F[0-9A-Fa-f]{3}\}|\\u(2[67]|2B)[0-9A-Fa-f]{2}',
    unicode: true,
  );
  final material = RegExp(
    r'\bIcons\.[a-z]|\bCupertinoIcons\.|\bIcon\(|\bIconData\b|\bImageIcon\(',
  );

  test('lib has dart sources to check', () {
    expect(sources, isNotEmpty);
  });

  test('no Material or Cupertino icon is used in lib', () {
    final hits = <String>[];
    for (final file in sources) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (material.hasMatch(lines[i])) hits.add('${file.path}:${i + 1}');
      }
    }
    expect(hits, isEmpty, reason: 'use LineIcon from lib/design/parts');
  });

  test('no emoji or symbol character is written in lib', () {
    final hits = <String>[];
    for (final file in sources) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (emoji.hasMatch(lines[i])) hits.add('${file.path}:${i + 1}');
      }
    }
    expect(hits, isEmpty, reason: 'draw it as a line icon instead');
  });
}
