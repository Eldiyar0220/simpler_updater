import 'package:simpler_updater/helpers/update_model.dart';

typedef BoolCallback = bool Function();

typedef VoidBoolCallback = void Function(bool value);

typedef UpgraderEvaluateNeed = bool;

typedef WillDisplayUpgradeCallback = void Function({
  required bool display,
  String? minAppVersion,
  String? installedVersion,
  String? appStoreVersion,
});

typedef ShowDialog = void Function(UpdateModel updateInfo);
