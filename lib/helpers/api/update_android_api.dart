/*
 * Copyright (c) 2021 William Kwabla. All rights reserved.
 */

part of '../update_helper.dart';

class _UpdateAndroidAPI {
  _UpdateAndroidAPI({http.Client? client}) : client = client ?? http.Client();

  final String playStorePrefixURL = 'play.google.com';

  final http.Client? client;

  Future<dom.Document?> lookupById(String id,
      {String? country = 'US',
      String? language = 'en',
      bool useCacheBuster = true}) async {
    assert(id.isNotEmpty);
    if (id.isEmpty) return null;

    final url = lookupURLById(id,
        country: country, language: language, useCacheBuster: useCacheBuster)!;

    try {
      final response = await client!.get(Uri.parse(url));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decodedResults = _decodeResults(response.body);

      return decodedResults;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('upgrader: lookupById exception: $e');
      }
      return null;
    }
  }

  String? lookupURLById(String id,
      {String? country = 'US',
      String? language = 'en',
      bool useCacheBuster = true}) {
    assert(id.isNotEmpty);
    if (id.isEmpty) return null;

    Map<String, dynamic> parameters = {'id': id};
    if (country != null && country.isNotEmpty) {
      parameters['gl'] = country;
    }
    if (language != null && language.isNotEmpty) {
      parameters['hl'] = language;
    }
    if (useCacheBuster) {
      parameters['_cb'] = DateTime.now().microsecondsSinceEpoch.toString();
    }
    final url = Uri.https(playStorePrefixURL, '/store/apps/details', parameters)
        .toString();

    return url;
  }

  dom.Document? _decodeResults(String jsonResponse) {
    if (jsonResponse.isNotEmpty) {
      final decodedResults = parse(jsonResponse);
      return decodedResults;
    }
    return null;
  }
}

extension PlayStoreResults on _UpdateAndroidAPI {
  static RegExp releaseNotesSpan = RegExp(r'>(.*?)</span>');

  String? description(dom.Document response) {
    try {
      final sectionElements = response.getElementsByClassName('W4P4ne');
      final descriptionElement = sectionElements[0];
      final description = descriptionElement
          .querySelector('.PHBdkd')
          ?.querySelector('.DWPxHb')
          ?.text;
      return description;
    } catch (e) {
      return redesignedDescription(response);
    }
  }

  String? redesignedDescription(dom.Document response) {
    try {
      final sectionElements = response.getElementsByClassName('bARER');
      final descriptionElement = sectionElements.last;
      final description = descriptionElement.text;
      return description;
    } catch (e) {
      if (kDebugMode) {
        print('upgrader: PlayStoreResults.redesignedDescription exception: $e');
      }
    }
    return null;
  }

  String? releaseNotes(dom.Document response) {
    try {
      final sectionElements = response.getElementsByClassName('W4P4ne');
      final releaseNotesElement = sectionElements.firstWhere(
          (elm) => elm.querySelector('.wSaTQd')!.text == 'What\'s New',
          orElse: () => sectionElements[0]);

      final rawReleaseNotes = releaseNotesElement
          .querySelector('.PHBdkd')
          ?.querySelector('.DWPxHb');
      final releaseNotes = rawReleaseNotes == null
          ? null
          : multilineReleaseNotes(rawReleaseNotes);

      return releaseNotes;
    } catch (e) {
      return redesignedReleaseNotes(response);
    }
  }

  String? redesignedReleaseNotes(dom.Document response) {
    try {
      final sectionElements =
          response.querySelectorAll('[itemprop="description"]');

      final rawReleaseNotes = sectionElements.last;
      final releaseNotes = multilineReleaseNotes(rawReleaseNotes);
      return releaseNotes;
    } catch (e) {
      if (kDebugMode) {
        print(
            'upgrader: PlayStoreResults.redesignedReleaseNotes exception: $e');
      }
    }
    return null;
  }

  String? multilineReleaseNotes(dom.Element rawReleaseNotes) {
    final innerHtml = rawReleaseNotes.innerHtml;
    String? releaseNotes = innerHtml;

    if (releaseNotesSpan.hasMatch(innerHtml)) {
      releaseNotes = releaseNotesSpan.firstMatch(innerHtml)!.group(1);
    }

    releaseNotes = releaseNotes!.replaceAll('<br>', '\n');

    return releaseNotes;
  }

  String? version(dom.Document response) {
    String? version;
    try {
      final additionalInfoElements = response.getElementsByClassName('hAyfc');
      final versionElement = additionalInfoElements.firstWhere(
        (elm) => elm.querySelector('.BgcNfc')!.text == 'Current Version',
      );
      final storeVersion = versionElement.querySelector('.htlgb')!.text;

      version = VersionParser.parse(storeVersion).toString();
    } catch (e) {
      return redesignedVersion(response);
    }

    return version;
  }

  String? redesignedVersion(dom.Document response) {
    String? version;
    try {
      const patternName = ",\"name\":\"";
      const patternVersion = ",[[[\"";
      const patternCallback = "AF_initDataCallback";
      const patternEndOfString = "\"";

      final scripts = response.getElementsByTagName("script");
      final infoElements =
          scripts.where((element) => element.text.contains(patternName));
      final additionalInfoElements =
          scripts.where((element) => element.text.contains(patternCallback));
      final additionalInfoElementsFiltered = additionalInfoElements
          .where((element) => element.text.contains(patternVersion));

      final nameElement = infoElements.first.text;
      final storeNameStartIndex =
          nameElement.indexOf(patternName) + patternName.length;
      final storeNameEndIndex = storeNameStartIndex +
          nameElement
              .substring(storeNameStartIndex)
              .indexOf(patternEndOfString);
      final storeName =
          nameElement.substring(storeNameStartIndex, storeNameEndIndex);

      final versionElement = additionalInfoElementsFiltered
          .where((element) => element.text.contains("\"$storeName\""))
          .first
          .text;
      final storeVersionStartIndex =
          versionElement.lastIndexOf(patternVersion) + patternVersion.length;
      final storeVersionEndIndex = storeVersionStartIndex +
          versionElement
              .substring(storeVersionStartIndex)
              .indexOf(patternEndOfString);
      final storeVersion = versionElement.substring(
          storeVersionStartIndex, storeVersionEndIndex);

      version = VersionParser.parse(storeVersion).toString();
    } catch (e) {
      if (kDebugMode) {
        print('upgrader: PlayStoreResults.redesignedVersion exception: $e');
      }
    }

    return version;
  }
}
