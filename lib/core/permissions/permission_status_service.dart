import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_status_service.g.dart';

enum AppPermissionStatus { granted, denied, permanentlyDenied, restricted }

abstract class PermissionStatusService {
  /// Read-only status check. Location is requested elsewhere via `geolocator`
  /// (see navigation_providers.dart) to avoid the two plugins racing to
  /// request the same OS permission; this only ever reads the status.
  Future<AppPermissionStatus> locationStatus();

  Future<AppPermissionStatus> cameraStatus();

  Future<void> openSettings();
}

class DevicePermissionStatusService implements PermissionStatusService {
  @override
  Future<AppPermissionStatus> locationStatus() async =>
      _map(await Permission.locationWhenInUse.status);

  @override
  Future<AppPermissionStatus> cameraStatus() async =>
      _map(await Permission.camera.status);

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }

  AppPermissionStatus _map(PermissionStatus status) => switch (status) {
    PermissionStatus.granted ||
    PermissionStatus.limited ||
    PermissionStatus.provisional => AppPermissionStatus.granted,
    PermissionStatus.denied => AppPermissionStatus.denied,
    PermissionStatus.permanentlyDenied =>
      AppPermissionStatus.permanentlyDenied,
    PermissionStatus.restricted => AppPermissionStatus.restricted,
  };
}

@Riverpod(keepAlive: true)
PermissionStatusService permissionStatusService(Ref ref) =>
    DevicePermissionStatusService();
