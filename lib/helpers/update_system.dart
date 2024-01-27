// import "package:os_detect/os_detect.dart" as platform;
import 'dart:io';

import 'package:flutter/foundation.dart';

class UpdateSystem {
  String? _current;

  String get current {
    if (_current != null) return _current!;
    _current = isAndroid
        ? 'android'
        : isFuchsia
            ? 'fuchsia'
            : isIOS
                ? 'ios'
                : isLinux
                    ? 'linux'
                    : isMacOS
                        ? 'macos'
                        : isWeb
                            ? 'web'
                            : isWindows
                                ? 'windows'
                                : '';
    return _current ?? '';
  }

  bool get isAndroid {
    try {
      return Platform.isAndroid;
    } catch (e) {
      return false;
    }
  }

  bool get isFuchsia {
    try {
      return Platform.isFuchsia;
    } catch (e) {
      return false;
    }
  }

  bool get isIOS {
    try {
      return Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  bool get isLinux {
    try {
      return Platform.isLinux;
    } catch (e) {
      return false;
    }
  }

  bool get isMacOS {
    try {
      return Platform.isMacOS;
    } catch (e) {
      return false;
    }
  }

  bool get isWeb {
    try {
      return kIsWeb;
    } catch (e) {
      return false;
    }
  }

  bool get isWindows {
    try {
      return Platform.isWindows;
    } catch (e) {
      return false;
    }
  }
}
