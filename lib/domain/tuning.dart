/// Numbers for the fill gauge. Judge the feel on a real device and adjust only here.
abstract final class GaugeTuning {
  /// How much one tap raises the level.
  static const double stepPerTap = 0.025;

  /// How long the level holds after the last tap.
  static const Duration grace = Duration(milliseconds: 300);

  /// How much the level falls per second once the grace time is over.
  static const double decayPerSecond = 0.2;

  /// How long the on-screen gauge takes to catch up with the real level (exponential smoothing).
  /// For display only: the domain never uses it, and the screen does the smoothing.
  static const Duration displayFollow = Duration(milliseconds: 220);
}

/// Numbers for save batching.
abstract final class SaveTuning {
  /// How often to write to disk while the user keeps tapping.
  static const Duration interval = Duration(seconds: 2);
}
