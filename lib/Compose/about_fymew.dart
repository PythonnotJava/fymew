import 'dart:math';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Logic/global_config.dart';

const url = "https://github.com/PythonnotJava";

class AboutFymewDialog extends StatelessWidget {
  const AboutFymewDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent, // 先设透明，让圆角可见
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.05,
        vertical: size.height * 0.05,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24), // 四角大圆角
        child: Container(
          color: Colors.white, // 卡片背景
          width: size.width * 0.9,
          height: size.height * 0.8,
          child: Column(
            children: [
              /// 上方 glb 模型展示
              FutureBuilder(
                future: () async {
                  try {
                    final response = await globalDio.head(
                      'https://www.robot-shadow.cn/src/pkg/Fymew/img/logo.glb',
                    );
                    if (response.statusCode == 200) {
                      debugPrint('请求成功');
                      return true;
                    } else {
                      debugPrint('请求失败，状态码: ${response.statusCode}');
                      return false;
                    }
                  } catch (e) {
                    debugPrint('请求异常: $e');
                    return false;
                  }
                }(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: size.height * 0.45,
                      child: SpinKitCircle(
                        size: min(size.width * 0.4, size.height * 0.4),
                        color: Colors.lightBlue,
                      ),
                    );
                  }
                  if (snapshot.data == true) {
                    return SizedBox(
                      height: size.height * 0.45,
                      child: const ModelViewer(
                        rotationPerSecond: "30deg",
                        autoPlay: true,
                        backgroundColor: Colors.transparent,
                        src:
                            'https://www.robot-shadow.cn/src/pkg/Fymew/img/logo.glb',
                        alt: '3D model of logo',
                        loading: Loading.lazy,
                        exposure: 1.0,
                        shadowIntensity: 0.5,
                        shadowSoftness: 0.5,
                        poster:
                            'https://www.robot-shadow.cn/src/pkg/Fymew/img/splash_1024.png',
                        ar: false,
                        arModes: ['scene-viewer', 'webxr', 'quick-look'],
                        autoRotate: true,
                        disableZoom: false,
                      ),
                    );
                  } else {
                    return SizedBox(
                      height: size.height * 0.45,
                      child: Image.asset('assets/img/splash_1024.png'),
                    );
                  }
                },
              ),

              /// 下方信息
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Fymew",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "版本号: ",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              "1.0.0",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "GitHub: ",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  if (!await launchUrl(Uri.parse(url))) {
                                    debugPrint('Could not launch $url');
                                  }
                                },
                                child: const Text(
                                  "点击直达",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Fymew (音：/faɪ mjuː/)，是Fly music的近音提取，意为轻盈、自由的听音乐。",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 关闭按钮
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    label: const Text("关闭"),
                    icon: const Icon(Icons.close),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red, // 蓝色背景
                      foregroundColor: Colors.white, // 白色文字和图标
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // 按钮圆角
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
