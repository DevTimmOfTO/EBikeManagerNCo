import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'local_image_store.g.dart';

/// Persists user-picked photos (bike photos, ADFC engraving photos, avatar)
/// into this app's private storage, since paths from `image_picker` are only
/// valid until the OS clears its own temp/cache directory.
abstract class LocalImageStore {
  /// Copies [source] into a [category] subfolder of app storage and returns
  /// the new absolute path. Deletes [previousPath] first, if given, so
  /// replacing a photo doesn't leak the old file.
  Future<String> save(
    XFile source, {
    required String category,
    String? previousPath,
  });

  Future<void> delete(String path);
}

class FileSystemImageStore implements LocalImageStore {
  static const _uuid = Uuid();

  @override
  Future<String> save(
    XFile source, {
    required String category,
    String? previousPath,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(docsDir.path, category));
    await targetDir.create(recursive: true);
    final targetPath = p.join(
      targetDir.path,
      '${_uuid.v4()}${p.extension(source.path)}',
    );
    await File(source.path).copy(targetPath);
    if (previousPath != null) {
      await delete(previousPath);
    }
    return targetPath;
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }
}

@Riverpod(keepAlive: true)
LocalImageStore localImageStore(Ref ref) => FileSystemImageStore();
