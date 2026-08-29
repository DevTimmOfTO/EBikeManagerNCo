import 'package:ebikemanager/core/database/repositories/drift_app_settings_repository.dart';
import 'package:ebikemanager/core/domain/entities/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_settings_providers.g.dart';

@riverpod
Stream<AppSettings> appSettings(Ref ref) =>
    ref.watch(appSettingsRepositoryProvider).watchSettings();
