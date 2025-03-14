import 'package:shared_preferences/shared_preferences.dart';

class PrefsUtil {
  static String keyAndroidSdk = 'keyAndroidSdk';

  // 华为应用市场
  static String keyHuaweiClientId = 'keyHuaweiClientId';
  static String keyHuaweiClientSecret = 'keyHuaweiClientSecret';

  // 荣耀应用市场
  static String keyHonorClientId = 'keyHonorClientId';
  static String keyHonorClientSecret = 'keyHonorClientSecret';

  // OPPO应用市场
  static String keyOppoClientId = 'keyOppoClientId';
  static String keyOppoClientSecret = 'keyOppoClientSecret';

  // VIVO应用市场
  static String keyVivoAccessKey = 'keyVivoAccessKey';
  static String keyVivoAccessSecret = 'keyVivoAccessSecret';

  // 小米应用市场
  static String keyXiaomiClientSecret = 'keyXiaomiClientSecret';
  static String keyXiaomiPublicPem = 'keyXiaomiPublicPem';

  factory PrefsUtil() => _instance;

  PrefsUtil._internal();

  static final PrefsUtil _instance = PrefsUtil._internal();

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }
}
