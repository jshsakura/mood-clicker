import 'dart:convert';

import 'package:mood_clicker/domain/cheer.dart';
import 'package:mood_clicker/domain/mood.dart';

/// Moods with [size] fake phrases per stage, named like `2h7` (mood index, stage letter, number).
/// With [complete] or [rare] false the optional bundle of that name is left out.
Map<String, Object?> moodsWith(
  int size, {
  bool complete = true,
  bool rare = true,
}) => {
  for (final mood in Mood.values)
    mood.id: <String, Object?>{
      for (final stage in CheerStage.values)
        if ((complete || stage != CheerStage.complete) &&
            (rare || stage != CheerStage.rare))
          stage.id: <Object?>[
            for (var i = 0; i < size; i++) '${mood.index}${stage.id[0]}$i',
          ],
    },
};

String fileOf(Map<String, Object?> moods) =>
    jsonEncode({'version': 1, 'moods': moods});

CheerBook bookOf(int size, {bool complete = true}) =>
    CheerBook.parse(fileOf(moodsWith(size, complete: complete))).book;
