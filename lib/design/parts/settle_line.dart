import 'package:flutter/material.dart';

import '../../domain/mood.dart';
import '../../domain/tuning.dart';
import '../../l10n/app_localizations.g.dart';
import '../app_theme.dart';
import '../tokens.g.dart';

/// The one line after the settle of a heavy mood, or null for a mood that keeps its normal finish.
/// The words never say the mood is gone or better.
String? settleLineFor(AppLocalizations l10n, Mood mood) => switch (mood) {
  Mood.angry => l10n.release_settleAngry,
  Mood.sad => l10n.release_settleSad,
  Mood.anxious => l10n.release_settleAnxious,
  Mood.happy || Mood.excited => null,
};

/// A line that floats up, stays for [ReleaseTuning.settleLineHold], and fades away. With the reduced
/// motion setting it only fades.
class SettleLine extends StatefulWidget {
  const SettleLine({super.key, required this.text});

  final String text;

  /// How far the line rises while it fades in.
  static const double rise = Space.md;

  @override
  State<SettleLine> createState() => _SettleLineState();
}

class _SettleLineState extends State<SettleLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: Motion.page + ReleaseTuning.settleLineHold + Motion.page,
  )..forward();

  /// 0 to 1 to 0: in over [Motion.page], held, out over [Motion.page].
  double _shown() {
    final total = _clock.duration!.inMicroseconds;
    final at = _clock.value * total;
    final edge = Motion.page.inMicroseconds;
    if (at < edge) return at / edge;
    if (at > total - edge) return (total - at) / edge;
    return 1;
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final p = context.palette;
    return AnimatedBuilder(
      animation: _clock,
      builder: (context, child) {
        if (_clock.isCompleted) return const SizedBox.shrink();
        final shown = _shown();
        return Opacity(
          opacity: shown,
          child: Transform.translate(
            offset: Offset(0, reduce ? 0 : SettleLine.rise * (1 - shown)),
            child: child,
          ),
        );
      },
      child: Text(
        widget.text,
        textAlign: TextAlign.center,
        style: TypeScale.body.copyWith(color: p.ink2),
      ),
    );
  }
}
