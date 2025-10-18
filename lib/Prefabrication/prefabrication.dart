import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../Compose/play_list_searcher.dart';
import '../Logic/music_info_reader.dart';
import '../Logic/global_config.dart';
import '../Compose/web_loader.dart' show downloadOnlineFileToTempDir;
import '../Logic/play_controller.dart';

part 'web_widget.dart';
part 'yearly_widget.dart';
part 'recomment_widget.dart';

void showSnackBar(String text, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), duration: const Duration(milliseconds: 500)),
  );
}

/// 预制控件系统，由于Fymew没有复杂的后端服务系统，全靠在线的Json获取请求进行对应更新，因此特制了对应请求展示用的UI控件
enum PrefabricationType {
  /// 音乐推荐系统
  recommend,

  /// 新闻系统
  news,

  /// 网页端
  web,

  /// 特殊——年度总结
  annualSummary,
}

/// 预制轮播专用组件
/// """
/// {type : "", cover : "", content : "", subcontent : ""}
/// """
const typeMap = {0: "歌曲推荐", 1: "新闻", 2: "年度总结", 3: "链接"};

class SwiperCard extends StatelessWidget {
  final Map<String, dynamic> json;

  const SwiperCard({super.key, required this.json});

  @override
  Widget build(BuildContext context) {
    final core = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          /// 背景图片或占位控件
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: json['cover'],
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: SpinKitFadingCircle(color: Colors.white, size: 30),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.error, size: 50, color: Colors.grey),
                ),
              ),
            ),
          ),

          /// 左上角 type
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                typeMap[json['type']]!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          /// 左下角主内容
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Text(
              json['content'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black54,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),

          /// 居中右对齐的次内容
          if (json['subcontent'] != null)
            Positioned(
              top: 0,
              bottom: 0,
              right: 8,
              child: Center(
                child: Text(
                  json['subcontent'],
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        blurRadius: 3,
                        color: Colors.black45,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final which = json['type'];
            late final Widget rt;
            if (which == 0) {
              rt = RecommentWidget(
                mimetype: json['mimetype'],
                name: json['name'],
                url: json['url'],
                description: json['description'],
              );
            } else if (which == 1) {
              rt = WebWidget(url: json['url'], title: json['title']);
            } else if (which == 2) {
              rt = const YearlyWidget();
            } else {
              rt = const Center(child: Text('意外错误'));
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => rt),
            );
          },
          child: core,
        ),
      ),
    );
  }
}
