import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_info_service.g.dart';

// Single-method abstract class for DI/mocking, same as every other
// repository/service interface in this codebase.
// ignore: one_member_abstracts
abstract class AppInfoService {
  Future<String> versionLabel();
}

class PackageInfoAppInfoService implements AppInfoService {
  @override
  Future<String> versionLabel() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }
}

@Riverpod(keepAlive: true)
AppInfoService appInfoService(Ref ref) => PackageInfoAppInfoService();
