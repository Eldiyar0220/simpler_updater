// Copyright (c) 2021, Matthew Barbour. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

class VersionParser implements Comparable<VersionParser> {
  VersionParser(this.major, this.minor, this.patch,
      {List<String> preRelease = const <String>[], this.build = ''})
      : _preRelease = preRelease {
    for (var i = 0; i < _preRelease.length; i++) {
      if (_preRelease[i].toString().trim().isEmpty) {
        throw ArgumentError('preRelease segments must not be empty');
      }
      // Just in case
      _preRelease[i] = _preRelease[i].toString();
      if (!_preReleaseRegex.hasMatch(_preRelease[i])) {
        throw const FormatException(
            'preRelease segments must only contain [0-9A-Za-z-]');
      }
    }
    if (build.isNotEmpty && !_buildRegex.hasMatch(build)) {
      throw const FormatException('build must only contain [0-9A-Za-z-.]');
    }

    if (major < 0 || minor < 0 || patch < 0) {
      throw ArgumentError('Version numbers must be greater than 0');
    }
  }
  static final RegExp _versionRegex =
      RegExp(r'^([\d.]+)(-([0-9A-Za-z\-.]+))?(\+([0-9A-Za-z\-.]+))?$');
  static final RegExp _buildRegex = RegExp(r'^[0-9A-Za-z\-.]+$');
  static final RegExp _preReleaseRegex = RegExp(r'^[0-9A-Za-z\-]+$');

  final int major;

  final int minor;

  final int patch;

  final String build;

  final List<String> _preRelease;

  bool get isPreRelease => _preRelease.isNotEmpty;

  @override
  int get hashCode => toString().hashCode;

  List<String> get preRelease => List<String>.from(_preRelease);

  bool operator <(dynamic o) => o is VersionParser && _compare(this, o) < 0;

  bool operator <=(dynamic o) => o is VersionParser && _compare(this, o) <= 0;

  @override
  bool operator ==(dynamic o) => o is VersionParser && _compare(this, o) == 0;

  bool operator >(dynamic o) => o is VersionParser && _compare(this, o) > 0;

  bool operator >=(dynamic o) => o is VersionParser && _compare(this, o) >= 0;

  @override
  int compareTo(VersionParser? other) {
    if (other == null) {
      throw ArgumentError.notNull('other');
    }

    return _compare(this, other);
  }

  VersionParser incrementMajor() => VersionParser(major + 1, 0, 0);

  VersionParser incrementMinor() => VersionParser(major, minor + 1, 0);

  VersionParser incrementPatch() => VersionParser(major, minor, patch + 1);

  VersionParser incrementPreRelease() {
    if (!isPreRelease) {
      throw Exception(
          'Cannot increment pre-release on a non-pre-release [Version]');
    }
    final newPreRelease = preRelease;

    var found = false;
    for (var i = newPreRelease.length - 1; i >= 0; i--) {
      final segment = newPreRelease[i];
      if (VersionParser._isNumeric(segment)) {
        var intVal = int.parse(segment);
        intVal++;
        newPreRelease[i] = intVal.toString();
        found = true;
        break;
      }
    }
    if (!found) {
      newPreRelease.add('1');
    }

    return VersionParser(major, minor, patch, preRelease: newPreRelease);
  }

  @override
  String toString() {
    final output = StringBuffer('$major.$minor.$patch');
    if (_preRelease.isNotEmpty) {
      output.write("-${_preRelease.join('.')}");
    }
    if (build.trim().isNotEmpty) {
      output.write('+${build.trim()}');
    }
    return output.toString();
  }

  static VersionParser parse(String versionString) {
    if (versionString.trim().isEmpty) {
      throw const FormatException('Cannot parse empty string into version');
    }
    if (!_versionRegex.hasMatch(versionString)) {
      throw const FormatException('Not a properly formatted version string');
    }
    final Match m = _versionRegex.firstMatch(versionString)!;
    final version = m.group(1)!;

    int? major, minor, patch;
    final parts = version.split('.');
    major = int.parse(parts[0]);
    if (parts.length > 1) {
      minor = int.parse(parts[1]);
      if (parts.length > 2) {
        patch = int.parse(parts[2]);
      }
    }

    final preReleaseString = m.group(3) ?? '';
    var preReleaseList = <String>[];
    if (preReleaseString.trim().isNotEmpty) {
      preReleaseList = preReleaseString.split('.');
    }
    final build = m.group(5) ?? '';

    return VersionParser(major, minor ?? 0, patch ?? 0,
        build: build, preRelease: preReleaseList);
  }

  static int _compare(VersionParser? a, VersionParser? b) {
    if (a == null) {
      throw ArgumentError.notNull('a');
    }

    if (b == null) {
      throw ArgumentError.notNull('b');
    }

    if (a.major > b.major) return 1;
    if (a.major < b.major) return -1;

    if (a.minor > b.minor) return 1;
    if (a.minor < b.minor) return -1;

    if (a.patch > b.patch) return 1;
    if (a.patch < b.patch) return -1;

    if (a.preRelease.isEmpty) {
      if (b.preRelease.isEmpty) {
        return 0;
      } else {
        return 1;
      }
    } else if (b.preRelease.isEmpty) {
      return -1;
    } else {
      var preReleaseMax = a.preRelease.length;
      if (b.preRelease.length > a.preRelease.length) {
        preReleaseMax = b.preRelease.length;
      }

      for (var i = 0; i < preReleaseMax; i++) {
        if (b.preRelease.length <= i) {
          return 1;
        } else if (a.preRelease.length <= i) {
          return -1;
        }

        if (a.preRelease[i] == b.preRelease[i]) continue;

        final aNumeric = _isNumeric(a.preRelease[i]);
        final bNumeric = _isNumeric(b.preRelease[i]);

        if (aNumeric && bNumeric) {
          final aNumber = double.parse(a.preRelease[i]);
          final bNumber = double.parse(b.preRelease[i]);
          if (aNumber > bNumber) {
            return 1;
          } else {
            return -1;
          }
        } else if (bNumeric) {
          return 1;
        } else if (aNumeric) {
          return -1;
        } else {
          return a.preRelease[i].compareTo(b.preRelease[i]);
        }
      }
    }
    return 0;
  }

  static bool _isNumeric(String? s) {
    if (s == null) {
      return false;
    }
    return double.tryParse(s) != null;
  }
}
