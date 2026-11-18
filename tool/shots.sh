#!/usr/bin/env bash
# 화면을 기기 없이 그림(PNG)으로 뽑아 눈으로 확인한다. 도커 안에서 돈다.
#   tool/shots.sh            그림을 새로 뽑아 build/shots/ 에 낸다. 커밋하지 않는다
#   tool/shots.sh --check    커밋된 골든(test/goldens/images/)과 비교한다. 다르면 실패한다
#   tool/shots.sh --update   커밋된 골든을 지금 화면으로 바꾼다. 바뀐 그림을 눈으로 본 뒤 커밋한다
#
# 골든은 리눅스 도커 이미지에서 뽑은 것이라 맥이나 다른 환경과 픽셀이 다르다.
# 그래서 비교는 이 스크립트와 CI(같은 이미지)에서만 한다.
set -euo pipefail
cd "$(dirname "$0")/.."
TEST=test/goldens/golden_test.dart

case "${1:-}" in
  "")
    rm -rf build/shots
    tool/fl test "$TEST" --dart-define=SHOTS_OUT=build/shots
    echo "그림 $(find build/shots -name '*.png' | wc -l)장: build/shots/"
    ;;
  --check)
    rm -rf test/goldens/failures
    if tool/fl test "$TEST"; then
      echo "✓ 커밋된 골든과 같습니다"
    else
      echo "✗ 골든과 다릅니다. 차이 그림: test/goldens/failures/ (*_masterImage 가 기존, *_testImage 가 지금, *_isolatedDiff 가 차이)" >&2
      echo "  의도한 변경이면 tool/shots.sh --update 로 골든을 바꿉니다." >&2
      exit 1
    fi
    ;;
  --update)
    tool/fl test "$TEST" --update-goldens
    echo "골든을 바꿨습니다. git diff --stat test/goldens/images 로 어느 그림이 바뀌었는지 보고, 그림을 열어 확인한 뒤 커밋합니다"
    ;;
  *)
    echo "사용: tool/shots.sh [--check|--update]" >&2
    exit 2
    ;;
esac
