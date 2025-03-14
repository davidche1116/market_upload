import 'dart:async';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:market_upload/market/honor_market.dart';
import 'package:market_upload/market/huawei_market.dart';
import 'package:market_upload/market/oppo_market.dart';
import 'package:market_upload/market/vivo_market.dart';
import 'package:market_upload/market/xiaomi_market.dart';
import 'package:market_upload/utils/apk_util.dart';
import 'package:market_upload/utils/constant_util.dart';
import 'package:market_upload/utils/log_util.dart';
import 'package:market_upload/widget/settings_page.dart';
import 'package:parser_apk_info/model/apk_info.dart';
import 'package:window_manager/window_manager.dart';

import 'apk_info.dart';
import 'log_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  ApkInfo? info32;
  ApkInfo? info64;
  final myController = TextEditingController();
  DateTime? date;
  TimeOfDay? time;
  bool isLoading = false;

  // 市场状态：0-未开始，1-成功，2-失败，-1-进行中
  Map<String, int> status = {
    'huawei': 0,
    'honor': 0,
    'oppo': 0,
    'vivo': 0,
    'xiaomi': 0,
  };

  // 市场名称映射
  final Map<String, String> marketNames = {
    'huawei': '华为',
    'honor': '荣耀',
    'oppo': 'OPPO',
    'vivo': 'VIVO',
    'xiaomi': '小米',
  };

  @override
  void initState() {
    windowManager.addListener(this);
    myController.text = '''1、优化用户体验
2、修复已知问题
''';
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    myController.dispose();
    super.dispose();
  }

  @override
  void onWindowFocus() {
    setState(() {});
  }

  Future<void> _apk32() async {
    await _apk(arm64: false);
  }

  Future<void> _apk64() async {
    await _apk();
  }

  Future<void> _apk({bool arm64 = true}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择${arm64 ? '64' : '32'}位APK文件',
        type: FileType.custom,
        allowedExtensions: ['apk'],
      );

      if (result != null) {
        setState(() => isLoading = true);
        ApkInfo? info = await ApkUtil().getInfo(result.files.single.path!);
        if (info != null) {
          if (arm64) {
            info64 = info;
          } else {
            info32 = info;
          }
          setState(() {});
        }
      }
    } catch (e) {
      LogUtil.logger.e('选择APK文件失败: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _onlineTime() async {
    try {
      date = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30)),
        initialDate: date ?? DateTime.now(),
      );
      if (date != null) {
        await Future.delayed(const Duration(microseconds: 1));
        if (!mounted) return;
        time = await showTimePicker(
          context: context,
          initialTime: time ?? const TimeOfDay(hour: 0, minute: 0),
        );
        if (time != null) {
          date = date!.add(Duration(hours: time!.hour, minutes: time!.minute));
        }
      }

      setState(() {});
    } catch (e) {
      LogUtil.logger.e('设置上架时间失败: $e');
    }
  }

  bool _checkInfo() {
    bool ret = (info32 != null) && (info64 != null);
    if (!ret) {
      LogUtil.logger.e('需要先选择32位和64位APK文件后，才能进行操作');
      _showErrorSnackBar('请先选择32位和64位APK文件');
    }
    return ret;
  }

  bool _checkHuaweiConfig() {
    if (ConstantUtil.huaweiClientId.isEmpty ||
        ConstantUtil.huaweiClientSecret.isEmpty) {
      LogUtil.logger.e('华为应用市场配置未设置');
      _showErrorSnackBar('请先在设置页面配置华为应用市场参数');
      return false;
    }
    return true;
  }

  bool _checkHonorConfig() {
    if (ConstantUtil.honorClientId.isEmpty ||
        ConstantUtil.honorClientSecret.isEmpty) {
      LogUtil.logger.e('荣耀应用市场配置未设置');
      _showErrorSnackBar('请先在设置页面配置荣耀应用市场参数');
      return false;
    }
    return true;
  }

  bool _checkOppoConfig() {
    if (ConstantUtil.oppoClientId.isEmpty ||
        ConstantUtil.oppoClientSecret.isEmpty) {
      LogUtil.logger.e('OPPO应用市场配置未设置');
      _showErrorSnackBar('请先在设置页面配置OPPO应用市场参数');
      return false;
    }
    return true;
  }

  bool _checkVivoConfig() {
    if (ConstantUtil.vivoAccessKey.isEmpty ||
        ConstantUtil.vivoAccessSecret.isEmpty) {
      LogUtil.logger.e('VIVO应用市场配置未设置');
      _showErrorSnackBar('请先在设置页面配置VIVO应用市场参数');
      return false;
    }
    return true;
  }

  bool _checkXiaomiConfig() {
    if (ConstantUtil.xiaomiClientSecret.isEmpty ||
        ConstantUtil.xiaomiPublicPem.isEmpty) {
      LogUtil.logger.e('小米应用市场配置未设置');
      _showErrorSnackBar('请先在设置页面配置小米应用市场参数');
      return false;
    }
    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // 通用的市场提交方法
  Future<void> _submitToMarket(
    String marketKey,
    Future<bool> Function() submitFunc,
  ) async {
    if (_checkInfo()) {
      try {
        setState(() {
          status[marketKey] = -1; // 设置为进行中
        });

        bool ret = await submitFunc();

        setState(() {
          status[marketKey] = ret ? 1 : 2; // 设置为成功或失败
        });
      } catch (e) {
        LogUtil.logger.e('${marketNames[marketKey]}市场提交失败: $e');
        setState(() {
          status[marketKey] = 2; // 设置为失败
        });
        _showErrorSnackBar('${marketNames[marketKey]}市场提交失败');
      }
    }
  }

  Future<void> _huawei() async {
    if (_checkHuaweiConfig()) {
      await _submitToMarket(
        'huawei',
        () => HuaweiMarket.submit(info64!, myController.text, date),
      );
    }
  }

  Future<void> _honor() async {
    if (_checkHonorConfig()) {
      await _submitToMarket(
        'honor',
        () => HonorMarket.submit(info64!, myController.text, date),
      );
    }
  }

  Future<void> _vivo() async {
    if (_checkVivoConfig()) {
      await _submitToMarket(
        'vivo',
        () => VivoMarket.submit(info32!, info64!, myController.text, date),
      );
    }
  }

  Future<void> _oppo() async {
    if (_checkOppoConfig()) {
      await _submitToMarket(
        'oppo',
        () => OppoMarket.submit(info32!, info64!, myController.text, date),
      );
    }
  }

  Future<void> _xiaomi() async {
    if (_checkXiaomiConfig()) {
      await _submitToMarket(
        'xiaomi',
        () => XiaomiMarket.submit(info32!, info64!, myController.text, date),
      );
    }
  }

  Future<void> _all() async {
    if (_checkInfo()) {
      if (_checkHuaweiConfig()) await _huawei();
      if (_checkHonorConfig()) await _honor();
      if (_checkVivoConfig()) await _vivo();
      if (_checkOppoConfig()) await _oppo();
      if (_checkXiaomiConfig()) await _xiaomi();
    }
  }

  Widget _statusIcon(String key) {
    if (status[key] == 1) {
      return const Icon(Icons.check_circle_outline, color: Colors.green);
    } else if (status[key] == 2) {
      return const Icon(Icons.close_outlined, color: Colors.red);
    } else if (status[key] == -1) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      return const Icon(Icons.circle_outlined, color: Colors.grey);
    }
  }

  // 创建市场按钮
  Widget _buildMarketButton(String marketKey, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusIcon(marketKey),
            const SizedBox(width: 4),
            Text(marketNames[marketKey] ?? marketKey),
          ],
        ),
      ),
    );
  }

  // 创建APK信息卡片
  Widget _buildApkInfoCard(ApkInfo? info, String title) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child:
                    info == null
                        ? const Center(child: Text('未选择APK文件'))
                        : ApkInfoWidget(info),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    return Scaffold(
      appBar: AppBar(
        title: const DragToMoveArea(
          child: SizedBox(
            width: double.infinity,
            child: Text(ConstantUtil.appTitle),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              AdaptiveTheme.of(context).toggleThemeMode(useSystem: false);
            },
            tooltip: '切换主题',
            icon: const Icon(Icons.wb_sunny_outlined, size: 20),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            tooltip: '设置',
            icon: const Icon(Icons.settings_outlined, size: 20),
          ),
          if (Platform.isWindows)
            SizedBox(
              width: 138,
              child: WindowCaption(
                brightness: Theme.of(context).brightness,
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              children: [
                // 顶部操作区
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      spacing: 12,
                      children: [
                        const Text(
                          'APK选择',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _apk32,
                          icon: const Icon(Icons.android_outlined),
                          label: const Text('选择32位APK'),
                          style: buttonStyle,
                        ),
                        ElevatedButton.icon(
                          onPressed: _apk64,
                          icon: const Icon(Icons.android_outlined),
                          label: const Text('选择64位APK'),
                          style: buttonStyle,
                        ),
                        Spacer(),
                        ElevatedButton.icon(
                          onPressed: _onlineTime,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(
                            date == null
                                ? '立即上架'
                                : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')} ${date!.hour.toString().padLeft(2, '0')}:${date!.minute.toString().padLeft(2, '0')}',
                          ),
                          style: buttonStyle,
                        ),
                        Spacer(),
                        ElevatedButton.icon(
                          onPressed: _all,
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('全部'),
                          style: buttonStyle,
                        ),
                        _buildMarketButton('huawei', _huawei),
                        _buildMarketButton('honor', _honor),
                        _buildMarketButton('vivo', _vivo),
                        _buildMarketButton('oppo', _oppo),
                        _buildMarketButton('xiaomi', _xiaomi),
                      ],
                    ),
                  ),
                ),
                // APK信息和更新内容区域
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      _buildApkInfoCard(info32, '32位APK信息'),
                      _buildApkInfoCard(info64, '64位APK信息'),
                      Expanded(
                        child: Card(
                          margin: const EdgeInsets.all(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '更新内容',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: TextFormField(
                                    controller: myController,
                                    maxLines: null,
                                    expands: true,
                                    decoration: const InputDecoration(
                                      hintText: '请输入应用更新内容',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 日志区域
                Expanded(
                  flex: 4,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: LogWidget(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 加载指示器
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
