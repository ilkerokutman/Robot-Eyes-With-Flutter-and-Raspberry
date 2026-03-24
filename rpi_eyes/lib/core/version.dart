/// Application version constants following semantic versioning
class AppVersion {
  AppVersion._();

  /// Major version - incremented for incompatible API changes
  static const int major = 2;

  /// Minor version - incremented for backwards-compatible functionality additions
  static const int minor = 2;

  /// Patch version - incremented for backwards-compatible bug fixes
  static const int patch = 2;

  /// Full semantic version string (major.minor.patch)
  static const String full = '$major.$minor.$patch';

  /// Build metadata (optional, e.g., '+build.123')
  static const String buildMetadata = '';

  /// Complete version with build metadata if present
  static String get complete =>
      buildMetadata.isEmpty ? full : '$full+$buildMetadata';

  /// Version name for display
  static const String name = 'Robot Eyes';

  /// Version display string
  static String get display => '$name v$complete';
}
