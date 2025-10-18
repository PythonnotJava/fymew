part of 'panel.dart';

/// 队列路由
class QueuePanelViewer extends StatefulWidget {
  final PanelData panelData;
  const QueuePanelViewer({super.key, required this.panelData});

  @override
  State<StatefulWidget> createState() => QueuePanelViewerState();
}

class QueuePanelViewerState extends State<QueuePanelViewer> {
  late final PlayerController playerController;
  late final PanelData panelData;

  @override
  void initState() {
    playerController = Provider.of<PlayerController>(context, listen: false);
    panelData = widget.panelData;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          panelData.title,
          style: TextStyle(fontWeight: FontWeight.w700, color: panelData.color),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              if (playerController.queue.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('队列暂无歌曲。'),
                    duration: Duration(seconds: 1),
                  ),
                );
                return;
              }
              await showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('提示'),
                    content: const Text('确定全清空？'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('取消'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('确定'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          clearQueue(context, playerController);
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Text('清空队列', style: TextStyle(color: panelData.color)),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<PlayerController>(
          builder: (_, playerController, __) {
            final queue = playerController.queue;
            if (queue.isEmpty) {
              return const EmptyStateWidget(title: Text('你的队列中空空如也'));
            }
            final core = ReorderableListView.builder(
              itemBuilder: (context, index) {
                final MusicInfoReaderWithUniqueKey
                musicInfoReaderWithUniqueKey = queue[index];
                return Selector<PlayerController, bool>(
                  key: ValueKey(musicInfoReaderWithUniqueKey.uniqueKey),
                  selector: (_, controller) {
                    return controller.queueIndex == index &&
                        controller.currentMusicInfo ==
                            musicInfoReaderWithUniqueKey.info;
                  },
                  builder: (context, isCurrent, child) {
                    return SimplePanelCard(
                      info: musicInfoReaderWithUniqueKey.info,
                      whenInfoRemoveCallBack: (_, _) async {
                        return whenDeleteQueueCard(
                          playerController,
                          isCurrent,
                          index,
                        );
                      },
                      color: isCurrent ? Colors.blue[300] : null,
                      onTopCallback: () async => onTopCallback(
                        musicInfoReaderWithUniqueKey.info,
                        playerController,
                        isCurrent,
                        index,
                      ),
                    );
                  },
                );
              },
              itemCount: queue.length,
              onReorder: (int oldIndex, int newIndex) async {
                if (newIndex > oldIndex) newIndex--;
                final moveInfo = playerController.queue.removeAt(oldIndex);
                final relativeIndex = playerController.queueIndex;

                /// 以下情况需要考虑
                /// 1. 如果是正在播放的歌曲被移动
                /// 2. 正在播放歌曲A前面的歌曲B被移动到A后面
                /// 3. 正在播放歌曲A后面的歌曲B被移动到A前面
                if (relativeIndex == oldIndex) {
                  playerController.queueIndex = newIndex;
                } else if (oldIndex < relativeIndex &&
                    newIndex >= relativeIndex) {
                  playerController.queueIndex--;
                } else if (oldIndex > relativeIndex &&
                    newIndex <= relativeIndex) {
                  playerController.queueIndex++;
                }
                playerController.queue.insert(newIndex, moveInfo);
              },

              /// 被拖动的时候的外观处理
              proxyDecorator:
                  (Widget child, int index, Animation<double> animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (BuildContext context, Widget? child) {
                    final double animValue = Curves.easeInOut.transform(
                      animation.value,
                    );

                    /// 动态阴影
                    final double elevation = ui.lerpDouble(
                      1,
                      6,
                      animValue,
                    )!;

                    /// 轻微缩放
                    final double scale = ui.lerpDouble(
                      1,
                      1.02,
                      animValue,
                    )!;

                    /// 动态边框宽度
                    final double borderWidth = ui.lerpDouble(
                      0,
                      2,
                      animValue,
                    )!;

                    return Transform.scale(
                      scale: scale,
                      child: Material(
                        elevation: elevation,
                        borderRadius: BorderRadius.circular(15),
                        clipBehavior: Clip.antiAlias,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              /// 边框颜色
                              color: Colors.blueAccent.withValues(
                                alpha: cardOpacity,
                              ),

                              /// 动态边框宽度
                              width: borderWidth,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  child: child,
                );
              },
            );
            return Stack(children: [backgroundBuilder(), core],);
          },
        ),
      ),
    );
  }

  /// 点击队列歌曲跳转到当前索引并且播放，如果是正在播放的被点击则忽视
  Future<void> onTopCallback(
    MusicInfoReader info,
    PlayerController playerController,
    bool isCurrent,
    int clickIndex,
  ) async {
    if (!isCurrent) {
      playerController
        ..updateInfoByExist(
          info,
          playerController.currentIndex,
          forceRestart: true,
          shouldPlay: true,
        )
        ..queueIndex = clickIndex;
      debugPrint('重新定向播放队列歌曲${info.musicPath}。');
    } else {
      debugPrint('当前队列歌曲${info.musicPath}已经在播放了。');
    }
  }

  /// 当删除队列的歌曲
  Future<void> whenDeleteQueueCard(
    PlayerController playerController,
    bool isCurrent,
    int clickIndex,
  ) async {
    /// 考虑优先级
    /// 先考虑：当队列还没开始调度
    if (playerController.queueIndex == -1) {
      playerController.removeItemAtQueue(clickIndex);
      debugPrint(
        "该歌曲当队列还没开始调度被删除，当前queueIndex = ${playerController.queueIndex}，queueLength = ${playerController.queue.length}。",
      );
      return;
    }

    /// 点击正在播放的是队尾的情况则重置队列且切换下一首
    if (playerController.isQueueEnd && isCurrent) {
      playerController
        ..resetQueue()
        ..next();
      debugPrint(
        "正在播放的是队尾，队列清空，当前queueIndex = ${playerController.queueIndex}，queueLength = ${playerController.queue.length}。",
      );
      return;
    }

    /// 是其他正在播放的队列歌曲
    if (isCurrent) {
      playerController.queue.removeAt(clickIndex);
      final musicInfoReaderWithUniqueKey = playerController.queue[clickIndex];
      playerController.updateInfoByExist(
        musicInfoReaderWithUniqueKey.info,
        playerController.currentIndex,
        forceRestart: true,
        shouldPlay: true,
      );
      debugPrint(
        '正在播放的队列歌曲已删除，当前queueIndex = ${playerController.queueIndex}，queueLength = ${playerController.queue.length}。',
      );
      return;
    }

    /// 正在播放的歌曲后面的歌曲不用考虑队列索引调整，播放歌曲前面的就需要了
    if (clickIndex < playerController.queueIndex) {
      playerController
        ..removeItemAtQueue(clickIndex)
        ..queueIndex -= 1;
      debugPrint(
        '正在播放的队列歌曲之前的歌曲已删除，当前queueIndex = ${playerController.queueIndex}，queueLength = ${playerController.queue.length}。',
      );
    } else {
      playerController.removeItemAtQueue(clickIndex);
      debugPrint(
        '正在播放的队列歌曲之后的歌曲已删除，当前queueIndex = ${playerController.queueIndex}，queueLength = ${playerController.queue.length}。',
      );
    }
  }
}
