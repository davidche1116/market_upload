import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/services.dart';
import 'package:market_upload/utils/constant_util.dart';
import 'package:pointycastle/asymmetric/api.dart';

class CryptoUtil {
  ///使用md5加密
  static Future<String> getFilePathMd5(String filePath) async {
    final file = File(filePath);
    return await getFileMd5(file);
  }

  static Future<String> getFileMd5(File file) async {
    final fileBytes = file.readAsBytesSync().buffer.asUint8List();
    final hash = md5.convert(fileBytes.buffer.asUint8List()).toString();
    return hash;
  }

  static String getMd5(String str) {
    final hash = md5.convert(utf8.encode(str)).toString();
    return hash;
  }

  static String uint8ToHex(Uint8List byteArr) {
    if (byteArr.isEmpty) {
      return "";
    }
    Uint8List result = Uint8List(byteArr.length << 1);
    var hexTable = [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
    ]; //16进制字符表
    for (var i = 0; i < byteArr.length; i++) {
      var bit = byteArr[i]; //取传入的byteArr的每一位
      var index = bit >> 4 & 15; //右移4位,取剩下四位
      var i2 = i << 1; //byteArr的每一位对应结果的两位,所以对于结果的操作位数要乘2
      result[i2] = hexTable[index].codeUnitAt(0); //左边的值取字符表,转为Unicode放进resut数组
      index = bit & 15; //取右边四位
      result[i2 + 1] = hexTable[index].codeUnitAt(
        0,
      ); //右边的值取字符表,转为Unicode放进resut数组
    }
    return String.fromCharCodes(result); //Unicode转回为对应字符,生成字符串返回
  }

  static String uint8ListToHexString(Uint8List data) {
    return data.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  static Future encodeString(String content) async {
    //创建公钥对象
    RSAPublicKey publicKey =
        RSAKeyParser().parse(ConstantUtil.xiaomiPublicPem) as RSAPublicKey;
    //创建加密器
    final encrypter = Encrypter(RSA(publicKey: publicKey));
    int encryptGroupSize = 117;

    //分段加密
    // 原始字符串转成字节数组
    List<int> sourceBytes = utf8.encode(content);
    //数据长度
    int inputLength = sourceBytes.length;
    // 缓存数组
    List<int> cache = [];
    // 分段加密 步长为MAX_ENCRYPT_BLOCK
    for (int i = 0; i < inputLength; i += encryptGroupSize) {
      //剩余长度
      int endLen = inputLength - i;
      List<int> item;
      if (endLen > encryptGroupSize) {
        item = sourceBytes.sublist(i, i + encryptGroupSize);
      } else {
        item = sourceBytes.sublist(i, i + endLen);
      }
      // 加密后对象转换成数组存放到缓存
      cache.addAll(encrypter.encryptBytes(item).bytes);
    }

    Uint8List bytes = Uint8List.fromList(cache);
    String hexString = uint8ListToHexString(bytes);
    return hexString;
  }
}
