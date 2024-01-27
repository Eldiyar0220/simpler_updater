// ignore_for_file: avoid_classes_with_only_static_members

import 'package:package_info_plus/package_info_plus.dart';
import 'package:simpler_updater/helpers/update_defs.dart';
import 'package:simpler_updater/helpers/update_helper.dart';
import 'package:simpler_updater/helpers/update_model.dart';

class SimplerUpdater {
  static Future<void> checkUpdateApp({required ShowDialog showDialog}) async {
    final upgrade = UpdaterHelper.sharedInstance;
    await upgrade.initialize();
    final shouldDisplay = upgrade.shouldDisplayUpgrade();
    if (shouldDisplay) {
      final updateInfo = UpdateModel(
        currentAppStoreListingURL: upgrade.currentAppStoreListingURL,
        currentAppStoreVersion: upgrade.currentAppStoreVersion,
        currentInstalledVersion: upgrade.currentInstalledVersion,
        releaseNotes: upgrade.releaseNotes,
        appName: upgrade.appName(),
        openAppStoreOnTap1: () async => await upgrade.openAppStoreV1(),
        openAppStoreOnTap2: () async => await upgrade.openAppStoreV2(),
        ignoreOnTap: () async => await upgrade.saveIgnored(),
      );
      showDialog(updateInfo);
    }
  }

  static Future<PackageInfo> get packageInfo async =>
      await PackageInfo.fromPlatform();

  static Future<void> cleanSettings() async {
    await UpdaterHelper.clearSavedSettings();
  }
}
