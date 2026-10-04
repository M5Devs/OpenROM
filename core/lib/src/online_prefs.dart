// OpenROM — Online feature preference keys
// M5 Dev | GPL v3

/// SharedPreferences keys for online features.
/// All default to false (opt-in).
abstract class OnlinePrefs {
  // Auto-update check
  static const String autoUpdateEnabled = 'online_auto_update_enabled';

  // RetroAchievements
  static const String raEnabled         = 'online_ra_enabled';
  static const String raApiKey          = 'online_ra_api_key';
  static const String raUsername        = 'online_ra_username';
}
