import 'dart:async';
import 'dart:io';

import 'package:market_upload/utils/log_util.dart';
import 'package:market_upload/utils/prefs_util.dart';
import 'package:parser_apk_info/parser_apk_info.dart';
import 'package:path/path.dart';

class ApkUtil {
  factory ApkUtil() => _instance;

  ApkUtil._internal();

  static final ApkUtil _instance = ApkUtil._internal();

  String _getAaptApp() {
    String androidSdk = 'C:/Users/Administrator/AppData/Local/Android/Sdk';
    if (Platform.isMacOS) {
      androidSdk = '/Users/cechds/Library/Android/sdk';
    }

    try {
      final String? androidHome =
          PrefsUtil().getString(PrefsUtil.keyAndroidSdk) ??
          Platform.environment['ANDROID_SDK_ROOT'] ??
          Platform.environment['ANDROID_HOME'];

      androidSdk =
          Directory(
            join(androidHome ?? androidSdk, 'build-tools'),
          ).listSync().last.path;
    } catch (e) {
      LogUtil.logger.e(e.toString());
    }

    return androidSdk;
  }

  Future<ApkInfo?> getInfo(String path) async {
    final apkFile = File(path);
    if (await apkFile.exists()) {
      final parserApkInfo = ParserApkInfoAapt(DisableLogger());
      final aaptDirPath = _getAaptApp();
      final aaptPath = await AaptUtil.getAaptApp(aaptDirPath);
      if (aaptPath == null) {
        LogUtil.logger.e('Android SDK目录配置异常，没有找到aapt2，可在设置里进行配置!');
        return null;
      }
      await parserApkInfo.aaptInit(aaptPath);
      return await parserApkInfo.parseFile(apkFile);
    }
    return null;
  }
}
