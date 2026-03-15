import 'package:shared_preferences/shared_preferences.dart';

class WallboardSettings {
  static const _defaultSiteIdKey = 'default_wallboard_site_id';
  static const _defaultSiteNameKey = 'default_wallboard_site_name';
  static const _launchWallboardKey = 'launch_wallboard_on_start';

  static Future<void> saveDefaultStation({
    required int siteId,
    required String siteName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultSiteIdKey, siteId);
    await prefs.setString(_defaultSiteNameKey, siteName);
  }

  static Future<void> clearDefaultStation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_defaultSiteIdKey);
    await prefs.remove(_defaultSiteNameKey);
  }

  static Future<({int? siteId, String? siteName})> getDefaultStation() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      siteId: prefs.getInt(_defaultSiteIdKey),
      siteName: prefs.getString(_defaultSiteNameKey),
    );
  }

  static Future<void> setLaunchWallboardOnStart(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_launchWallboardKey, value);
  }

  static Future<bool> getLaunchWallboardOnStart() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_launchWallboardKey) ?? false;
  }
}
