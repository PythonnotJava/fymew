import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' show Random, min;
import 'dart:typed_data' show Uint8List;
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import 'package:image/image.dart' as image;
import 'package:cached_network_image/cached_network_image.dart';

import 'floating_player.dart';
import 'background_builder.dart';
import 'play_list_searcher.dart';
import '../Logic/play_controller.dart';
import '../Logic/music_info_reader.dart';
import 'simple_panel_card.dart' show SimplePanelCard;
import 'song_card_item.dart' show clearQueue;
import 'empty_widget.dart';
import 'web_loader.dart'
    show loadFromWebCompletely, downloadOnlineFileToTempDir;
import 'timer_dialog.dart' show createTimerDialogCompletely;
import 'debug_viewer.dart' show showDebugViewer;
import '../Logic/global_config.dart';

part 'music_wrapper.dart';
part 'queue_panel_view.dart';
part 'favor_panel_view.dart';
part 'expandable_container.dart';
part 'floating_expander.dart';
part 'personalized_card.dart';

/// 跳转的界面属于哪种模式
enum PanelType {
  /// 自定义模式
  custom,

  /// 我的收藏
  favor,

  /// 队列模式
  queue,
}

final class PanelData {
  final PanelType panelType;
  final Color? color;
  final String title;
  const PanelData({required this.panelType, this.color, required this.title});
}

/// Panel有五种，事件、收藏、网络载入、队列记录、自定义歌单
class Panel extends StatefulWidget {
  const Panel({
    super.key,
    required this.panelData,
    required this.imgSvgPath,
    this.opacity,
    this.deletable,
    this.needDot,
    this.finalLinearColor,
  });

  final PanelData panelData;
  final String imgSvgPath;
  final double? opacity;

  /// 是否在右上角添加一个dot按钮，默认没有
  final bool? needDot;

  /// 固定由用户创建的Panel可以删除，自带的没有删除选项
  final bool? deletable;

  /// 右下角的渐变终点色
  final Color? finalLinearColor;

  @override
  State<StatefulWidget> createState() => PanelState();
}

class PanelState extends State<Panel> {
  bool _pressed = false;

  /// 防止连点
  bool _isClickable = true;

  void _handleTap(BuildContext context) {
    if (!_isClickable) return; // 忽略重复点击

    setState(() {
      _isClickable = false;
    });

    /// 点击逻辑
    jumpToPanel(context);

    /// 1 秒后恢复可点击
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isClickable = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.panelData.color ?? Colors.blueAccent;

    final content = Stack(
      children: [
        /// 渐变背景
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.15),
                  widget.finalLinearColor ?? Colors.white,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(2, 3),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),

        /// 装饰 SVG
        Positioned(
          bottom: -10,
          right: -10,
          child: Opacity(
            opacity: widget.opacity ?? 0.2,
            child: SvgPicture.asset(
              widget.imgSvgPath,
              width: 100,
              height: 100,
              color: color,
            ),
          ),
        ),

        /// 主体内容
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_note, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                widget.panelData.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        /// 右上角菜单
        if (widget.needDot == true)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Colors.black54,
                ),
                onPressed: () {},
              ),
            ),
          ),
      ],
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _handleTap(context),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(aspectRatio: 4 / 3, child: content),
          ),
        ),
      ),
    );
  }

  /// 点击panel跳转新界面
  /// 跳转传入两个参数：跳转类型、界面名字
  void jumpToPanel(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return switch (widget.panelData.panelType) {
            PanelType.favor => FavorPanelView(panelData: widget.panelData),
            PanelType.queue => QueuePanelViewer(panelData: widget.panelData),
            PanelType.custom => const Scaffold(
              body: Center(child: Text('data')),
            ),
          };
        },
      ),
    );
  }
}
