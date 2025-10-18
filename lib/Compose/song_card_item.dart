import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_json_view/flutter_json_view.dart';

import '../Logic/click_mode_controller.dart' show ClickModeController;
import '../Logic/music_info_reader.dart';
import '../Logic/global_config.dart';
import '../Logic/play_controller.dart';
import 'setting_sheet.dart' show confirmDeleteMusic;
import 'floating_player.dart' show FloatingPlayerState;
import 'play_list_searcher.dart' show MusicPlayerListState;
import 'panel.dart' show whenCencelFavorItem;

/// Card是必定有一个歌曲的
class SongCardItem extends StatefulWidget {
  final MusicInfoReader info;
  const SongCardItem({super.key, required this.info});

  @override
  State<SongCardItem> createState() => SongCardItemState();
}

class SongCardItemState extends State<SongCardItem>
    with AutomaticKeepAliveClientMixin {
  late final MusicInfoReader info;
  late final PlayerController playerController;

  /// 是否是临时加入乐库
  late bool isTempInLib;

  @override
  void initState() {
    info = widget.info;
    playerController = Provider.of<PlayerController>(context, listen: false);
    isTempInLib = info.anySign.containsKey('web');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    debugPrint("卡片重构");

    /// SongCard只能放在乐库中，因此index是乐库的当前索引
    final index = playerController.playTotalLib.indexOf(info);
    return Padding(
      key: widget.key,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeightForPlatform),
        child: Selector<PlayerController, bool>(
          selector: (_, PlayerController playerController) {
            /// 检测：点击的歌曲是不是正在播放的歌曲
            return playerController.currentMusicInfo.musicPath ==
                info.musicPath;
          },
          builder: (BuildContext selectorContext, bool isCurrentClicked, _) {
            Future<void> click() async {
              /// 点击播放歌曲
              /// 如果不是乐库列表，则切回，并且保存之前列表模式的索引
              if (!playerController.isPlayingLib) {
                await playerController.setPlaylist(0);
                playerController.setCurrentIndex(index);
                if (isCurrentClicked) {
                  _whenNotInTotal();
                }
                debugPrint('切换到乐库模式，当前索引:$index');
              }
              if (!isCurrentClicked) {
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
            }

            return Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: isCurrentClicked
                  ? Colors.pink[200]!.withValues(alpha: cardOpacity)
                  : Color.fromRGBO(240, 240, 240, cardOpacity),
              child: Consumer<ClickModeController>(
                builder: (_, clickModeController, __) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    splashColor: Color.fromARGB(200, 240, 240, 240),
                    onTap: clickModeController.isSingleClicked ? click : null,
                    onDoubleTap: !clickModeController.isSingleClicked
                        ? click
                        : null,
                    child: Row(
                      children: [
                        SizedBox(
                          height: maxHeightForPlatform - 10,
                          width: maxHeightForPlatform - 10,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image(
                              image: FileImage(File(info.coverPath)),
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 4,
                          child: Text(
                            '${info.title} - ${info.artist}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: platformDefaultFontSize,
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: PopupMenuButton<int>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (int value) async {
                              switch (value) {
                                /// 加入队列
                                case 0:
                                  if (playerController.playbackMode !=
                                      PlaybackMode.sequence) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('请先切换到顺序播放。'),
                                        duration: const Duration(
                                          milliseconds: 800,
                                        ),
                                      ),
                                    );
                                    break;
                                  }
                                  playerController.queue.add(
                                    MusicInfoReaderWithUniqueKey.generate(info),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('加入队列成功'),
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                    ),
                                  );
                                  break;

                                /// 隐藏展示浮动球
                                case 1:
                                  final fs =
                                      playerController.bindMaps[1]
                                          as FloatingPlayerState;
                                  if (fs.isHideSelf) {
                                    fs.justShow();
                                  } else {
                                    fs.justHide();
                                  }
                                  debugPrint('隐藏展示浮动球');
                                  break;

                                /// 收藏歌曲
                                case 2:

                                  /// 先查看收藏状态
                                  final isFavor = info.favorId != null;
                                  if (!isFavor) {
                                    await playerController.appendToFavor(info);
                                    debugPrint("添加了歌曲：${info.musicPath} 到我的收藏");
                                  } else {
                                    await whenCencelFavorItem(
                                      playerController,
                                      info,
                                      true,
                                    );
                                    debugPrint("取消了歌曲：${info.musicPath} 到我的收藏");
                                  }
                                  setState(() {});
                                  break;

                                /// 删除歌曲
                                case 3:
                                  final floatingState =
                                      playerController.bindMaps[1]
                                          as FloatingPlayerState;
                                  floatingState.justHide();
                                  await confirmDeleteMusic(
                                    context,
                                    playerController,
                                    pointInfo: info,
                                    isTemp: isTempInLib,
                                  );
                                  floatingState.justShow();
                                  break;

                                /// 临时置顶歌曲（乐库）
                                case 4:
                                  final int index = playerController
                                      .playTotalLib
                                      .indexOf(info);

                                  /// 已经是顶部则没必要重构
                                  if (index == 0) {
                                    debugPrint('已经是置顶歌曲了.');
                                    break;
                                  }
                                  (playerController.bindMaps[0]
                                          as MusicPlayerListState)
                                      .moveItem(index, mode: 0);
                                  break;

                                /// 永久置顶歌曲（乐库）
                                case 5:
                                  final int index = playerController
                                      .playTotalLib
                                      .indexOf(info);

                                  /// 已经是顶部则没必要重构
                                  if (index == 0) {
                                    debugPrint('已经是置顶歌曲了.');
                                    break;
                                  }
                                  (playerController.bindMaps[0]
                                          as MusicPlayerListState)
                                      .moveItem(index, mode: 0);
                                  info.anySign['id'] = mgrMusicToTop--;
                                  await saveMgrSrcData(key: 'toTop');
                                  await info.toPickleAsync();
                                  break;

                                /// 清空队列
                                case 6:
                                  if (playerController.queue.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('队列暂无歌曲。'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                    break;
                                  }
                                  clearQueue(context, playerController);
                                  break;

                                /// 查看信息
                                case 7:
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      final Map<String, dynamic> data = info
                                          .toJson();
                                      final dataWithOutCoverData = data
                                        ..remove('coverBytesEncode')
                                        ..['id'] = info.id
                                        ..['favorId'] = info.favorId
                                        ..['anySign'] = info.anySign
                                        ..['index'] = index;
                                      return SimpleDialog(
                                        title: const Row(
                                          children: [
                                            Icon(Icons.remove_red_eye_outlined),
                                            SizedBox(width: 20),
                                            Text('信息'),
                                          ],
                                        ),
                                        children: [
                                          Image.file(File(info.coverPath)),
                                          JsonView.string(
                                            JsonEncoder.withIndent(
                                              '  ',
                                            ).convert(dataWithOutCoverData),
                                            theme: const JsonViewTheme(
                                              viewType: JsonViewType.base,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  break;
                                default:
                                  debugPrint('value = default');
                                  break;
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<int>>[
                                  const PopupMenuItem<int>(
                                    value: 0,
                                    child: Row(
                                      children: [
                                        Icon(Icons.queue),
                                        SizedBox(width: 10),
                                        Text('加入队列'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<int>(
                                    value: 1,
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility),
                                        SizedBox(width: 10),
                                        Text('隐藏/展示浮动球'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<int>(
                                    value: 2,
                                    enabled: !isTempInLib,
                                    child: Row(
                                      children: [
                                        isTempInLib
                                            ? const Icon(
                                                Icons.favorite_border,
                                                color: Colors.blueGrey,
                                              )
                                            : Icon(
                                                info.favorId != null
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: Colors.red,
                                              ),
                                        const SizedBox(width: 10),
                                        const Text('收藏歌曲'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<int>(
                                    value: 3,
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete),
                                        SizedBox(width: 10),
                                        Text('删除歌曲'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<int>(
                                    value: 4,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.vertical_align_top,
                                          color: Colors.deepPurple,
                                        ),
                                        SizedBox(width: 10),
                                        Text('临时置顶'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<int>(
                                    value: 5,
                                    enabled: !isTempInLib,
                                    child: Row(
                                      children: [
                                        isTempInLib
                                            ? const Icon(
                                                Icons.vertical_align_top,
                                                color: Colors.blueGrey,
                                              )
                                            : const Icon(
                                                Icons.vertical_align_top,
                                                color: Colors.red,
                                              ),
                                        const SizedBox(width: 10),
                                        const Text('永久置顶'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<int>(
                                    value: 6,
                                    child: Row(
                                      children: [
                                        Icon(Icons.clear),
                                        SizedBox(width: 10),
                                        Text('清空队列'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<int>(
                                    value: 7,
                                    child: Row(
                                      children: [
                                        Icon(Icons.remove_red_eye_outlined),
                                        SizedBox(width: 10),
                                        Text('查看信息'),
                                      ],
                                    ),
                                  ),
                                ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _whenNotInTotal() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('切换到乐库模式且被点击歌曲已经在播放了。'),
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// 清空队列
void clearQueue(BuildContext context, PlayerController playerController) {
  playerController.resetQueue();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('歌曲队列（长度为${playerController.queue.length}）被清空。'),
      duration: const Duration(seconds: 1),
    ),
  );
}
