import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// A comparator that does not compare and only writes pictures to a folder. tool/shots.sh uses it.
/// It never touches the committed goldens.
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
