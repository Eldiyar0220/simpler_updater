/*
 * Copyright (c) 2018-2022 Larry Aasen. All rights reserved.
 */

part of '../update_helper.dart';

class _UpdateIosAPI {
  final String lookupPrefixURL = 'https://itunes.apple.com/lookup';

  http.Client? client = http.Client();

  bool debugLogging = false;

  Future<Map?> lookupByBundleId(String bundleId,
      {String? country = 'US', bool useCacheBuster = true}) async {
    assert(bundleId.isNotEmpty);
    if (bundleId.isEmpty) {
      return null;
    }

    final url = lookupURLByBundleId(bundleId,
        country: country ??= '', useCacheBuster: useCacheBuster)!;
    if (debugLogging) {
      print('upgrader: download: $url');
    }

    try {
      final response = await client!.get(Uri.parse(url));
      if (debugLogging) {
        print('upgrader: response statusCode: ${response.statusCode}');
      }

      final decodedResults = _decodeResults(response.body);
      return decodedResults;
    } catch (e) {
      if (debugLogging) {
        print('upgrader: lookupByBundleId exception: $e');
      }
      return null;
    }
  }

  Future<Map?> lookupById(String id,
      {String country = 'US', bool useCacheBuster = true}) async {
    if (id.isEmpty) {
      return null;
    }

    final url =
        lookupURLById(id, country: country, useCacheBuster: useCacheBuster)!;
    if (debugLogging) {
      print('upgrader: download: $url');
    }
    try {
      final response = await client!.get(Uri.parse(url));
      final decodedResults = _decodeResults(response.body);
      return decodedResults;
    } catch (e) {
      if (debugLogging) {
        print('upgrader: lookupById exception: $e');
      }
      return null;
    }
  }

  String? lookupURLByBundleId(String bundleId,
      {String country = 'US', bool useCacheBuster = true}) {
    if (bundleId.isEmpty) {
      return null;
    }

    return lookupURLByQSP(
        {'bundleId': bundleId, 'country': country.toUpperCase()},
        useCacheBuster: useCacheBuster);
  }

  String? lookupURLById(String id,
      {String country = 'US', bool useCacheBuster = true}) {
    if (id.isEmpty) {
      return null;
    }

    return lookupURLByQSP({'id': id, 'country': country.toUpperCase()},
        useCacheBuster: useCacheBuster);
  }

  String? lookupURLByQSP(Map<String, String?> qsp,
      {bool useCacheBuster = true}) {
    if (qsp.isEmpty) {
      return null;
    }

    final parameters = <String>[];
    qsp.forEach((key, value) => parameters.add('$key=$value'));
    if (useCacheBuster) {
      parameters.add('_cb=${DateTime.now().microsecondsSinceEpoch.toString()}');
    }
    final finalParameters = parameters.join('&');

    return '$lookupPrefixURL?$finalParameters';
  }

  Map? _decodeResults(String jsonResponse) {
    if (jsonResponse.isNotEmpty) {
      final decodedResults = json.decode(jsonResponse);
      if (decodedResults is Map) {
        final resultCount = decodedResults['resultCount'];
        if (resultCount == 0) {
          if (debugLogging) {
            print(
                'upgrader.ITunesSearchAPI: results are empty: $decodedResults');
          }
        }
        return decodedResults;
      }
    }
    return null;
  }
}

extension ITunesResults on _UpdateIosAPI {
  String? bundleId(Map response) {
    String? value;
    try {
      value = response['results'][0]['bundleId'];
    } catch (e) {
      if (debugLogging) {
        print('upgrader.ITunesResults.bundleId: $e');
      }
    }
    return value;
  }

  String? currency(Map response) {
    String? value;
    try {
      value = response['results'][0]['currency'];
    } catch (e) {
      if (debugLogging) {
        print('upgrader.ITunesResults.currency: $e');
      }
    }
    return value;
  }

  String? description(Map response) {
    String? value;
    try {
      value = response['results'][0]['description'];
    } catch (e) {
      if (debugLogging) {
        print('upgrader.ITunesResults.description: $e');
      }
    }
    return value;
  }

  VersionParser? minAppVersion(Map response, {String tagName = 'mav'}) {
    VersionParser? version;
    try {
      final desc = description(response);
      if (desc != null) {
        var regExpSource = r'\[\:tagName\:[\s]*(?<version>[^\s]+)[\s]*\]';
        regExpSource = regExpSource.replaceAll(RegExp('tagName'), tagName);
        final regExp = RegExp(regExpSource, caseSensitive: false);
        final match = regExp.firstMatch(desc);
        final mav = match?.namedGroup('version');

        if (mav != null) {
          try {
            // Verify version string using class Version
            version = VersionParser.parse(mav);
          } on Exception catch (e) {
            if (debugLogging) {
              print(
                  'upgrader: ITunesResults.minAppVersion: $tagName error: $e');
            }
          }
        }
      }
    } on Exception catch (e) {
      if (debugLogging) {
        print('upgrader.ITunesResults.minAppVersion : $e');
      }
    }
    return version;
  }

  String? releaseNotes(Map response) {
    String? value;
    try {
      value = response['results'][0]['releaseNotes'];
    } catch (e) {
      if (debugLogging) {
        print('upgrader.ITunesResults.releaseNotes: $e');
      }
    }
    return value;
  }

  String? trackViewUrl(Map response) {
    String? value;
    try {
      value = response['results'][0]['trackViewUrl'];
    } catch (e) {
      if (debugLogging) {
        print('upgrader.ITunesResults.trackViewUrl: $e');
      }
    }
    return value;
  }

  String? version(Map response) {
    String? value;
    try {
      value = response['results'][0]['version'];
    } catch (e) {
      if (debugLogging) {
        print('upgrader.ITunesResults.version: $e');
      }
    }
    return value;
  }
}
