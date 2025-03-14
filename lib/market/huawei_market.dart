import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:market_upload/utils/constant_util.dart';
import 'package:market_upload/utils/dio_util.dart';
import 'package:market_upload/utils/log_util.dart';
import 'package:parser_apk_info/model/apk_info.dart';

/// 官方API文档：https://developer.huawei.com/consumer/cn/doc/AppGallery-connect-Guides/agcapi-updateapp-0000001111845352
class HuaweiMarket {
  static const String domain = 'https://connect-api.cloud.huawei.com/api';

  static String accessToken = '';
  static Options options = Options();
  static Map<String, dynamic> appInfo = {};
  static List<Map<String, dynamic>> languages = [{}];
  static Map<String, dynamic> urlInfo = {};
  static String appId = '';

  static Future<bool> submit(
    ApkInfo info64,
    String updateContent,
    DateTime? datetime,
  ) async {
    LogUtil.logger.i('华为开始提交');

    // 获取token
    bool ret = await getToken();
    if (ret) {
      ret = await getAppId(info64.applicationId ?? '');
      if (ret) {
        // 查询信息
        ret = await getAppInfo();
        if (ret) {
          // 获取文件上传地址
          ret = await getUploadUrl(info64);
          if (ret) {
            // 上传文件
            ret = await uploadFile(info64);
            if (ret) {
              // 更新文件
              ret = await updateFile(info64);
              if (ret) {
                // 更新新版本说明
                ret = await updateFeatures(updateContent);
                if (ret) {
                  // 软件包采用异步解析方式，请您在传包后等候2分钟再调用提交发布接口。
                  await Future.delayed(const Duration(seconds: 60));
                  // 提交发布
                  ret = await appSubmit(datetime);
                }
              }
            }
          }
        }
      }
    }

    LogUtil.logger.i('华为提交完成。结果为$ret');
    return ret;
  }

  static Future<bool> getToken() async {
    LogUtil.logger.i('华为开始获取token');
    bool ret = false;

    try {
      Response response = await DioUtil.dio.post(
        '$domain/oauth2/v1/token',
        data: {
          'grant_type': 'client_credentials',
          'client_id': ConstantUtil.huaweiClientId,
          'client_secret': ConstantUtil.huaweiClientSecret,
        },
      );
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        accessToken = response.data['access_token'] ?? '';
        // 其他API调用需要用的headers
        options = Options(
          headers: {
            'client_id': ConstantUtil.huaweiClientId,
            'Authorization': 'Bearer $accessToken',
          },
        );
        LogUtil.logger.i('华为获取token为：$accessToken');
        ret = accessToken.isNotEmpty;
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('华为完成获取token，结果为$ret');
    return ret;
  }

  static Future<bool> getAppId(String packageName) async {
    LogUtil.logger.i('华为开始获取APP ID');
    bool ret = false;

    try {
      Response response = await DioUtil.dio.get(
        '$domain/publish/v2/appid-list',
        options: options,
        queryParameters: {'packageName': packageName},
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['ret']['code'] == 0) {
          ret = true;
          List idList = response.data['appids'];
          appId = idList.first['value'];
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('华为完成获取APP ID，结果为$ret');
    return ret;
  }

  static Future<bool> getAppInfo() async {
    LogUtil.logger.i('华为开始获取APP信息');
    bool ret = false;

    try {
      Response response = await DioUtil.dio.get(
        '$domain/publish/v2/app-info',
        options: options,
        queryParameters: {'appId': appId, 'lang': 'zh-CN'},
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['ret']['code'] == 0) {
          ret = true;
          appInfo = response.data['appInfo'];
          languages = response.data['languages'];
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('华为完成获取APP信息，结果为$ret');
    return ret;
  }

  static Future<bool> getUploadUrl(ApkInfo info64) async {
    LogUtil.logger.i('华为开始获取上传地址');
    bool ret = false;

    try {
      XFile file = XFile(info64.file.path);
      int size = await file.length();
      Response response = await DioUtil.dio.get(
        '$domain/publish/v2/upload-url/for-obs',
        options: options,
        queryParameters: {
          'appId': appId,
          'fileName': file.name,
          'contentLength': size,
        },
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['ret']['code'] == 0) {
          ret = true;
          urlInfo = response.data['urlInfo'];
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('华为完成获取上传地址，结果为$ret');
    return ret;
  }

  static Future<bool> uploadFile(ApkInfo info64) async {
    LogUtil.logger.i('华为开始上传文件');
    bool ret = false;

    try {
      Response response = await DioUtil.dio.request(
        urlInfo['url'],
        options: Options(
          method: urlInfo['method'],
          headers: urlInfo['headers'],
        ),
        data: info64.file.readAsBytesSync(),
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        ret = true;
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('华为完成上传文件，结果为$ret');
    return ret;
  }

  static Future<bool> updateFile(ApkInfo info64) async {
    LogUtil.logger.i('华为开始更新应用文件信息');
    bool ret = false;

    try {
      XFile file = XFile(info64.file.path);
      Response response = await DioUtil.dio.put(
        '$domain/publish/v2/app-file-info',
        options: options,
        queryParameters: {'appId': appId},
        data: {
          'fileType': 5,
          'files': [
            {'fileName': file.name, 'fileDestUrl': urlInfo['objectId']},
          ],
        },
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['ret']['code'] == 0) {
          ret = true;
          urlInfo = response.data['urlInfo'];
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('华为完成更新应用文件信息，结果为$ret');
    return ret;
  }

  static Future<bool> updateFeatures(String newFeatures) async {
    LogUtil.logger.i('华为开始更新应用新版本信息');
    bool ret = false;

    try {
      Response response = await DioUtil.dio.put(
        '$domain/publish/v2/app-language-info',
        options: options,
        queryParameters: {'appId': appId},
        data: {'lang': 'zh-CN', 'newFeatures': newFeatures},
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['ret']['code'] == 0) {
          ret = true;
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('华为完成更新应用新版本信息，结果为$ret');
    return ret;
  }

  static Future<bool> appSubmit(DateTime? datetime) async {
    LogUtil.logger.i('华为开始提交发布');
    bool ret = false;

    try {
      Map<String, dynamic> queryParameters = {'appId': appId};
      if (datetime != null) {
        String time =
            '${datetime.toString().substring(0, 10)}T${datetime.toString().substring(11, 19)}+0800';
        queryParameters['releaseTime'] = time;
      }
      Response response = await DioUtil.dio.post(
        '$domain/publish/v2/app-submit',
        options: options,
        queryParameters: queryParameters,
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['ret']['code'] == 0) {
          ret = true;
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('华为完成提交发布，结果为$ret');
    return ret;
  }
}
