/// Feedback kinds called by screens. UI code only knows this enum and mood IDs.
enum FeedbackKind {
  /// Played on each tap; varies by mood.
  tap,

  /// Played when the fill gauge reaches full.
  full,

  /// Played when a mood banner is selected.
  select,

  /// Played when the fill gauge drops back to zero.
  drop,

  /// Played when a rare cheer phrase appears.
  rare,
}
