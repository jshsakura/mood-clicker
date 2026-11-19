import 'package:flutter/material.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/parts/dawn_wash.dart';

import 'harness.dart';

/// The progress steps shot for the dawn wash.
const releaseSteps = [(0, 0.0), (50, 0.5), (100, 1.0)];

/// The dawn wash at progress 0, 0.5 and 1, in every theme, on one device.
final releasePartShots = <GoldenScreen>[
  for (final (percent, progress) in releaseSteps) ...[
    GoldenScreen(
      'dawn_wash_$percent',
      (choice) => Builder(
        builder: (context) => ColoredBox(
          color: context.palette.ground,
          child: DawnWash(progress: progress),
        ),
      ),
      deviceNames: const {'iphone'},
    ),
  ],
];
