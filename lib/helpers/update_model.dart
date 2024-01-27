final class UpdateModel {
  UpdateModel({
    this.currentAppStoreListingURL,
    this.currentAppStoreVersion,
    this.currentInstalledVersion,
    this.releaseNotes,
    required this.appName,
    required this.ignoreOnTap,
    required this.openAppStoreOnTap1,
    required this.openAppStoreOnTap2,
  });
  final String? currentAppStoreListingURL;
  final String? currentAppStoreVersion;
  final String? currentInstalledVersion;
  final String? releaseNotes;
  final String appName;
  final Function() ignoreOnTap;
  final Function() openAppStoreOnTap1;
  final Function() openAppStoreOnTap2;

  @override
  String toString() {
    return 'UpdateModel(currentAppStoreListingURL: $currentAppStoreListingURL, currentAppStoreVersion: $currentAppStoreVersion, currentInstalledVersion: $currentInstalledVersion, releaseNotes: $releaseNotes, appName: $appName, ignoreOnTap: $ignoreOnTap, openAppStoreOnTap1: $openAppStoreOnTap1, openAppStoreOnTap2: $openAppStoreOnTap2)';
  }
}
