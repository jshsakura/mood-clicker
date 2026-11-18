import 'mood_journal.dart';

sealed class LoadResult {
  const LoadResult();
}

class Loaded extends LoadResult {
  const Loaded(this.journal);
  final MoodJournal journal;
}

/// 파일은 있는데 읽을 수 없다. 호출자는 지우지 말고 사용자에게 알려야 한다.
class LoadFailed extends LoadResult {
  const LoadFailed(this.reason);
  final String reason;
}

abstract interface class MoodRepository {
  Future<LoadResult> load();

  /// 쓰기 실패는 예외로 알린다. 파일에 이미 같은 내용이 있어 쓰기를 건너뛰면 false,
  /// 실제로 썼으면 true. 여러 번 겹쳐 불러도 하나씩 차례로 쓴다.
  Future<bool> save(MoodJournal journal);
}
