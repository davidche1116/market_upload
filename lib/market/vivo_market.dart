import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:market_upload/utils/constant_util.dart';
import 'package:market_upload/utils/crypto_util.dart';
import 'package:market_upload/utils/dio_util.dart';
import 'package:market_upload/utils/log_util.dart';
import 'package:parser_apk_info/model/apk_info.dart';

/// 官方API文档：https://dev.vivo.com.cn/documentCenter/doc/326
class VivoMarket {
  static const String domain = 'https://developer-api.vivo.com.cn/router/rest';

  static Map<String, String> commonParameters = {
    'method': 'method',
    'access_key': ConstantUtil.vivoAccessKey,
    'timestamp': 'timestamp',
    'format': 'json',
    'v': '1.0',
    'sign_method': 'hmac',
    'sign': 'sign',
    'target_app_key': 'developer',
  };

  static Map<String, dynamic> appInfo = {};
  static Map<String, dynamic> apk32Info = {};
  static Map<String, dynamic> apk64Info = {};

  static Future<bool> submit(
    ApkInfo info32,
    ApkInfo info64,
    String updateContent,
    DateTime? datetime,
  ) async {
    LogUtil.logger.i('VIVO开始提交');

    // 查询信息
    bool ret = await getAppInfo(info64);
    if (ret) {
      // 上传32位APK
      ret = await uploadApk32(info32);
      if (ret) {
        // 上传64位APK
        ret = await uploadApk64(info64);
        if (ret) {
          // 提交发布
          ret = await appSubmit(updateContent, datetime);
        }
      }
    }

    LogUtil.logger.i('VIVO提交完成。结果为$ret');
    return ret;
  }

  static void setParam(String method) {
    commonParameters['method'] = method;
    commonParameters['timestamp'] =
        DateTime.now().millisecondsSinceEpoch.toString();
  }

  static Map<String, dynamic> getParam(Map<String, dynamic> param) {
    Map<String, dynamic> allParam = {};
    allParam.addAll(param);
    allParam.addAll(commonParameters);
    List<String> keys = allParam.keys.toList();
    keys.remove('sign');
    keys.remove('file');
    keys.sort();
    Map<String, dynamic> retParam = {};
    List<String> paramList = [];
    for (String key in keys) {
      dynamic value = allParam[key];
      if (value != null && value != '') {
        paramList.add('$key=$value');
        retParam[key] = value;
      }
    }
    String signParam = paramList.join('&');
    var hmacSha256 = Hmac(
      sha256,
      ConstantUtil.vivoAccessSecret.codeUnits,
    ); // HMAC-SHA256
    var digest = hmacSha256.convert(const Utf8Encoder().convert(signParam));
    retParam['sign'] = digest.toString();
    commonParameters['sign'] = digest.toString();
    return retParam;
  }

  static Future<bool> getAppInfo(ApkInfo info64) async {
    LogUtil.logger.i('VIVO开始获取APP信息');
    bool ret = false;

    try {
      setParam('app.query.details');
      Map<String, dynamic> param = {'packageName': info64.applicationId};
      param = getParam(param);
      Response response = await DioUtil.dio.post(
        domain,
        queryParameters: param,
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['code'] == 0) {
          ret = true;
          appInfo = response.data['data'];
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('VIVO完成获取APP信息，结果为$ret');
    return ret;
  }

  static Future<bool> uploadApk32(ApkInfo info32) async {
    LogUtil.logger.i('VIVO开始上传32位APK');
    bool ret = false;

    try {
      String fileMd5 = await CryptoUtil.getFileMd5(info32.file);

      setParam('app.upload.apk.app.32');
      Map<String, dynamic> param = {
        'packageName': info32.applicationId,
        'file': MultipartFile.fromFileSync(info32.file.path),
        'fileMd5': fileMd5,
      };
      getParam(param);
      Response response = await DioUtil.dio.post(
        domain,
        queryParameters: commonParameters,
        data: FormData.fromMap(param),
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['code'] == 0) {
          ret = true;
          apk32Info = response.data['data'];
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('VIVO完成获取上传32位APK，结果为$ret');
    return ret;
  }

  static Future<bool> uploadApk64(ApkInfo info64) async {
    LogUtil.logger.i('VIVO开始上传64位APK');
    bool ret = false;

    try {
      String fileMd5 = await CryptoUtil.getFileMd5(info64.file);

      setParam('app.upload.apk.app.64');
      Map<String, dynamic> param = {
        'packageName': info64.applicationId,
        'file': MultipartFile.fromFileSync(info64.file.path),
        'fileMd5': fileMd5,
      };
      getParam(param);
      Response response = await DioUtil.dio.post(
        domain,
        queryParameters: commonParameters,
        data: FormData.fromMap(param),
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['code'] == 0) {
          ret = true;
          apk64Info = response.data['data'];
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('VIVO完成获取上传64位APK，结果为$ret');
    return ret;
  }

  static Future<bool> appSubmit(String newFeatures, DateTime? datetime) async {
    LogUtil.logger.i('VIVO开始提交发布');
    bool ret = false;

    try {
      setParam('app.sync.update.subpackage.app');
      Map<String, dynamic> param = {
        'packageName': apk64Info['packageName'],
        'apk32': apk32Info['serialnumber'],
        'apk64': apk64Info['serialnumber'],
        'onlineType': 1,
        'updateDesc': newFeatures,
      };
      if (datetime != null) {
        param['onlineType'] = 2;
        param['scheOnlineTime'] = datetime.toString().substring(0, 19);
      }
      Map<String, dynamic> allParam = getParam(param);
      Response response = await DioUtil.dio.post(
        domain,
        queryParameters: allParam,
        data: param,
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['code'] == 0) {
          ret = true;
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('VIVO完成提交发布，结果为$ret');
    return ret;
  }
}
