import 'package:cross_file/cross_file.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:market_upload/utils/constant_util.dart';
import 'package:market_upload/utils/dio_util.dart';
import 'package:market_upload/utils/log_util.dart';
import 'package:parser_apk_info/model/apk_info.dart';

/// 官方API文档：https://developer.honor.com/cn/doc/guides/101359
class HonorMarket {
  static const String domain =
      'https://appmarket-openapi-drcn.cloud.honor.com/openapi';

  static String accessToken = '';
  static Options options = Options();
  static Map<String, dynamic> appInfo = {};
  static Map<String, dynamic> urlInfo = {};
  static String appId = '';

  static Future<bool> submit(
    ApkInfo info64,
    String updateContent,
    DateTime? datetime,
  ) async {
    LogUtil.logger.i('荣耀开始提交');

    // 获取token
    bool ret = await getToken();
    if (ret) {
      // 获取APP ID
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
                  // 提交发布
                  ret = await appSubmit(datetime);
                }
              }
            }
          }
        }
      }
    }

    LogUtil.logger.i('荣耀提交完成。结果为$ret');
    return ret;
  }

  static Future<bool> getToken() async {
    LogUtil.logger.i('荣耀开始获取token');
    bool ret = false;

    try {
      Response response = await DioUtil.dio.post(
        'https://iam.developer.honor.com/auth/token',
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
        data: {
          'grant_type': 'client_credentials',
          'client_id': ConstantUtil.honorClientId,
          'client_secret': ConstantUtil.honorClientSecret,
        },
      );
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        accessToken = response.data['access_token'] ?? '';
        // 其他API调用需要用的headers
        options = Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );
        LogUtil.logger.i('荣耀获取token为：$accessToken');
        ret = accessToken.isNotEmpty;
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('荣耀完成获取token，结果为$ret');
    return ret;
  }

  static Future<bool> getAppId(String pkgName) async {
    LogUtil.logger.i('荣耀开始获取APP ID');
    bool ret = false;

    try {
      Response response = await DioUtil.dio.get(
        '$domain/v1/publish/get-app-id',
        options: options,
        queryParameters: {'pkgName': pkgName},
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['code'] == 0) {
          ret = true;
          List idList = response.data['data'];
          appId = idList.first['appId'].toString();
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('荣耀完成获取APP ID，结果为$ret');
    return ret;
  }

  static Future<bool> getAppInfo() async {
    LogUtil.logger.i('荣耀开始获取APP信息');
    bool ret = false;

    try {
      Response response = await DioUtil.dio.get(
        '$domain/v1/publish/get-app-detail',
        options: options,
        queryParameters: {'appId': appId},
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

    LogUtil.logger.i('荣耀完成获取APP信息，结果为$ret');
    return ret;
  }

  static Future<bool> getUploadUrl(ApkInfo info64) async {
    LogUtil.logger.i('荣耀开始获取上传地址');
    bool ret = false;

    try {
      XFile file = XFile(info64.file.path);
      int size = await file.length();
      String s256 = sha256.convert(info64.file.readAsBytesSync()).toString();
      Response response = await DioUtil.dio.post(
        '$domain/v1/publish/get-file-upload-url',
        options: options,
        queryParameters: {'appId': appId},
        data: [
          {
            'fileName': file.name,
            'fileType': 100,
            'fileSize': size,
            'fileSha256': s256,
          },
        ],
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['code'] == 0) {
          ret = true;
          var data = response.data['data'];
          urlInfo = data.single;
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('荣耀完成获取上传地址，结果为$ret');
    return ret;
  }

  static Future<bool> uploadFile(ApkInfo info64) async {
    LogUtil.logger.i('荣耀开始上传文件');
    bool ret = false;

    try {
      XFile file = XFile(info64.file.path);

      ///通过FormData
      Map<String, dynamic> map = {};
      map["name"] = "file";
      map['filename'] = file.name;
      map["file"] = await MultipartFile.fromFile(
        file.path,
        filename: file.name,
      );

      ///通过FormData
      FormData formData = FormData.fromMap(map);

      Response response = await DioUtil.dio.post(
        urlInfo['uploadUrl'],
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'multipart/form-data',
          },
        ),
        data: formData,
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

    LogUtil.logger.i('荣耀完成上传文件，结果为$ret');
    return ret;
  }

  static Future<bool> updateFile(ApkInfo info64) async {
    LogUtil.logger.i('荣耀开始更新应用文件信息');
    bool ret = false;

    try {
      Response response = await DioUtil.dio.post(
        '$domain/v1/publish/update-file-info',
        options: options,
        queryParameters: {'appId': appId},
        data: {
          'bindingFileList': [
            {'objectId': urlInfo['objectId']},
          ],
        },
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['code'] == 0) {
          ret = true;
          urlInfo = response.data['urlInfo'];
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('荣耀完成更新应用文件信息，结果为$ret');
    return ret;
  }

  static Future<bool> updateFeatures(String newFeatures) async {
    LogUtil.logger.i('荣耀开始更新应用新版本信息');
    bool ret = false;

    try {
      Response response = await DioUtil.dio.post(
        '$domain/v1/publish/update-language-info',
        options: options,
        queryParameters: {'appId': appId},
        data: {
          'languageInfoList': [
            {
              'languageId': 'zh-CN',
              'appName': appInfo['languageInfo'][0]['appName'],
              'intro': appInfo['languageInfo'][0]['intro'],
              'newFeature': newFeatures,
            },
          ],
        },
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

    LogUtil.logger.i('荣耀完成更新应用新版本信息，结果为$ret');
    return ret;
  }

  static Future<bool> appSubmit(DateTime? datetime) async {
    LogUtil.logger.i('荣耀开始提交发布');
    bool ret = false;

    try {
      Map<String, dynamic> data = {'releaseType': 1};
      if (datetime != null) {
        // 例：2024-01-01T01:01:01+0800
        String time =
            '${datetime.toString().substring(0, 10)}T${datetime.toString().substring(11, 19)}+0800';
        data = {'releaseType': 2, 'releaseTime': time};
      }
      Response response = await DioUtil.dio.post(
        '$domain/v1/publish/submit-audit',
        options: options,
        queryParameters: {'appId': appId},
        data: data,
      );
      LogUtil.logger.d(response);
      if (response.statusCode == ConstantUtil.httpStatusOk) {
        if (response.data['code'] == 0) {
          ret = true;
          LogUtil.logger.i('发布流程ID为${response.data['data']}');
        }
      }
    } catch (e) {
      LogUtil.logger.e(e);
    }

    LogUtil.logger.i('荣耀完成提交发布，结果为$ret');
    return ret;
  }
}
