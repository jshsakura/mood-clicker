enum MoodSide { happy, sad }

/// The moods a user can pick. This is a draft list. `id` goes into the save file, so never change it.
/// Display names live in the translation files, not here.
enum Mood {
  happy('happy', MoodSide.happy),
  excited('excited', MoodSide.happy),
  angry('angry', MoodSide.sad),
  sad('sad', MoodSide.sad),
  anxious('anxious', MoodSide.sad);

  const Mood(this.id, this.side);

  final String id;
  final MoodSide side;

  static Mood? byId(String id) {
    for (final mood in values) {
      if (mood.id == id) return mood;
    }
    return null;
  }
}
