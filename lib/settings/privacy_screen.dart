import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../design/app_theme.dart';
import '../design/parts/line_icon.dart';
import '../design/parts/pressable_surface.dart';
import '../design/tokens.g.dart';
import '../l10n/app_localizations.g.dart';
import 'privacy_policy.dart';

/// Shows the privacy policy of the app, read from the shipped markdown
/// document of the current language.
///
/// The renderer covers the subset the documents use: headings, note blocks,
/// bullet lists, paragraphs and blank lines. No markdown package: the files
/// are ours and stay this simple on purpose.
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({
    super.key,
    this.locale,
    this.loadDoc = loadDocFromBundle,
  });

  /// Null reads the locale the app is running in.
  final Locale? locale;

  /// Reads one document path. Injected for tests; production reads the
  /// asset bundle.
  final Future<String> Function(String path) loadDoc;

  static Future<String> loadDocFromBundle(String path) {
    return rootBundle.loadString(path);
  }

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  String? _text;
  Locale? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = widget.locale ?? Localizations.localeOf(context);
    if (_loadedFor == locale) return;
    _loadedFor = locale;
    _load(locale);
  }

  Future<void> _load(Locale locale) async {
    final text = await widget.loadDoc(privacyDocPath(locale));
    if (mounted) setState(() => _text = text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Row(
                children: [
                  PressableSurface.icon(
                    icon: LineIcons.backHeavy,
                    semanticLabel: l10n.common_back,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: Space.md),
                  Text(
                    l10n.settings_privacy,
                    style: TypeScale.title.copyWith(
                      color: context.palette.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _text == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        Space.lg,
                        0,
                        Space.lg,
                        Space.xl,
                      ),
                      child: _MarkdownBody(text: _text!),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkdownBody extends StatelessWidget {
  const _MarkdownBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final blocks = <Widget>[];
    final paragraphs = <String>[];

    void flushParagraph() {
      if (paragraphs.isEmpty) return;
      blocks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: Space.md),
          child: Text(
            paragraphs.join(' '),
            style: TypeScale.body.copyWith(color: palette.ink),
          ),
        ),
      );
      paragraphs.clear();
    }

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trimRight();
      if (line.isEmpty) {
        flushParagraph();
      } else if (line.startsWith('# ')) {
        flushParagraph();
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: Text(
              _plain(line.substring(2)),
              style: TypeScale.title.copyWith(
                color: palette.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        flushParagraph();
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: Space.lg, bottom: Space.sm),
            child: Text(
              _plain(line.substring(3)),
              style: TypeScale.body.copyWith(
                color: palette.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      } else if (line.startsWith('> ')) {
        flushParagraph();
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: Row(
              children: [
                Container(width: 2, color: palette.accent),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(
                    _plain(line.substring(2)),
                    style: TypeScale.label.copyWith(color: palette.inkMuted),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.startsWith('- ')) {
        flushParagraph();
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: Space.md),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.ink,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(
                    _plain(line.substring(2)),
                    style: TypeScale.body.copyWith(color: palette.ink),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        paragraphs.add(_plain(line));
      }
    }
    flushParagraph();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  /// The documents only mark code spans; the app shows them as plain text.
  static String _plain(String line) => line.replaceAll('`', '');
}
