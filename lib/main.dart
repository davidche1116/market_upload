import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:market_upload/utils/constant_util.dart';
import 'package:market_upload/utils/prefs_util.dart';
import 'package:window_manager/window_manager.dart';

import 'widget/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PrefsUtil().init();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 680),
    minimumSize: Size(1280, 680),
    title: ConstantUtil.appTitle,
    center: true,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  runApp(MarketUploadApp(savedThemeMode: savedThemeMode));
}

class MarketUploadApp extends StatelessWidget {
  const MarketUploadApp({super.key, this.savedThemeMode});

  final AdaptiveThemeMode? savedThemeMode;

  @override
  Widget build(BuildContext context) {
    const MaterialColor themeColor = Colors.blue;
    return AdaptiveTheme(
      light: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeColor,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ),
      ),
      dark: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeColor,
          brightness: Brightness.dark,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ),
      ),
      initial: savedThemeMode ?? AdaptiveThemeMode.system,
      builder:
          (theme, darkTheme) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: ConstantUtil.appTitle,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('zh', 'CN')],
            theme: theme,
            darkTheme: darkTheme,
            home: const HomePage(),
          ),
    );
  }
}
