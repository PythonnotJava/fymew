import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart' as window_size;
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_kit/media_kit.dart';

import 'Logic/play_controller.dart';
import 'Logic/global_config.dart';
import 'Compose/mix_compose.dart' show AppCore;
import 'Compose/user_drawer.dart' show DrawerState;
import 'Compose/floating_player.dart' show FloatingPlayerController;
import 'Logic/system_notifier.dart';
import 'Logic/click_mode_controller.dart' show ClickModeController;

Future<void> main() async {
  runZonedGuarded(
    () async {
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      MediaKit.ensureInitialized();

      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      await initGlobalSystem();

      /// 安卓通知权限
      if (isPlatformWithMobile) {
        if (await Permission.notification.status.isDenied) {
          debugPrint('尝试要通知权限');
          await Permission.notification.request();
        } else {
          debugPrint('已经获得通知权限');
        }
      }

      /// -----------------日志模块----------------------------

      /// 保存原始 debugPrint
      final originalDebugPrint = debugPrint;

      /// 重定向 debugPrint
      debugPrint = (String? message, {int? wrapWidth}) {
        originalDebugPrint(message, wrapWidth: wrapWidth);
        if (message != null) {
          writeLog("DEBUG: $message");
        }
      };

      /// 捕获 Flutter 框架错误
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.dumpErrorToConsole(details);
        writeLog(
          "FLUTTER ERROR: ${details.exceptionAsString()}\n${details.stack}",
        );
      };

      /// -----------------------------------------

      if (isPlatformWithPC) {
        debugPrint('PC端限制尺寸');
        window_size.setWindowMinSize(const Size(600, 800));
        window_size.setWindowMaxSize(Size.infinite);
        window_size.setWindowTitle('Fymew');
      }

      final playerController = PlayerController();
      await playerController.loadInitialPlaylistAndRecord();

      /// 重要！！！：预加载，不然出现点击浮动球才开始计时的bug
      final OnlineController onlineController = OnlineController();

      debugPrint("Current music path = ${initInfo.musicPath}");
      debugPrint("Current storage = ${dirOfLongTimeStorage.path}");

      if (playerController.onlyStartMode != 3){
        /// 注册全局音频服务
        audioHandler = await AudioService.init(
          builder: () => MyAudioHandler(playerController),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'com.pythonnotjava.fymew',
            androidNotificationChannelName: 'Audio Playback',
            androidNotificationOngoing: true,
          ),
        );
      }

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => DrawerState()),
            ChangeNotifierProvider(create: (_) => playerController),
            ChangeNotifierProvider(create: (_) => onlineController),
            ChangeNotifierProvider(create: (_) => FloatingPlayerController()),
            ChangeNotifierProvider(create: (_) => ClickModeController())
          ],
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'SourceHanSerifSC'),
            title: 'Fymew',
            home: const AppCore(),
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
      FlutterNativeSplash.remove();
    },
    (error, stack) {
      writeLog("UNCAUGHT EXCEPTION: $error\n$stack");
    },
  );
}
