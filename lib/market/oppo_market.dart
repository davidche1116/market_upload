import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:market_upload/utils/constant_util.dart';
import 'package:market_upload/utils/dio_util.dart';
import 'package:market_upload/utils/log_util.dart';
import 'package:parser_apk_info/model/apk_info.dart';

/// 官方API文档：https://open.oppomobile.com/new/developmentDoc/info?id=10998
class OppoMarket {
  static const String domain = 'https://oop-openapi-cn.heytapmobi.com';

  static Map<String, String> commonParameters = {
    'access_token': 'access_token',
    'timestamp': 'timestamp',
    'api_sign': 'api_sign',
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
    LogUtil.logger.i('OPPO开始提交');

    // 获取token
    bool ret = await getToken();
    if (ret) {
      // 查询信息
      ret = await getAppInfo(info64);
      if (ret) {
        // 上传32位APK
        ret = await getUploadUrl(false);
        if (ret) {
          ret = await uploadFile(info32, false);
          if (ret) {
            // 上传64位APK
            ret = await getUploadUrl(true);
            if (ret) {
              ret = await uploadFile(info64, true);
              if (ret) {
                // 提交发布
                ret = await appSubmit(info64, updateContent, datetime);
              }
            }
          }
        }
      }
    }

    LogUtil.logger.i('OPPO提交完成。结果为$ret');
    return ret;
  }

  static void setParam() {
    commonParameters['timestamp'] =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  }

  static Map<String, dynamic> getParam(Map<String, dynamic> param) {
    Map<String, dynamic> allParam = {};
    allParam.addAll(param);
    allParam.addAll(commonParameters);
    List<String> keys = allParam.keys.toList();
    keys.remove('api_sign');
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
      ConstantUtil.oppoClientSecret.codeUnits,
    ); // HMAC-SHA256
    var digest = hmacSha256.convert(const Utf8Encoder().convert(signParam));
    retParam['api_sign'] = digest.toString();
    commonParameters['api_sign'] = digest.toString();
    return retParam;
  }

  static Future<bool> getToken() async {
    LogUtil.logger.i('OPPO开始获取token');
    bool ret = false;

    try {
      Response response = await DioUtil.dio.get(
        '$domain/developer/v1/token',
        queryParameters: {
          'client_id': ConstantUtil.oppoClientId,
          'client_secret': ConstantUtil.oppoClientSecret,
        },
      );
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['errno'] == 0) {
          String accessToken = response.data['data']['access_token'] ?? '';
          commonParameters['access_token'] = accessToken;
          LogUtil.logger.i('OPPO获取token为：$accessToken');
          ret = accessToken.isNotEmpty;
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('OPPO完成获取token，结果为$ret');
    return ret;
  }

  static Future<bool> getAppInfo(ApkInfo info64) async {
    LogUtil.logger.i('OPPO开始获取APP信息');
    bool ret = false;

    try {
      setParam();
      Map<String, dynamic> param = {'pkg_name': info64.applicationId};
      param = getParam(param);
      Response response = await DioUtil.dio.get(
        '$domain/resource/v1/app/info',
        queryParameters: param,
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['errno'] == 0) {
          ret = true;
          appInfo = response.data['data'];
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('OPPO完成获取APP信息，结果为$ret');
    return ret;
  }

  static Future<bool> getUploadUrl(bool arm64) async {
    LogUtil.logger.i('OPPO开始获取${arm64 ? '64' : '32'}位上传地址');
    bool ret = false;

    try {
      setParam();
      getParam({});
      Response response = await DioUtil.dio.get(
        '$domain/resource/v1/upload/get-upload-url',
        queryParameters: commonParameters,
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['errno'] == 0) {
          ret = true;
          if (arm64) {
            apk64Info = response.data['data'];
          } else {
            apk32Info = response.data['data'];
          }
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('OPPO完成获取${arm64 ? '64' : '32'}位上传地址，结果为$ret');
    return ret;
  }

  static Future<bool> uploadFile(ApkInfo apkInfo, bool arm64) async {
    LogUtil.logger.i('OPPO开始上传${arm64 ? '64' : '32'}位APK');
    bool ret = false;

    try {
      setParam();
      Map<String, dynamic> param = {
        'type': 'apk',
        'sign': arm64 ? apk64Info['sign'] : apk32Info['sign'],
        'file': MultipartFile.fromFileSync(apkInfo.file.path),
      };
      getParam(param);
      Response response = await DioUtil.dio.post(
        arm64 ? apk64Info['upload_url'] : apk32Info['upload_url'],
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        queryParameters: commonParameters,
        data: FormData.fromMap(param),
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['errno'] == 0) {
          ret = true;
          if (arm64) {
            apk64Info = response.data['data'];
          } else {
            apk32Info = response.data['data'];
          }
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('OPPO完成上传${arm64 ? '64' : '32'}位APK，结果为$ret');
    return ret;
  }

  static Future<bool> appSubmit(
    ApkInfo apkInfo,
    String newFeatures,
    DateTime? datetime,
  ) async {
    LogUtil.logger.i('OPPO开始提交发布');
    bool ret = false;

    try {
      setParam();
      List<Map<String, dynamic>> apkUrl = [
        {'url': apk32Info['url'], 'md5': apk32Info['md5'], 'cpu_code': 32},
        {'url': apk64Info['url'], 'md5': apk64Info['md5'], 'cpu_code': 64},
      ];
      String jsonApkUrl = jsonEncode(apkUrl);
      LogUtil.logger.d(jsonApkUrl);

      Map<String, dynamic> param = {
        'pkg_name': appInfo['pkg_name'],
        'version_code': apkInfo.versionCode,
        'apk_url': jsonApkUrl,
        'app_name': appInfo['app_name'],
        'second_category_id': appInfo['second_category_id'],
        'third_category_id': appInfo['third_category_id'],
        'summary': appInfo['summary'],
        'detail_desc': appInfo['detail_desc'],
        'update_desc': newFeatures,
        'privacy_source_url': appInfo['privacy_source_url'],
        'icon_url': appInfo['icon_url'],
        'pic_url': appInfo['pic_url'],
        'online_type': 1,
        'test_desc': appInfo['test_desc'],
        'copyright_url': appInfo['copyright_url'],
        'business_username': appInfo['business_username'],
        'business_email': appInfo['business_email'],
        'business_mobile': appInfo['business_mobile'],
        'age_level': appInfo['age_level'],
        'adaptive_equipment': appInfo['adaptive_equipment'],
        'special_url': appInfo['special_url'],
        'special_file_url': appInfo['special_file_url'],
        'icp_url': appInfo['icp_url'],
      };
      if (datetime != null) {
        param['online_type'] = 2;
        param['sche_online_time'] = datetime.toString().substring(0, 19);
      }

      Map<String, dynamic> allParam = getParam(param);
      Response response = await DioUtil.dio.post(
        '$domain/resource/v1/app/upd',
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
        data: allParam,
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['errno'] == 0) {
          ret = true;
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('OPPO完成提交发布，结果为$ret');
    return ret;
  }
}
