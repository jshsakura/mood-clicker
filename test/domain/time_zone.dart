import 'dart:ffi';
import 'dart:io';

typedef _MallocC = Pointer<Uint8> Function(IntPtr);
typedef _MallocD = Pointer<Uint8> Function(int);
typedef _SetenvC = Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Int32);
typedef _SetenvD = int Function(Pointer<Uint8>, Pointer<Uint8>, int);

/// 테스트 안에서만 기기 시간대를 [zone] 으로 바꾼다(리눅스, 맥). `DateTime.toLocal` 이 따라온다.
/// 시간대 데이터가 없는 환경이면 zone 이 UTC 로 취급되므로 호출한 쪽이 확인한다.
T withTimeZone<T>(String zone, T Function() body) {
  final libc = DynamicLibrary.process();
  final malloc = libc.lookupFunction<_MallocC, _MallocD>('malloc');
  final setenv = libc.lookupFunction<_SetenvC, _SetenvD>('setenv');
  final tzset = libc.lookupFunction<Void Function(), void Function()>('tzset');
  Pointer<Uint8> cstr(String s) {
    final bytes = s.codeUnits;
    final p = malloc(bytes.length + 1);
    for (var i = 0; i < bytes.length; i++) {
      p[i] = bytes[i];
    }
    p[bytes.length] = 0;
    return p;
  }

  final before = Platform.environment['TZ'] ?? '';
  setenv(cstr('TZ'), cstr(zone), 1);
  tzset();
  try {
    return body();
  } finally {
    setenv(cstr('TZ'), cstr(before), 1);
    tzset();
  }
}

/// 이 환경에서 [zone] 의 서머타임이 실제로 적용되는지. 아니면 시간대 테스트를 건너뛴다.
bool hasDaylightSaving(String zone) => withTimeZone(
  zone,
  () =>
      DateTime.utc(2026, 1, 15, 12).toLocal().timeZoneOffset !=
      DateTime.utc(2026, 7, 15, 12).toLocal().timeZoneOffset,
);
