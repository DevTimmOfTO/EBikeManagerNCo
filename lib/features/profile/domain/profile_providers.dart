import 'package:ebikemanager/core/app_info/app_info_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_providers.g.dart';

@riverpod
Future<String> appVersionLabel(Ref ref) =>
    ref.watch(appInfoServiceProvider).versionLabel();
