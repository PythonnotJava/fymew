import 'dart:io';

import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';

import '../Logic/global_config.dart';
import '../Logic/play_controller.dart';
import 'play_list_searcher.dart';
import '../Logic/music_info_reader.dart' show MusicInfoReader;
import 'floating_player.dart';

class SettingSheet extends StatefulWidget {
  const SettingSheet({super.key});

  @override
  State<StatefulWidget> createState() => SettingSheetState();
}

class SettingSheetState extends State<SettingSheet> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerController>(
      builder: (_, playerController, __) {
        PlaybackMode playbackMode = playerController.playbackMode;
        final coverPath = playerController.currentMusicInfo.coverPath;
        final text =
            '${playerController.currentMusicInfo.title} - ${playerController.currentMusicInfo.artist}.';
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (builderContext, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      Image.file(File(coverPath), width: 80, height: 80),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 20,
                          child: Marquee(
                            text: text,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: platformDefaultFontSize,
                            ),
                            scrollAxis: Axis.horizontal,
                            velocity: 30,
                            pauseAfterRound: const Duration(seconds: 1),
                            startPadding: 10,
                            blankSpace: 50,
                            accelerationDuration: const Duration(seconds: 1),
                            accelerationCurve: Curves.linear,
                            decelerationDuration: const Duration(seconds: 1),
                            decelerationCurve: Curves.easeOut,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ExpansionTile(
                    title: const Text('播放模式'),
                    leading: const Icon(Icons.local_play),
                    children: [
                      ListTile(
                        leading: Icon(
                          playbackMode == PlaybackMode.sequence
                              ? Icons.circle
                              : Icons.circle_outlined,
                        ),
                        title: const Text("\t\t顺序播放"),
                        onTap: () async {
                          if (playerController.playbackMode !=
                              PlaybackMode.sequence) {
                            playerController.updateMode(PlaybackMode.sequence);
                            mgrPreMusicData['playbackMode'] = 0;
                            await saveMgrSrcData(key: 'music');

                            /// 切到该模式则重设队列
                            playerController.resetQueue();
                          }
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          playbackMode == PlaybackMode.random
                              ? Icons.circle
                              : Icons.circle_outlined,
                        ),
                        title: const Text("\t\t随机歌曲"),
                        onTap: () async {
                          if (playerController.playbackMode !=
                              PlaybackMode.random) {
                            playerController.updateMode(PlaybackMode.random);
                            mgrPreMusicData['playbackMode'] = 1;
                            await saveMgrSrcData(key: 'music');

                            /// 该模式不允许且清空队列
                            playerController.resetQueue();
                          }
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          playbackMode == PlaybackMode.loopOne
                              ? Icons.circle
                              : Icons.circle_outlined,
                        ),
                        title: const Text("\t\t单曲循环"),
                        onTap: () async {
                          if (playerController.playbackMode !=
                              PlaybackMode.loopOne) {
                            playerController.updateMode(PlaybackMode.loopOne);
                            mgrPreMusicData['playbackMode'] = 2;
                            await saveMgrSrcData(key: 'music');

                            /// 该模式不允许且清空队列
                            playerController.resetQueue();
                          }
                        },
                      ),
                    ],
                  ),
                  ListTile(
                    leading: const Icon(Icons.repeat),
                    title: const Text('临时重播'),
                    enabled: !playerController.currentMusicInfo.anySign
                        .containsKey('again'),
                    onTap: () => playerController.allowAgainTemp(
                      playerController.currentMusicInfo,
                    ),
                  ),
                  Selector<PlayerController, bool>(
                    selector: (_, controller) {
                      /// 乐库为空、处于默认音乐、播放非乐库模式都不能从浮动球删除歌曲、在线歌曲（播放一次的）也不能删除
                      return controller.isEmptyOrDefault() ||
                          !controller.isPlayingLib ||
                          controller.isPlayingQueue ||
                          controller.isPlayingOnlineOneTime;
                    },
                    builder: (_, banDelete, __) {
                      if (banDelete) {
                        return const ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('删除歌曲'),
                          onTap: null,
                          enabled: false,
                        );
                      }
                      return ListTile(
                        leading: const Icon(Icons.delete),
                        title: const Text('删除歌曲'),
                        onTap: () async {
                          final info = playerController.currentMusicInfo;

                          /// 如果是网络来源歌曲，只需要删除卡片和列表中的Info即可
                          if (info.anySign.containsKey('web')) {
                            if (info.anySign['web'] == 1) {
                              await confirmDeleteMusic(
                                builderContext,
                                playerController,
                                isTemp: true,
                              );
                              return;
                            }
                            debugPrint('如果是网络来源歌曲，只需要删除卡片和列表中的Info即可');
                          } else {
                            await confirmDeleteMusic(
                              builderContext,
                              playerController,
                            );
                          }
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.touch_app_rounded),
                    title: const Text('随机跳转进度'),
                    onTap: () => playerController.seekToPercent(
                      playerController.randomGenerate.nextDouble(),
                    ),
                  ),

                  ListTile(
                    leading: const Icon(Icons.image_search_rounded),
                    title: const Text('界面背景设置'),
                    onTap: () async {
                      final MusicPlayerListState musicPlayerListState =
                          playerController.bindMaps[0] as MusicPlayerListState;
                      await musicPlayerListState.refreshBgImg();
                    },
                  ),
                  /// 播放速度
                  ExpansionTile(
                    title: const Text('播放速度'),
                    leading: const Icon(Icons.speed),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            const Text("0.5x"),
                            Expanded(
                              child: Slider(
                                value: playerController.playSpeed,
                                min: 0.5,
                                max: 2.0,
                                divisions: 6,
                                label: "${playerController.playSpeed.toStringAsFixed(2)}x",
                                onChanged: (value) async {
                                  await playerController.setSpeed(value);
                                },
                              ),
                            ),
                            Text("2.0x"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ListTile(
                    leading: const Icon(Icons.touch_app_rounded),
                    title: const Text('跳转95%进度'),
                    onTap: () => playerController.seekToPercent(
                      0.95,
                    ),
                  ),

                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// 确认删除一首歌曲
Future<void> confirmDeleteMusic(
  BuildContext context,
  PlayerController playerController, {
  MusicInfoReader? pointInfo,

  /// 这个声明是在线的临时音乐
  bool isTemp = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (builderContext) {
      return AlertDialog(
        title: const Text("确认删除"),
        content: const Text("你确定要删除吗？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(builderContext).pop(false),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () => Navigator.of(builderContext).pop(true),
            child: const Text("删除", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;
  final info = pointInfo ?? playerController.currentMusicInfo;
  int currentPlayingIndex0 = playerController.playLists.indexOf(info);

  /// 删除 MusicInfoReader 的缓存和记录
  /// 收藏记录（如有的话）
  /// 从总乐库播放列表中移除
  if (!isTemp) {
    await info.deleteSelf();
  }
  if (playerController.favorsMap.containsKey(info.musicPath)) {
    await playerController.removeFavorItem(info);
    debugPrint('是收藏歌曲，删了');
  }
  int indexInTotal = playerController.playTotalLib.indexOf(info);
  playerController.playTotalLib.removeAt(indexInTotal);

  /// 同步 [MusicPlayerList] 的 _filterCards来删除Card
  if (context.mounted) {
    final MusicPlayerListState musicPlayerListState =
        playerController.bindMaps[0] as MusicPlayerListState;
    if (musicPlayerListState.mounted) {
      /// 刷新乐库列表
      musicPlayerListState.updateCardsByController();
      debugPrint('删除后刷新了乐库列表');
    }
  } else {
    debugPrint('没触发，需要检测异常点。');
    return;
  }

  bool isPlaying = playerController.isPlaying;
  debugPrint(
    'isPlaying = $isPlaying, len of PlayListTotal == ${playerController.playTotalLib.length}',
  );

  /// 当前播放列表的索引
  int currentPlayingIndex = playerController.isPlayingLib
      ? indexInTotal
      : currentPlayingIndex0;

  /// 这时候歌曲信息已经从乐库以及归属列表删除（队列除外）
  /// 如果删除的是当前播放列表的歌曲，停止播放并切换到下一首歌曲（如果有），否则设置为默认音乐
  /// 如果在播放，后面的歌曲继续播放，如果本来没播放，后面也不播放
  if (playerController.currentMusicInfo == info) {
    debugPrint('情况1');

    /// 如果在播放队列
    if (playerController.isPlayingQueue) {
      debugPrint('情况1-1');
      late final int newIndex;

      /// 在当前的播放列表中同步进度
      if (playerController.playLists.isEmpty) {
        debugPrint('情况1-1-1');
        newIndex = -1;
      } else {
        debugPrint('情况1-1-2');
        newIndex = currentPlayingIndex >= playerController.playLists.length
            ? 0
            : currentPlayingIndex;
      }
      playerController.updateInfoByExist(
        info,
        newIndex,
        shouldPlay: isPlaying,
        forceRestart: false,
      );
      debugPrint(
        '>>> 队列模式中\t删除不影响队列\t当前播放列表索引为：${playerController.currentPlayTarget}\t已切换到歌曲索引： $newIndex',
      );
    } else {
      /// 非队列模式
      debugPrint('情况1-2');
      if (playerController.playLists.isNotEmpty) {
        debugPrint('情况1-2-1');
        final newIndex =
            currentPlayingIndex >= playerController.playLists.length
            ? 0
            : currentPlayingIndex;
        debugPrint(
          '此时currentPlayingIndex = $currentPlayingIndex, newIndex = $newIndex',
        );
        final newInfo = playerController.playLists[newIndex];
        if (isPlaying) {
          debugPrint('情况1-2-1-1');
          await playerController.stopAudioPlayer();
          await playerController.updateInfoByExist(newInfo, newIndex);
        } else {
          debugPrint('情况1-2-1-2， 且newInfo = ${newInfo.musicPath}');
          await playerController.justUpdateMusicAndIndex(newInfo, newIndex);
        }
        debugPrint(
          '>>> 非队列模式中\t当前播放列表索引为：${playerController.currentPlayTarget}\t已切换到歌曲索引:$newIndex',
        );
      } else {
        debugPrint('情况1-2-2');

        /// 无歌曲时切换直接播放默认歌曲
        await playerController.updateInfoByExist(
          MusicInfoReader.defaultReplace,
          -1,
        );
        debugPrint(
          '>>> 非队列模式中\t当前播放列表索引为：${playerController.currentPlayTarget}\t无歌曲时切换到默认歌曲',
        );
      }

      /// 刷新同步FloatingPlayer
      FloatingPlayerManager().markNeedsBuild();
    }
  } else {
    debugPrint('情况2');

    /// 不是在播放的歌曲被删除时是在播放的歌曲被删除时
    debugPrint('不是在播放的歌曲被删除时');
    final playingIndex = playerController.currentIndex;

    /// 在播放的前面的歌曲被删除
    if (playingIndex > currentPlayingIndex) {
      debugPrint('情况2-1');
      playerController.setCurrentIndex(playingIndex - 1);
    }
  }

  /// 删除的是需要临时重播的歌曲
  if (info.anySign.containsKey('again')) {
    info.anySign.remove('again');
  }
}
