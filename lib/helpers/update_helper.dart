/*
 * Copyright (c) 2018-2023 Larry Aasen. All rights reserved.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simpler_updater/helpers/update_defs.dart';
import 'package:simpler_updater/helpers/update_system.dart';
import 'package:simpler_updater/helpers/version_parser.dart';
import 'package:url_launcher/url_launcher.dart';

part 'api/update_android_api.dart';
part 'api/update_ios_api.dart';

UpdaterHelper _sharedInstance = UpdaterHelper();

class UpdaterHelper {
  UpdaterHelper({
    this.debugDisplayAlways = false,
    this.debugDisplayOnce = false,
    this.willDisplayUpgrade,
    this.countryCode,
    this.languageCode,
    this.minAppVersion,
    http.Client? client,
    UpdateSystem? updateSystem,
    this.durationUntilAlertAgain = const Duration(days: 2),
  })  : client = client ?? http.Client(),
        updateSystem = updateSystem ?? UpdateSystem();

  final http.Client client;
  final String? countryCode;
  final String? languageCode;
  final Duration durationUntilAlertAgain;
  final UpdateSystem updateSystem;
  final bool _hasAlerted = false;
  final bool _isCriticalUpdate = false;
  bool debugDisplayAlways;
  bool debugDisplayOnce;
  String? minAppVersion;
  bool _initCalled = false;
  PackageInfo? _packageInfo;
  String? _installedVersion;
  String? _appStoreVersion;
  String? _appStoreListingURL;
  String? _releaseNotes;
  String? _updateAvailable;
  DateTime? _lastTimeAlerted;
  String? _userIgnoredVersion;
  Future<bool>? _futureInit;
  WillDisplayUpgradeCallback? willDisplayUpgrade;

  bool get evaluationReady => _evaluationReady;
  bool _evaluationReady = false;

  static UpdaterHelper get sharedInstance => _sharedInstance;

  String? get currentAppStoreListingURL => _appStoreListingURL;

  String? get currentAppStoreVersion => _appStoreVersion;

  String? get currentInstalledVersion => _installedVersion;

  String? get releaseNotes => _releaseNotes;

  void installPackageInfo({PackageInfo? packageInfo}) {
    _packageInfo = packageInfo;
    _initCalled = false;
  }

  void installAppStoreVersion(String version) => _appStoreVersion = version;

  void installAppStoreListingURL(String url) => _appStoreListingURL = url;

  Future<bool> initialize() async {
    if (_futureInit != null) return _futureInit!;

    _futureInit = Future(() async {
      if (_initCalled) {
        assert(false, 'Error.');
        return true;
      }
      _initCalled = true;
      await getSavedPref();
      _packageInfo ??= await PackageInfo.fromPlatform();
      _installedVersion = _packageInfo!.version;
      await updateVersionInfo();
      _evaluationReady = true;
      return true;
    });

    return _futureInit!;
  }

  Future<bool> updateVersionInfo() async {
    if (_packageInfo == null || _packageInfo!.packageName.isEmpty) {
      return false;
    }
    final country = countryCode ?? findCountryCode();
    final language = languageCode ?? findLanguageCode();

    if (updateSystem.isAndroid) {
      await getAndroidStoreVersion(country: country, language: language);
    } else if (updateSystem.isIOS) {
      final iTunes = _UpdateIosAPI();
      iTunes.client = client;
      final response = await iTunes.lookupByBundleId(_packageInfo!.packageName,
          country: country);

      if (response != null) {
        _appStoreVersion = iTunes.version(response);
        _appStoreListingURL = iTunes.trackViewUrl(response);
        _releaseNotes ??= iTunes.releaseNotes(response);
        final mav = iTunes.minAppVersion(response);
        if (mav != null) {
          minAppVersion = mav.toString();
        }
      }
    }

    return true;
  }

  Future<bool?> getAndroidStoreVersion({
    String? country,
    String? language,
  }) async {
    final id = _packageInfo!.packageName;
    final playStore = _UpdateAndroidAPI(client: client);
    final response =
        await playStore.lookupById(id, country: country, language: language);
    if (response != null) {
      _appStoreVersion ??= playStore.version(response);
      _appStoreListingURL ??=
          playStore.lookupURLById(id, language: language, country: country);
      _releaseNotes ??= playStore.releaseNotes(response);
    }

    return true;
  }

  bool verifyInit() {
    if (!_initCalled) {
      throw 'Error: initialize() not called. Must be called first.';
    }
    return true;
  }

  String appName() {
    verifyInit();
    return _packageInfo?.appName ?? '';
  }

  bool blocked() => belowMinAppVersion() || _isCriticalUpdate;

  bool isTooSoon() {
    if (_lastTimeAlerted == null) {
      return false;
    }

    final lastAlertedDuration = DateTime.now().difference(_lastTimeAlerted!);
    final rv = lastAlertedDuration < durationUntilAlertAgain;

    return rv;
  }

  bool shouldDisplayUpgrade() {
    final isBlocked = blocked();

    var rv = true;
    if (debugDisplayAlways || (debugDisplayOnce && !_hasAlerted)) {
      rv = true;
    } else if (!isUpdateAvailable()) {
      rv = false;
    } else if (isBlocked) {
      rv = true;
    } else if (isTooSoon() || alreadyIgnoredThisVersion()) {
      rv = false;
    }

    if (willDisplayUpgrade != null) {
      willDisplayUpgrade!(
        display: rv,
        minAppVersion: minAppVersion,
        installedVersion: _installedVersion,
        appStoreVersion: _appStoreVersion,
      );
    }

    return rv;
  }

  bool belowMinAppVersion() {
    var rv = false;
    if (minAppVersion != null) {
      try {
        final minVersion = VersionParser.parse(minAppVersion!);
        final installedVersion = VersionParser.parse(_installedVersion!);
        rv = installedVersion < minVersion;
      } catch (e) {
        if (kDebugMode) {
          print('----- Error Min Version $e');
        }
      }
    }
    return rv;
  }

  bool alreadyIgnoredThisVersion() =>
      _userIgnoredVersion != null && _userIgnoredVersion == _appStoreVersion;

  bool isUpdateAvailable() {
    if (_appStoreVersion == null || _installedVersion == null) {
      return false;
    }

    try {
      final appStoreVersion = VersionParser.parse(_appStoreVersion!);
      final installedVersion = VersionParser.parse(_installedVersion!);

      final available = appStoreVersion > installedVersion;
      _updateAvailable = available ? _appStoreVersion : null;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('----- Error isUpdateAvailable $e');
      }
    }
    final isAvailable = _updateAvailable != null;
    return isAvailable;
  }

  String? findCountryCode({BuildContext? context}) {
    Locale? locale;
    if (context != null) {
      locale = Localizations.maybeLocaleOf(context);
    } else {
      locale = PlatformDispatcher.instance.locale;
    }
    final code = locale == null || locale.countryCode == null
        ? 'US'
        : locale.countryCode;
    return code;
  }

  String? findLanguageCode({BuildContext? context}) {
    Locale? locale;
    if (context != null) {
      locale = Localizations.maybeLocaleOf(context);
    } else {
      locale = PlatformDispatcher.instance.locale;
    }
    final code = locale == null ? 'en' : locale.languageCode;
    return code;
  }

  static Future<void> clearSavedSettings() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove('userIgnoredVersion');
    await pref.remove('lastTimeAlerted');
  }

  Future<bool> saveIgnored() async {
    final pref = await SharedPreferences.getInstance();

    _userIgnoredVersion = _appStoreVersion;
    await pref.setString('userIgnoredVersion', _userIgnoredVersion ?? '');
    return true;
  }

  Future<bool> getSavedPref() async {
    final pref = await SharedPreferences.getInstance();
    final lastTimeAlerted = pref.getString('lastTimeAlerted');
    if (lastTimeAlerted != null) {
      _lastTimeAlerted = DateTime.parse(lastTimeAlerted);
    }

    _userIgnoredVersion = pref.getString('userIgnoredVersion');

    return true;
  }

  Future<void> openAppStoreV1() async {
    if (_appStoreListingURL == null || _appStoreListingURL!.isEmpty) {
      return;
    }

    if (await canLaunchUrl(Uri.parse(_appStoreListingURL!))) {
      try {
        await launchUrl(
          Uri.parse(_appStoreListingURL!),
          mode: updateSystem.isAndroid
              ? LaunchMode.externalNonBrowserApplication
              : LaunchMode.platformDefault,
        );
      } catch (e) {
        if (kDebugMode) {
          print('----- Error sendUserToAppStore $e');
        }
      }
    }
  }

  Future<void> openAppStoreV2() async {
    if (_appStoreListingURL == null || _appStoreListingURL!.isEmpty) {
      return;
    }

    final uri = Uri.parse(_appStoreListingURL!);
    if (Platform.isAndroid) {
      await launchUrl(
        Uri.parse('market://details?${uri.query}'),
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (await canLaunchUrl(Uri.parse(_appStoreListingURL!)) == true) {
        await launchUrl(
          Uri.parse(_appStoreListingURL!),
        );
      }
    }
  }
}
