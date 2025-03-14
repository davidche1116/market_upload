import 'package:market_upload/utils/prefs_util.dart';

class ConstantUtil {
  static const String appTitle = '应用市场上传工具';
  static const int httpStatusOk = 200;

  static String get honorClientId =>
      PrefsUtil().getString(PrefsUtil.keyHonorClientId) ?? '';
  static String get honorClientSecret =>
      PrefsUtil().getString(PrefsUtil.keyHonorClientSecret) ?? '';

  static String get huaweiClientId =>
      PrefsUtil().getString(PrefsUtil.keyHuaweiClientId) ?? '';
  static String get huaweiClientSecret =>
      PrefsUtil().getString(PrefsUtil.keyHuaweiClientSecret) ?? '';

  static String get oppoClientId =>
      PrefsUtil().getString(PrefsUtil.keyOppoClientId) ?? '';
  static String get oppoClientSecret =>
      PrefsUtil().getString(PrefsUtil.keyOppoClientSecret) ?? '';

  static String get vivoAccessKey =>
      PrefsUtil().getString(PrefsUtil.keyVivoAccessKey) ?? '';
  static String get vivoAccessSecret =>
      PrefsUtil().getString(PrefsUtil.keyVivoAccessSecret) ?? '';

  static String get xiaomiClientSecret =>
      PrefsUtil().getString(PrefsUtil.keyXiaomiClientSecret) ?? '';
  static String get xiaomiPublicPem =>
      PrefsUtil().getString(PrefsUtil.keyXiaomiPublicPem) ?? '';
}
