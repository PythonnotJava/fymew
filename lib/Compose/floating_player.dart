import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';

import '../Logic/global_config.dart';
import 'rorate_circle.dart' show RotatingCircleImage;
import '../Logic/play_controller.dart' show PlayerController;
import 'setting_sheet.dart';

class FloatingPlayerController extends ChangeNotifier {
  double top = 200;
  double? left;
  double? right;
  bool _expanded = false;

  void toggleExpanded(bool expand) {
    _expanded = expand;
    notifyListeners();
  }

  bool get expanded => _expanded;

  set expand(bool v) => _expanded = v;
}

/// 全局 Overlay 悬浮球管理器（安全版本）
class FloatingPlayerManager {
  static final FloatingPlayerManager _instance =
      FloatingPlayerManager._internal();
  factory FloatingPlayerManager() => _instance;
  FloatingPlayerManager._internal();

  OverlayEntry? _entry;

  /// 安全插入 Overlay
  void show(BuildContext context) {
    if (_entry != null) return;

    _entry = OverlayEntry(builder: (context) => const FloatingPlayer());

    /// 延迟到下一帧插入，避免渲染冲突
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Overlay.of(context).insert(_entry!);
    });
  }

  /// 移除 Overlay
  void hide() {
    _entry?.remove();
    _entry = null;
  }

  /// 安全刷新 Overlay
  void markNeedsBuild() {
    if (_entry == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entry?.markNeedsBuild();
    });
  }
}

/// 悬浮球 Widget
class FloatingPlayer extends StatefulWidget {
  const FloatingPlayer({super.key});

  @override
  State<FloatingPlayer> createState() => FloatingPlayerState();
}

class FloatingPlayerState extends State<FloatingPlayer> {
  late double opacity;
  late bool absorbing;

  bool get isHideSelf => opacity == 0.0;

  @override
  void initState() {
    opacity = 1.0;
    absorbing = false;
    Provider.of<PlayerController>(context, listen: false).bindMaps[1] = this;
    super.initState();
  }

  void justHide() {
    if (opacity != 0.0 && !absorbing){
      setState(() {
        debugPrint("隐藏了");
        opacity = 0.0;
        absorbing = true;
      });
    }
  }

  void justShow() {
    if (opacity == 0.0 && absorbing) {
      setState(() {
        opacity = 1.0;
        absorbing = false;
        debugPrint("显示了");
      });
    }
  }

  Widget _floatingButton() {
    return Consumer<FloatingPlayerController>(
      builder: (_, floatingPlayerController, __) {
        return AbsorbPointer(
          absorbing: absorbing,
          child: AnimatedOpacity(
            opacity: opacity,

            /// 动画时长，控制隐形
            duration: const Duration(milliseconds: 801),
            child: GestureDetector(
              onTap: () => floatingPlayerController.toggleExpanded(true),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 6),
                    ],
                  ),
                  child: const Icon(Icons.menu, color: Colors.white),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _expandPlayer() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<FloatingPlayerController>(
      builder: (_, floatingPlayerController, __) {
        return AbsorbPointer(
          absorbing: absorbing,
          child: AnimatedOpacity(
            opacity: opacity,
            duration: const Duration(milliseconds: 300),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(5.0),
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.lightBlue[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Consumer<PlayerController>(
                  builder: (_, PlayerController playerController, __) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          child: RotatingCircleImage(
                            coverPath:
                                playerController.currentMusicInfo.coverPath,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    isPlatformWithMobile && screenWidth <= 500
                                    ? screenWidth * 0.75
                                    : screenWidth * 0.5,
                              ),
                              child: SizedBox(
                                height: 20,
                                child: Marquee(
                                  text:
                                      '${playerController.currentMusicInfo.title} - ${playerController.currentMusicInfo.artist}.',
                                  style: const TextStyle(color: Colors.black),
                                  scrollAxis: Axis.horizontal,
                                  velocity: 30,
                                  pauseAfterRound: const Duration(seconds: 1),
                                  startPadding: 10,
                                  blankSpace: 50,
                                  accelerationDuration: const Duration(
                                    seconds: 1,
                                  ),
                                  accelerationCurve: Curves.linear,
                                  decelerationDuration: const Duration(
                                    seconds: 1,
                                  ),
                                  decelerationCurve: Curves.easeOut,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => playerController.previous(
                                    previousIsClicked: true,
                                  ),
                                  icon: const Icon(Icons.skip_previous),
                                ),
                                IconButton(
                                  onPressed: () => playerController.playOrPause(),
                                  icon: Icon(
                                    playerController.isPaused
                                        ? Icons.play_arrow
                                        : Icons.pause,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => playerController.next(
                                    nextIsClicked: true,
                                  ),
                                  icon: const Icon(Icons.skip_next),
                                ),
                                IconButton(
                                  onPressed: () async => await showPopMenu(),
                                  icon: const Icon(Icons.settings),
                                ),
                                IconButton(
                                  onPressed: () => floatingPlayerController
                                      .toggleExpanded(false),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 点击设置按钮的时候，弹出半边对话框
  Future<void> showPopMenu() async {
    /// 在弹出对话框前隐藏浮动球
    justHide();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 允许高度自定义
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SettingSheet();
      },
    );

    /// 之后在再显示浮动球
    justShow();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final paddingTop = mediaQuery.padding.top;
    final paddingBottom = mediaQuery.padding.bottom;
    final bodyHeight = screenHeight - paddingTop - paddingBottom;

    return Consumer<FloatingPlayerController>(
      builder: (_, floatingPlayerController, __) {
        return Positioned(
          top: floatingPlayerController.top + paddingTop,
          left: floatingPlayerController.left,
          right: floatingPlayerController.right,
          child: Draggable(
            feedback: floatingPlayerController.expanded
                ? _expandPlayer()
                : _floatingButton(),
            childWhenDragging: const SizedBox(),
            onDragEnd: (details) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                double newLeft = details.offset.dx;
                double newTop = details.offset.dy - paddingTop;
                bool rightSide = newLeft + 30 > screenWidth / 2;

                setState(() {
                  floatingPlayerController.top = newTop.clamp(
                    0.0,
                    bodyHeight - (floatingPlayerController.expanded ? 100 : 60),
                  );
                  if (rightSide) {
                    floatingPlayerController.left = null;
                    floatingPlayerController.right = 0;
                  } else {
                    floatingPlayerController.left = 0;
                    floatingPlayerController.right = null;
                  }
                });
              });
            },
            child: floatingPlayerController.expanded
                ? _expandPlayer()
                : _floatingButton(),
          ),
        );
      },
    );
  }
}
