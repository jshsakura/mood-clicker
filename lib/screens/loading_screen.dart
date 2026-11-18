import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_services.dart';
import '../design/app_theme.dart';
import '../design/tokens.g.dart';
import '../domain/mood_journal.dart';
import '../domain/mood_repository.dart';
import '../l10n/app_localizations.g.dart';
import 'mood_select_screen.dart';
import 'tap/tap_screen.dart';

/// The first screen: the wordmark in the middle while the journal loads. A journal that cannot
/// be read is never deleted. The user is told, and starts with an empty one; the unreadable file
/// was already copied aside by the repository.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final services = AppScope.of(context);
    final result = await services.journal.repository.load();
    if (!mounted) return;
    switch (result) {
      case Loaded(:final journal):
        services.journal.load(journal);
      case LoadFailed():
        services.journal.load(MoodJournal.empty());
        await _tellBroken();
        if (!mounted) return;
    }
    final navigator = Navigator.of(context);
    unawaited(
      navigator.pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: Motion.page,
          pageBuilder: (_, _, _) => const MoodSelectScreen(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
    );
    // A widget or shortcut that started the app asked for a mood: open it on top of the picker.
    final launch = services.launchMood.value;
    if (launch != null) {
      services.launchMood.value = null;
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => TapScreen(mood: launch)),
        ),
      );
    }
  }

  Future<void> _tellBroken() {
    final l10n = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.loading_brokenTitle),
        content: Text(l10n.loading_brokenBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.loading_startNew),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: Center(
        child: Text(
          AppLocalizations.of(context).appName,
          style: TypeScale.wordmark.copyWith(color: p.ink),
        ),
      ),
    );
  }
}
