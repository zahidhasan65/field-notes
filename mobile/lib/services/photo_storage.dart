import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/core.dart';


class PhotoStorage {
  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'note_photos'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> copyIn(String sourcePath) async {
    final dir = await _dir();
    var ext = p.extension(sourcePath).toLowerCase();
    if (ext.isEmpty) ext = '.jpg';
    final target = p.join(dir.path, '${newUuid()}$ext');
    await File(sourcePath).copy(target);
    return target;
  }

  Future<String> saveBytes(String noteId, List<int> bytes, {String ext = '.jpg'}) async {
    final dir = await _dir();
    final target = p.join(dir.path, '$noteId-${DateTime.now().millisecondsSinceEpoch}$ext');
    await File(target).writeAsBytes(bytes, flush: true);
    return target;
  }

  Future<void> delete(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // best effort
    }
  }

  Future<void> deleteAll(Iterable<String> paths) async {
    for (final path in paths) {
      await delete(path);
    }
  }
}
