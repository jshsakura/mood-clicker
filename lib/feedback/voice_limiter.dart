/// Keeps the number of ringing voices under a cap. When a new voice arrives beyond it, the oldest
/// is faded out. Voices that already ended are forgotten first.
class VoiceLimiter<H> {
  VoiceLimiter({
    required this.max,
    required this.isAlive,
    required this.fadeOut,
  });

  final int max;
  final bool Function(H voice) isAlive;
  final void Function(H voice) fadeOut;
  final List<H> _voices = [];

  /// Registers a voice that has just started.
  void admit(H voice) {
    _voices.removeWhere((voice) => !isAlive(voice));
    _voices.add(voice);
    while (_voices.length > max) {
      fadeOut(_voices.removeAt(0));
    }
  }
}
