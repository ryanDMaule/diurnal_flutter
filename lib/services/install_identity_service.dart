import 'package:flutter/services.dart';

abstract interface class InstallIdentityService {
  Future<bool> isFreshInstallation();
}

class PlatformInstallIdentityService implements InstallIdentityService {
  const PlatformInstallIdentityService();

  static const _channel = MethodChannel(
    'com.mauleapplications.diurnus/install',
  );

  @override
  Future<bool> isFreshInstallation() async {
    try {
      return await _channel.invokeMethod<bool>('isFreshInstallation') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
