part of 'panel.dart';

class FavorPanelView extends StatefulWidget {
  final PanelData panelData;
  const FavorPanelView({super.key, required this.panelData});

  @override
  State<StatefulWidget> createState() => FavorPanelViewState();
}

class FavorPanelViewState extends State<FavorPanelView> {
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
          IconButton(
            icon: Icon(Icons.open_in_full_outlined, color: panelData.color),
            onPressed: () async {
              await showDialog<void>(
                context: context,
                builder: (context) {
                  return playerController.favors.isEmpty
                      ? const AlertDialog(
                          title: Text('信息'),
                          content: Text('您的收藏还是空空如也的状态哦……'),
                        )
                      : AlertDialog(
                          title: Text('信息'),
                          content: JsonView.string(
                            JsonEncoder.withIndent(
                              '  ',
                            ).convert(getInfo(playerController.favors)),
                            theme: const JsonViewTheme(
                              viewType: JsonViewType.base,
                            ),
                          ),
                        );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<PlayerController>(
          builder: (_, playerController, __) {
            if (playerController.favors.isEmpty) {
              return const EmptyStateWidget(title: Text('你的收藏中空空如也'));
            }
            final core = ListView.separated(
              itemBuilder: (context, index) {
                final info = playerController.favors[index];
                return Selector<PlayerController, bool>(
                  selector: (_, controller) {
                    /// 验证是不是收藏中在播歌曲
                    return controller.currentMusicInfo == info &&
                        playerController.isPlayingFavors;
                  },
                  builder: (context, isCurrent, _) {
                    return SimplePanelCard(
                      key: ValueKey(info.id),

                      /// id和favorId都可以，因为都是当前启动下不变且唯一的
                      info: info,
                      whenInfoRemoveCallBack: (info, context) async =>
                          await whenCencelFavorItem(
                            playerController,
                            info,
                            isCurrent,
                          ),
                      defaultIcon: Icons.favorite_border,
                      defaultIconColor: Colors.blueGrey,
                      color: isCurrent ? Colors.orange[200] : null,
                      onTopCallback: () async {
                        if (!playerController.isPlayingFavors) {
                          await playerController.setPlaylist(1);
                          playerController.setCurrentIndex(index);

                          /// 切换到收藏并且是正在播放的歌曲
                          if (mounted && isCurrent) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '切换到收藏模式且被点击歌曲已经在播放了，当前索引:$index。',
                                ),
                                duration: const Duration(milliseconds: 500),
                              ),
                            );
                          }
                          debugPrint('切换到收藏模式');
                        }
                        if (!isCurrent) {
                          playerController.updateInfoByExist(info, index);

                          /// 队列是否全播放检测
                          if (playerController.isQueueEnd) {
                            playerController.resetQueue();
                          }
                        } else {
                          if (!playerController.isPlaying) {
                            playerController.updateInfoByExist(info, index);
                            debugPrint('点击开始播放了');
                          } else {
                            debugPrint('已经在播放了');
                          }
                        }
                      },
                    );
                  },
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: 3),
              itemCount: playerController.favors.length,
            );
            return Stack(children: [backgroundBuilder(), core]);
          },
        ),
      ),
    );
  }
}

/// 当歌曲被取消收藏
Future<void> whenCencelFavorItem(
  PlayerController playerController,
  MusicInfoReader info,
  bool isCurrent,
) async {
  /// 是否播放的是收藏列表
  /// 不是的情况
  if (!playerController.isPlayingFavors) {
    debugPrint('从收藏（收藏未调用）中移除歌曲：${info.musicPath}');
    return await playerController.removeFavorItem(info, notify: true);
  }

  final clickIndex = playerController.playLists.indexOf(info);
  debugPrint("处于列表${playerController.currentPlayTarget}的索引: $clickIndex");

  /// 是的情况
  /// 取消的是正在播放且是唯一一首则换到默认音乐
  bool isPlaying = playerController.isPlaying;
  final len = playerController.favors.length;
  debugPrint("正在取消收藏，取消前播放器状态是：$isPlaying，favors长度为：$len");

  if (isCurrent && len == 1) {
    playerController.removeFavorItem(info);
    playerController.updateInfoByExist(
      MusicInfoReader.defaultReplace,
      -1,
      shouldPlay: isPlaying,
      forceRestart: true,
    );
    return debugPrint('取消收藏的是正在播放且是唯一一首则换到默认音乐');
  }

  /// 取消的是处于播放状态的歌曲
  if (isCurrent) {
    await playerController.removeFavorItem(info);

    /// 切换到下一首歌曲
    final newIndex = clickIndex >= playerController.playLists.length
        ? 0
        : clickIndex;
    final newInfo = playerController.playLists[newIndex];
    if (isPlaying) {
      await playerController.stopAudioPlayer();
      await playerController.updateInfoByExist(
        newInfo,
        newIndex,
        forceRestart: true,
        shouldPlay: true,
      );
    } else {
      await playerController.justUpdateMusicAndIndex(newInfo, newIndex);
    }
    return debugPrint('取消收藏的是处于播放状态的歌曲，其索引$clickIndex');
  }

  /// 取消的是处于播放状态前面的歌曲
  if (clickIndex < playerController.currentIndex) {
    playerController.setCurrentIndex(playerController.currentIndex - 1);
    await playerController.removeFavorItem(info, notify: true);
    return debugPrint('取消收藏的是处于播放状态的前面的歌曲');
  }

  /// 取消的是处于播放状态的后面的歌曲
  await playerController.removeFavorItem(info, notify: true);
  return debugPrint('取消收藏的是处于播放状态的后面的歌曲');
}

/// 获取收藏信息
/// 其中包括：收藏量、收藏中最早导入歌曲、收藏中最晚导入歌曲
Map<String, String> getInfo(List<MusicInfoReader> favors) {
  final sortedList = List<MusicInfoReader>.from(favors)
    ..sort(
      (a, b) => parseCustomDateTime(
        a.loadTime,
      ).compareTo(parseCustomDateTime(b.loadTime)),
    );
  int len = sortedList.length;
  return len != 1
      ? {
          "收藏量": len.toString(),
          "收藏中最早导入的歌曲是": sortedList.first.title,
          "收藏中最早导入的歌曲时间是": sortedList.first.loadTime,
          "收藏中最晚导入的歌曲是": sortedList.last.title,
          "收藏中最晚导入的歌曲时间是": sortedList.last.loadTime,
        }
      : {
          "收藏量": '1',
          "收藏中唯一的歌曲是": sortedList.first.title,
          "收藏中唯一的歌曲导入的时间是": sortedList.first.loadTime,
        };
}
