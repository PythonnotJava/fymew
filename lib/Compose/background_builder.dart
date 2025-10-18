import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';

import '../Logic/global_config.dart';

/// 单例，生命周期是全局
final ValueNotifier<String> bgModeNotifier = ValueNotifier(mgrBgMode);

/// 全局的背景主题
Widget backgroundBuilder() {
  return Positioned.fill(
    child: ValueListenableBuilder<String>(
      valueListenable: bgModeNotifier,
      builder: (context, mode, _) {
        debugPrint('重塑了背景图片');
        switch (mode) {
          case '0':
            return SizedBox.shrink();
          case '1':
            return Image.asset(
              "assets/img/bg.jpg",
              fit: BoxFit.fill,
              gaplessPlayback: true,
              opacity: AlwaysStoppedAnimation(listOpacity),
            );
          case '2':
            return Opacity(
              opacity: listOpacity,
              child: GifView.asset(
                "assets/img/bg.gif",
                fit: BoxFit.fill,
                autoPlay: true,
                loop: true,
                frameRate: gifFps,
              ),
            );
          default:
            return Opacity(
              opacity: listOpacity,
              child: GifView(
                image: FileImage(File(mode)),
                fit: BoxFit.fill,
                autoPlay: true,
                loop: true,
                frameRate: gifFps,
              ),
            );
        }
      },
    ),
  );
}