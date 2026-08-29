import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'share_service.g.dart';

// Single-method abstract class for DI/mocking, same as every other
// repository/service interface in this codebase.
// ignore: one_member_abstracts
abstract class ShareService {
  /// Writes [json] to a temp file named [fileName] and opens the platform
  /// share sheet for it.
  Future<void> shareJsonFile(
    String json, {
    required String fileName,
    String? subject,
  });
}

class SharePlusService implements ShareService {
  @override
  Future<void> shareJsonFile(
    String json, {
    required String fileName,
    String? subject,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(json);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: subject),
    );
  }
}

@Riverpod(keepAlive: true)
ShareService shareService(Ref ref) => SharePlusService();
