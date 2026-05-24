import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateService {
  ForceUpdateService({
    FirebaseRemoteConfig? remoteConfig,
    PackageInfo? packageInfo,
  })  : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance,
        _packageInfo = packageInfo;

  static const String minimumVersionKey = 'minimum_version';

  /// TODO: App Store の実URLに差し替えてください
  static const String appStoreUrl =
      'https://apps.apple.com/jp/app/salonnote/id1234567890';

  final FirebaseRemoteConfig _remoteConfig;
  final PackageInfo? _packageInfo;

  Future<bool> shouldForceUpdate() async {
    if (!Platform.isIOS) {
      return false;
    }

    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      await _remoteConfig.setDefaults(
        const {
          minimumVersionKey: '0.0.0',
        },
      );

      await _remoteConfig.fetchAndActivate();

      final minimumVersion = _remoteConfig.getString(minimumVersionKey);
      final packageInfo = _packageInfo ?? await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      return isVersionLower(currentVersion, minimumVersion);
    } catch (_) {
      // エラー時は通常起動
      return false;
    }
  }

  bool isVersionLower(String currentVersion, String minimumVersion) {
    final currentParts = _normalizeVersion(currentVersion);
    final minimumParts = _normalizeVersion(minimumVersion);
    final maxLength = currentParts.length > minimumParts.length
        ? currentParts.length
        : minimumParts.length;

    for (var i = 0; i < maxLength; i++) {
      final current = i < currentParts.length ? currentParts[i] : 0;
      final minimum = i < minimumParts.length ? minimumParts[i] : 0;

      if (current < minimum) {
        return true;
      }
      if (current > minimum) {
        return false;
      }
    }

    return false;
  }

  List<int> _normalizeVersion(String version) {
    return version
        .split('.')
        .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }

  Future<void> openStore() async {
    final uri = Uri.parse(appStoreUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
