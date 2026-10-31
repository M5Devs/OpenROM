// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

/// A small, dependency-free SemVer 2.0.0 value type.
///
/// OpenROM deliberately avoids pulling in `pub_semver` (a dev-only transitive
/// dependency) so the plugin subsystem stays self-contained. Only the parts
/// needed for compatibility checks and ordering are implemented: full
/// `MAJOR.MINOR.PATCH`, optional pre-release and build metadata.
class SemVer implements Comparable<SemVer> {
  final int major;
  final int minor;
  final int patch;

  /// Dot-separated pre-release identifiers (e.g. `["beta", "1"]`), empty for a
  /// normal release. Pre-releases sort *below* the equivalent release.
  final List<String> preRelease;

  /// Dot-separated build metadata. Ignored for precedence, per SemVer §10.
  final List<String> build;

  const SemVer(
    this.major,
    this.minor,
    this.patch, {
    this.preRelease = const [],
    this.build = const [],
  });

  /// Strict SemVer 2.0.0 regex (official expression).
  static final RegExp _pattern = RegExp(
    r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
    r'(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)'
    r'(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?'
    r'(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$',
  );

  /// Parses a strict SemVer string, or returns `null` when [input] is not a
  /// valid version. Leading/trailing whitespace is tolerated; a leading `v`
  /// is **not** (call [tryParseLoose] for tolerant parsing).
  static SemVer? tryParse(String? input) {
    if (input == null) return null;
    final value = input.trim();
    final match = _pattern.firstMatch(value);
    if (match == null) return null;
    return SemVer(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      preRelease: _splitIdentifiers(match.group(4)),
      build: _splitIdentifiers(match.group(5)),
    );
  }

  /// Tolerant parse used for comparing against a host core version that may be
  /// formatted loosely (e.g. `v3.9.0`, `3.9`, `3.9.0-rc.1`). Returns `null`
  /// when nothing version-like can be extracted.
  static SemVer? tryParseLoose(String? input) {
    if (input == null) return null;
    var value = input.trim();
    if (value.startsWith('v') || value.startsWith('V')) {
      value = value.substring(1);
    }
    final direct = tryParse(value);
    if (direct != null) return direct;

    // Pad a truncated "3.9" style version to "3.9.0".
    final truncated = RegExp(r'^(\d+)\.(\d+)$').firstMatch(value);
    if (truncated != null) {
      return SemVer(
        int.parse(truncated.group(1)!),
        int.parse(truncated.group(2)!),
        0,
      );
    }
    return null;
  }

  static List<String> _splitIdentifiers(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return raw.split('.');
  }

  /// True when this version is a pre-release (has pre-release identifiers).
  bool get isPreRelease => preRelease.isNotEmpty;

  /// SemVer precedence comparison (§11). Build metadata is ignored.
  @override
  int compareTo(SemVer other) {
    final majorCmp = major.compareTo(other.major);
    if (majorCmp != 0) return majorCmp;
    final minorCmp = minor.compareTo(other.minor);
    if (minorCmp != 0) return minorCmp;
    final patchCmp = patch.compareTo(other.patch);
    if (patchCmp != 0) return patchCmp;

    // A pre-release is lower precedence than a normal release.
    if (preRelease.isEmpty && other.preRelease.isEmpty) return 0;
    if (preRelease.isEmpty) return 1;
    if (other.preRelease.isEmpty) return -1;

    final length = preRelease.length < other.preRelease.length
        ? preRelease.length
        : other.preRelease.length;
    for (var i = 0; i < length; i++) {
      final cmp =
          _comparePreReleaseIdentifier(preRelease[i], other.preRelease[i]);
      if (cmp != 0) return cmp;
    }
    return preRelease.length.compareTo(other.preRelease.length);
  }

  static int _comparePreReleaseIdentifier(String a, String b) {
    final aNumeric = int.tryParse(a);
    final bNumeric = int.tryParse(b);
    if (aNumeric != null && bNumeric != null)
      return aNumeric.compareTo(bNumeric);
    // Numeric identifiers always have lower precedence than alphanumeric ones.
    if (aNumeric != null) return -1;
    if (bNumeric != null) return 1;
    return a.compareTo(b);
  }

  bool operator <(SemVer other) => compareTo(other) < 0;
  bool operator >(SemVer other) => compareTo(other) > 0;
  bool operator <=(SemVer other) => compareTo(other) <= 0;
  bool operator >=(SemVer other) => compareTo(other) >= 0;

  /// True when this version is a strict upgrade over [other] **or** equal.
  /// Ignores pre-release for the common "is this plugin compatible" check.
  bool isAtLeast(SemVer other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is SemVer &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch &&
      _listEquals(other.preRelease, preRelease) &&
      _listEquals(other.build, build);

  @override
  int get hashCode => Object.hash(
        major,
        minor,
        patch,
        Object.hashAll(preRelease),
        Object.hashAll(build),
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    final buffer = StringBuffer('$major.$minor.$patch');
    if (preRelease.isNotEmpty) buffer.write('-${preRelease.join('.')}');
    if (build.isNotEmpty) buffer.write('+${build.join('.')}');
    return buffer.toString();
  }
}
