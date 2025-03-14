import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:market_upload/utils/prefs_util.dart';
import 'package:window_manager/window_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final androidSdkController = TextEditingController();
  final huaweiClientIdController = TextEditingController();
  final huaweiClientSecretController = TextEditingController();
  final honorClientIdController = TextEditingController();
  final honorClientSecretController = TextEditingController();
  final oppoClientIdController = TextEditingController();
  final oppoClientSecretController = TextEditingController();
  final vivoAccessKeyController = TextEditingController();
  final vivoAccessSecretController = TextEditingController();
  final xiaomiClientSecretController = TextEditingController();
  final xiaomiPublicPemController = TextEditingController();

  @override
  void initState() {
    androidSdkController.text =
        PrefsUtil().getString(PrefsUtil.keyAndroidSdk) ?? '';
    huaweiClientIdController.text =
        PrefsUtil().getString(PrefsUtil.keyHuaweiClientId) ?? '';
    huaweiClientSecretController.text =
        PrefsUtil().getString(PrefsUtil.keyHuaweiClientSecret) ?? '';
    honorClientIdController.text =
        PrefsUtil().getString(PrefsUtil.keyHonorClientId) ?? '';
    honorClientSecretController.text =
        PrefsUtil().getString(PrefsUtil.keyHonorClientSecret) ?? '';
    oppoClientIdController.text =
        PrefsUtil().getString(PrefsUtil.keyOppoClientId) ?? '';
    oppoClientSecretController.text =
        PrefsUtil().getString(PrefsUtil.keyOppoClientSecret) ?? '';
    vivoAccessKeyController.text =
        PrefsUtil().getString(PrefsUtil.keyVivoAccessKey) ?? '';
    vivoAccessSecretController.text =
        PrefsUtil().getString(PrefsUtil.keyVivoAccessSecret) ?? '';
    xiaomiClientSecretController.text =
        PrefsUtil().getString(PrefsUtil.keyXiaomiClientSecret) ?? '';
    xiaomiPublicPemController.text =
        PrefsUtil().getString(PrefsUtil.keyXiaomiPublicPem) ?? '';
    super.initState();
  }

  @override
  void dispose() {
    androidSdkController.dispose();
    huaweiClientIdController.dispose();
    huaweiClientSecretController.dispose();
    honorClientIdController.dispose();
    honorClientSecretController.dispose();
    oppoClientIdController.dispose();
    oppoClientSecretController.dispose();
    vivoAccessKeyController.dispose();
    vivoAccessSecretController.dispose();
    xiaomiClientSecretController.dispose();
    xiaomiPublicPemController.dispose();
    super.dispose();
  }

  Future<void> _chooseFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      setState(() {
        androidSdkController.text = selectedDirectory;
      });
    }
  }

  Future<void> _save() async {
    PrefsUtil().setString(PrefsUtil.keyAndroidSdk, androidSdkController.text);
    PrefsUtil().setString(
      PrefsUtil.keyHuaweiClientId,
      huaweiClientIdController.text,
    );
    PrefsUtil().setString(
      PrefsUtil.keyHuaweiClientSecret,
      huaweiClientSecretController.text,
    );
    PrefsUtil().setString(
      PrefsUtil.keyHonorClientId,
      honorClientIdController.text,
    );
    PrefsUtil().setString(
      PrefsUtil.keyHonorClientSecret,
      honorClientSecretController.text,
    );
    PrefsUtil().setString(
      PrefsUtil.keyOppoClientId,
      oppoClientIdController.text,
    );
    PrefsUtil().setString(
      PrefsUtil.keyOppoClientSecret,
      oppoClientSecretController.text,
    );
    PrefsUtil().setString(
      PrefsUtil.keyVivoAccessKey,
      vivoAccessKeyController.text,
    );
    PrefsUtil().setString(
      PrefsUtil.keyVivoAccessSecret,
      vivoAccessSecretController.text,
    );
    PrefsUtil().setString(
      PrefsUtil.keyXiaomiClientSecret,
      xiaomiClientSecretController.text,
    );
    PrefsUtil().setString(
      PrefsUtil.keyXiaomiPublicPem,
      xiaomiPublicPemController.text,
    );
    Navigator.pop(context);
  }

  Future<void> _cancel() async {
    Navigator.pop(context);
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool multiline = false,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: multiline ? 8 : 1,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                hintText: hintText,
                isDense: true,
                suffixIcon:
                    controller == androidSdkController
                        ? IconButton(
                          icon: const Icon(Icons.folder_open),
                          onPressed: _chooseFolder,
                        )
                        : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const DragToMoveArea(
          child: SizedBox(width: double.infinity, child: Text('设置')),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMarketSection('基础配置', [
              _buildTextField(
                'Android SDK目录',
                androidSdkController,
                hintText: '请选择Android SDK目录',
              ),
            ]),
            _buildMarketSection('华为应用市场', [
              _buildTextField(
                'Client ID',
                huaweiClientIdController,
                hintText: '请输入华为应用市场Client ID',
              ),
              _buildTextField(
                'Client Secret',
                huaweiClientSecretController,
                hintText: '请输入华为应用市场Client Secret',
              ),
            ]),
            _buildMarketSection('荣耀应用市场', [
              _buildTextField(
                'Client ID',
                honorClientIdController,
                hintText: '请输入荣耀应用市场Client ID',
              ),
              _buildTextField(
                'Client Secret',
                honorClientSecretController,
                hintText: '请输入荣耀应用市场Client Secret',
              ),
            ]),
            _buildMarketSection('OPPO应用市场', [
              _buildTextField(
                'Client ID',
                oppoClientIdController,
                hintText: '请输入OPPO应用市场Client ID',
              ),
              _buildTextField(
                'Client Secret',
                oppoClientSecretController,
                hintText: '请输入OPPO应用市场Client Secret',
              ),
            ]),
            _buildMarketSection('VIVO应用市场', [
              _buildTextField(
                'Access Key',
                vivoAccessKeyController,
                hintText: '请输入VIVO应用市场Access Key',
              ),
              _buildTextField(
                'Access Secret',
                vivoAccessSecretController,
                hintText: '请输入VIVO应用市场Access Secret',
              ),
            ]),
            _buildMarketSection('小米应用市场', [
              _buildTextField(
                'Client Secret',
                xiaomiClientSecretController,
                hintText: '请输入小米应用市场Client Secret',
              ),
              _buildTextField(
                'Public PEM',
                xiaomiPublicPemController,
                multiline: true,
                hintText: '请输入小米应用市场Public PEM',
              ),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: _cancel, child: const Text('取消')),
              const SizedBox(width: 8),
              FilledButton(onPressed: _save, child: const Text('保存')),
            ],
          ),
        ),
      ),
    );
  }
}
