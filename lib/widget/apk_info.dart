import 'package:flutter/material.dart';
import 'package:parser_apk_info/model/apk_info.dart';

class ApkInfoWidget extends StatelessWidget {
  const ApkInfoWidget(this.info, {super.key});

  final ApkInfo info;
  final String errorMsg = '解析失败';

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(title: const Text('文件：'), subtitle: Text(info.file.path)),
        ListTile(
          title: const Text('名称：'),
          trailing: Text(info.applicationLabel ?? errorMsg),
        ),
        ListTile(
          title: const Text('CPU：'),
          trailing: Text(info.nativeCodes?.join('/') ?? errorMsg),
        ),
        ListTile(
          title: const Text('版本：'),
          trailing: Text(info.versionName ?? errorMsg),
        ),
        ListTile(
          title: const Text('编译：'),
          trailing: Text(info.versionCode ?? errorMsg),
        ),
        ListTile(
          title: const Text('包名：'),
          trailing: Text(info.applicationId ?? errorMsg),
        ),
      ],
    );
  }
}
