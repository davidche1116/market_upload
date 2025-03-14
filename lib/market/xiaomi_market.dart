import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:market_upload/utils/constant_util.dart';
import 'package:market_upload/utils/crypto_util.dart';
import 'package:market_upload/utils/dio_util.dart';
import 'package:market_upload/utils/log_util.dart';
import 'package:parser_apk_info/model/apk_info.dart';

/// 官方API文档：https://dev.mi.com/distribute/doc/details?pId=1134
class XiaomiMarket {
  static const String domain = 'https://api.developer.xiaomi.com/devupload';

  static Map<String, dynamic> appInfo = {};

  static Future<bool> submit(
    ApkInfo info32,
    ApkInfo info64,
    String updateContent,
    DateTime? datetime,
  ) async {
    LogUtil.logger.i('小米开始提交');

    // 查询信息
    bool ret = await getAppInfo(info64);
    if (ret) {
      // 应用推送接口
      ret = await appSubmit(info32, info64, updateContent, datetime);
    }

    LogUtil.logger.i('小米提交完成。结果为$ret');
    return ret;
  }

  static Future<bool> getAppInfo(ApkInfo info64) async {
    LogUtil.logger.i('小米开始获取APP信息');
    bool ret = false;

    try {
      Map<String, dynamic> requestDataMap = {
        'packageName': info64.applicationId,
        'userName': 'huawei@cecdat.com',
      };
      String requestData = jsonEncode(requestDataMap);

      Map<String, dynamic> sigMap = {
        'sig': [
          {'name': 'RequestData', 'hash': CryptoUtil.getMd5(requestData)},
        ],
        'password': ConstantUtil.xiaomiClientSecret,
      };
      String sig = await CryptoUtil.encodeString(jsonEncode(sigMap));

      Response response = await DioUtil.dio.post(
        '$domain/dev/query',
        queryParameters: {'RequestData': requestData, 'SIG': sig},
      );

      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['result'] == 0) {
          ret = true;
          appInfo = response.data['packageInfo'];
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('小米完成获取APP信息，结果为$ret');
    return ret;
  }

  static Future<bool> appSubmit(
    ApkInfo info32,
    ApkInfo info64,
    String newFeatures,
    DateTime? datetime,
  ) async {
    LogUtil.logger.i('小米开始提交发布');
    bool ret = false;

    try {
      Map<String, dynamic> appInfoMap = {
        'appName': appInfo['appName'],
        'packageName': appInfo['packageName'],
        'updateDesc': newFeatures,
      };
      if (datetime != null) {
        appInfoMap['onlineTime'] = datetime.millisecondsSinceEpoch;
      }

      Map<String, dynamic> requestDataMap = {
        'userName': 'huawei@cecdat.com',
        'synchroType': 1,
        'appInfo': jsonEncode(appInfoMap),
      };
      String requestData = jsonEncode(requestDataMap);

      Map<String, dynamic> sigMap = {
        'sig': [
          {'name': 'RequestData', 'hash': CryptoUtil.getMd5(requestData)},
          {'name': 'apk', 'hash': await CryptoUtil.getFileMd5(info32.file)},
          {
            'name': 'secondApk',
            'hash': await CryptoUtil.getFileMd5(info64.file),
          },
        ],
        'password': ConstantUtil.xiaomiClientSecret,
      };
      String sig = await CryptoUtil.encodeString(jsonEncode(sigMap));

      Map<String, dynamic> map = {
        'RequestData': requestData,
        'SIG': sig,
        'apk': await MultipartFile.fromFile(info32.file.path),
        'secondApk': await MultipartFile.fromFile(info64.file.path),
      };

      ///通过FormData
      FormData formData = FormData.fromMap(map);
      Response response = await DioUtil.dio.post(
        '$domain/dev/push',
        data: formData,
      );

      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['result'] == 0) {
          ret = true;
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('小米完成提交发布，结果为$ret');
    return ret;
  }
}
