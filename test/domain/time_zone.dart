import 'dart:ffi';
import 'dart:io';

typedef _MallocC = Pointer<Uint8> Function(IntPtr);
typedef _MallocD = Pointer<Uint8> Function(int);
typedef _SetenvC = Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Int32);
typedef _SetenvD = int Function(Pointer<Uint8>, Pointer<Uint8>, int);

/// Switches the device time zone to [zone] for the duration of [body] (Linux and macOS).
/// `DateTime.toLocal` follows the change.
/// Without time zone data the zone behaves as UTC, so callers should check with `hasDaylightSaving`.
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

/// Whether daylight saving really applies to [zone] here. If not, the zone tests are skipped.
bool hasDaylightSaving(String zone) => withTimeZone(
  zone,
  () =>
      DateTime.utc(2026, 1, 15, 12).toLocal().timeZoneOffset !=
      DateTime.utc(2026, 7, 15, 12).toLocal().timeZoneOffset,
);
