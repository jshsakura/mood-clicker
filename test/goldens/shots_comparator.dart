import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// 비교하지 않고 그림을 폴더에 쓰기만 하는 비교기. tool/shots.sh 가 쓴다.
/// 커밋된 골든은 건드리지 않는다.
class ShotsComparator extends GoldenFileComparator {
  ShotsComparator(this.dir);

  final Directory dir;

  Future<void> _write(Uint8List bytes, Uri golden) async {
    await dir.create(recursive: true);
    await File('${dir.path}/${golden.pathSegments.last}').writeAsBytes(bytes);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    await _write(imageBytes, golden);
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) =>
      _write(imageBytes, golden);
}

void useShotsOutput(Directory dir) {
  goldenFileComparator = ShotsComparator(dir);
}
