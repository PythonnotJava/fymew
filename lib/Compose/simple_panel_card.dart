import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../Logic/global_config.dart';
import '../Logic/music_info_reader.dart' show MusicInfoReader;
import '../Logic/click_mode_controller.dart' show ClickModeController;

class SimplePanelCard extends StatefulWidget {
  /// 绑定的信息
  final MusicInfoReader info;
  final IconData? defaultIcon;
  final Color? defaultIconColor;

  /// 绑定的信息被从当前Panel移除的触发回调
  final void Function(MusicInfoReader info, BuildContext onPressedContext)
  whenInfoRemoveCallBack;

  /// 可以额外添加的一个功能按键
  final SlidableAction? moreSlidableAction;

  /// 卡片被点击回调
  final void Function()? onTopCallback;

  final Color? color;
  const SimplePanelCard({
    super.key,
    required this.info,
    this.defaultIcon,
    required this.whenInfoRemoveCallBack,
    this.moreSlidableAction,
    this.color,
    this.onTopCallback,
    this.defaultIconColor,
  });

  @override
  State<StatefulWidget> createState() => SimplePanelCardState();
}

class SimplePanelCardState extends State<SimplePanelCard> {
  late final List<SlidableAction> childrenOfSlidable;

  @override
  void initState() {
    childrenOfSlidable = [
      SlidableAction(
        onPressed: (c) => widget.whenInfoRemoveCallBack(widget.info, c),
        backgroundColor: Colors.pink[100]!,
        foregroundColor: widget.defaultIconColor ?? Colors.black,
        icon: widget.defaultIcon ?? Icons.delete,
        label: '移除',
      ),
    ];
    if (widget.moreSlidableAction != null) {
      childrenOfSlidable.insert(0, widget.moreSlidableAction!);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final ClickModeController clickModeController = context
        .watch<ClickModeController>();

    return Padding(
      key: widget.key,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.0),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        color: (widget.color ?? Colors.lightBlue[50])!.withValues(
          alpha: cardOpacity,
        ),
        child: InkWell(
          onTap: clickModeController.isSingleClicked
              ? widget.onTopCallback
              : null,
          onDoubleTap: !clickModeController.isSingleClicked
              ? widget.onTopCallback
              : null,
          borderRadius: BorderRadius.circular(12),
          splashColor: Color.fromARGB(200, 240, 240, 240),
          child: Slidable(
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: childrenOfSlidable,
            ),

            child: ListTile(
              leading: Padding(
                padding: const EdgeInsets.only(
                  left: 5,
                  right: 5,
                  top: 2.5,
                  bottom: 2.5,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image(
                      image: FileImage(File(info.coverPath)),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
              title: Text('${info.title} - ${info.artist}'),
            ),
          ),
        ),
      ),
    );
  }
}
