enum MoodSide { happy, sad }

/// 고를 수 있는 기분. 초안 목록이고 `id` 는 저장 파일에 들어가므로 바꾸지 않는다.
enum Mood {
  happy('happy', '행복해요', MoodSide.happy),
  excited('excited', '설레요', MoodSide.happy),
  angry('angry', '화나요', MoodSide.sad),
  sad('sad', '슬퍼요', MoodSide.sad),
  anxious('anxious', '불안해요', MoodSide.sad);

  const Mood(this.id, this.label, this.side);

  final String id;
  final String label;
  final MoodSide side;

  static Mood? byId(String id) {
    for (final mood in values) {
      if (mood.id == id) return mood;
    }
    return null;
  }
}
