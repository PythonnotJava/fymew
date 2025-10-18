import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'empty_widget.dart' show EmptyStateWidget;
import 'song_card_item.dart' show SongCardItem;
import '../Logic/music_info_reader.dart';
import '../Logic/global_config.dart';
import '../Logic/picker.dart';
import '../Logic/play_controller.dart' show PlayerController;
import 'web_loader.dart';
import 'user_drawer.dart' show backupImg, DrawerState;
import 'background_builder.dart' show backgroundBuilder, bgModeNotifier;

class MusicPlayerList extends StatefulWidget {
  const MusicPlayerList({super.key, this.scaffoldKey});

  final GlobalKey<ScaffoldState>? scaffoldKey;
  @override
  State<StatefulWidget> createState() => MusicPlayerListState();
}

class MusicPlayerListState extends State<MusicPlayerList> {
  /// 搜匹配
  late List<MusicInfoReader> _filterCards;

  /// 延迟匹配
  Timer? _debounce;

  late final PlayerController playerController;

  /// 跳转滚动条
  late final ScrollController scrollController;

  /// 筛选时禁用按钮
  bool enableBtn = true;

  /// 搜索的时候占满Appbar，失去焦点的时候恢复
  final FocusNode _searchFocus = FocusNode();
  bool isSearching = false;

  /// 背景图片路径
  String? bgPath;

  /// 载入的时候禁用UI
  bool isLoadingMusic = false;

  @override
  void initState() {
    super.initState();
    playerController = Provider.of<PlayerController>(context, listen: false);
    _filterCards = playerController.playTotalLib;
    scrollController = ScrollController();
    playerController.bindMaps[0] = this;

    _searchFocus.addListener(() {
      setState(() {
        isSearching = _searchFocus.hasFocus;
        if (isSearching) {
          debugPrint('搜索栏展开: 用户点击了搜索栏');
        }
      });
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// 更新卡片列表
  void updateCardsByController() {
    _filterCards = playerController.playTotalLib;
    setState(() {});
  }

  /// 移动卡片到置顶，然后更新索引
  void moveItem(int from, {int mode = 0}) {
    final list = playerController.playTotalLib;
    if (from == 0 || list.length == 1) return;
    list.insert(0, list.removeAt(from));
    int currentIndex = playerController.currentIndex;

    /// 如果正在放的歌曲被置顶
    if (from == currentIndex) {
      playerController.setCurrentIndex(0);
    } else if (from < currentIndex) {
      /// 如果是正在放的歌曲前面的歌曲被置顶什么都不做
      {}
    } else {
      /// 如果是正在放的歌曲后面的歌曲被置顶
      playerController.setCurrentIndex(currentIndex + 1);
    }

    setState(() {
      _filterCards = list;
    });
  }

  /// 搜索匹配算法
  void searchCardsMethod(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final q = query.toLowerCase();
      setState(() {
        if (q.isEmpty) {
          enableBtn = true;
          _filterCards = playerController.playTotalLib;
          return;
        }
        enableBtn = false;
        _filterCards = playerController.playTotalLib.where((info) {
          return info.artist.toLowerCase().contains(q) ||
              info.title.toLowerCase().contains(q);
        }).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('重塑');
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        // backgroundColor: Colors.transparent,
        leading: isSearching
            ? null
            : GestureDetector(
                onTap: () {
                  widget.scaffoldKey?.currentState?.openDrawer();
                },
                child: Consumer<DrawerState>(
                  builder: (_, drawerState, _) {
                    final avatar = drawerState.userAvatarPath == null
                        ? const AssetImage('assets/img/unicorn.png')
                        : FileImage(File(drawerState.userAvatarPath!))
                              as ImageProvider;
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CircleAvatar(backgroundImage: avatar),
                      ),
                    );
                  },
                ),
              ),
        title: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: isSearching
              ? MediaQuery.of(context).size.width
              : MediaQuery.of(context).size.width * 0.6,
          child: TextFormField(
            focusNode: _searchFocus,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Music Name",
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              counterText: '',
            ),
            maxLength: 100,
            onChanged: searchCardsMethod,
          ),
        ),
        actions: isSearching
            ? []
            : isLoadingMusic
            ? [const Flexible(child: CircularProgressIndicator())]
            : [
                /// 从目录新添加并且写入缓存
                IconButton(
                  onPressed: enableBtn
                      ? () async {
                          isLoadingMusic = true;
                          final String? pickFolder =
                              await FileFolderPicker.pickFolder();

                          /// 重置每次失败次数
                          playerController.setFailSnackBarCounter(0);

                          /// 空的原因：没权限、有权限但是取消操作
                          if (pickFolder == null) {
                            /// 若是安卓未授予权限，尝试再要一次
                            if (isPlatformWithMobile &&
                                !await FileFolderPicker.hasPermission) {
                              /// 永久不给权限需要用户自己设置
                              bool isPermanentlyDenied = await Permission
                                  .manageExternalStorage
                                  .isPermanentlyDenied;
                              if (isPermanentlyDenied && mounted) {
                                /// 永久拒绝，显示引导对话框
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("需要存储权限"),
                                    content: const Text("请在系统设置中授予存储权限以访问文件。"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("取消"),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await openAppSettings();
                                          Navigator.pop(context);
                                        },
                                        child: const Text("去设置"),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (mounted) {
                                showSnackBar('请授予存储权限以继续');
                              }
                            } else {
                              /// 用户取消操作
                              showSnackBar('取消选择文件夹');
                            }
                          } else {
                            /// 有权限，且可以读了
                            final dir = Directory(pickFolder);

                            /// 更新记录
                            /// 少量歌曲的情况，一首一首的生成，addMusicToPlaylistLib是每次添加一首
                            final entries = await dir
                                .list(recursive: false)
                                .toList();
                            final musicListLen = entries.length;
                            debugPrint("导入歌曲的长度：$musicListLen。");

                            /// 每次都通知
                            if (musicListLen <= 20) {
                              await _mannerOne(entries);
                            } else if (musicListLen > 20 &&
                                musicListLen <= 100) {
                              await _mannerTwo(entries, 2);
                            } else {
                              await _mannerTwo(entries, 3);
                            }

                            /// 一轮导入完成
                            /// 1. 延迟写入记录
                            /// 2. 顺序记录
                            /// 3. 恢复上面按钮
                            /// 最后：SnackBar显示信息
                            await saveMgrMixinData({
                              'src': mgrSrcData,
                              'counter': mgrMusicCounter,
                            });
                            _whenShowFailSnackBar();
                            setState(() {
                              isLoadingMusic = false;
                            });
                          }
                        }
                      : null,
                  disabledColor: Colors.grey,
                  icon: const Icon(
                    Icons.drive_folder_upload,
                    color: Colors.orangeAccent,
                  ),
                ),

                /// 跳转至当前播放歌曲
                IconButton(
                  onPressed: enableBtn ? _scrollToCurrentSong : null,
                  icon: const Icon(
                    Icons.control_point,
                    color: Colors.pinkAccent,
                  ),
                  disabledColor: Colors.grey,
                ),

                /// 网络源导入一首
                IconButton(
                  onPressed: enableBtn
                      ? () async => loadFromWebCompletely(
                          context,
                          playerController,
                          scrollToBottom: scrollToBottom,
                          showJumpToLib: false,
                        )
                      : null,
                  icon: Icon(
                    Icons.cloud_download_rounded,
                    color: Colors.lightBlue[200],
                  ),
                  disabledColor: Colors.grey,
                ),
              ],
      ),
      body: SafeArea(
        child: _filterCards.isEmpty
            ? const EmptyStateWidget(title: Text('你的列表中空空如也'))
            : GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  debugPrint('失去焦点，返回正常布局');
                  _searchFocus.unfocus();
                },
                child: Stack(
                  children: [
                    backgroundBuilder(),
                    ListView.builder(
                      cacheExtent: _filterCards.length.toDouble(),
                      controller: scrollController,
                      itemCount: _filterCards.length,
                      itemBuilder: (context, index) {
                        final info = _filterCards[index];
                        return SongCardItem(
                          /// 使用 id 作为唯一的 key
                          key: ValueKey(info.id),
                          info: info,
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _whenShowFailSnackBar() {
    if (!mounted) return;
    int failSnackBarCounter = playerController.failSnackBarCounter;
    showSnackBar('因冲突失败个数：$failSnackBarCounter');
  }

  /// 跳转到当前播放歌曲的逻辑
  void _scrollToCurrentSong() {
    final info = playerController.currentMusicInfo;
    final currentIndex = playerController.playTotalLib.indexOf(info);

    if (currentIndex != -1) {
      if (currentIndex == 0){
        return scrollController.jumpTo(0);
      }
      /// 计算并滚动到指定索引的位置，使用 animateTo 带来平滑滚动效果
      scrollController.animateTo(
        currentIndex * maxHeightForPlatform,
        duration: Duration(milliseconds: min(currentIndex * 25, 2000)),
        curve: Curves.easeInOut,
      );
    } else {
      if (!mounted) return;
      showSnackBar('找不到该歌曲');
    }
  }

  /// 滚动到乐库底部，有同步刷新UI功能
  void scrollToBottom() {
    setState(() {
      /// 触发更新新卡片
    });
    final step = playerController.playTotalLib.length - 1;
    scrollController.animateTo(
      step * maxHeightForPlatform,
      duration: Duration(milliseconds: min((step + 1) * 25, 2000)),
      curve: Curves.easeInOut,
    );
  }

  void showSnackBar(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), duration: Duration(milliseconds: 500)),
  );

  /// 修改背景图片
  Future<void> refreshBgImg() async {
    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 12,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.image_search_rounded, color: Colors.lightBlue),
                    SizedBox(width: 10),
                    Text(
                      '背景设置',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: mgrBgMode != '1'
                            ? () async {
                                if (!mounted) {
                                  return;
                                }
                                Navigator.pop(context);
                                bgModeNotifier.value = mgrBgMode = '1';
                                await saveMgrSrcData(key: 'bgMode');
                              }
                            : null,
                        child: Column(
                          children: [
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: const AssetImage("assets/img/bg.jpg"),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                mgrBgMode == '1'
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.deepPurple,
                                      )
                                    : const Icon(
                                        Icons.circle_outlined,
                                        color: Colors.grey,
                                      ),
                                const Text("默认图片"),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: mgrBgMode != '2'
                            ? () async {
                                if (!mounted) {
                                  return;
                                }
                                Navigator.pop(context);
                                bgModeNotifier.value = mgrBgMode = '2';
                                await saveMgrSrcData(key: 'bgMode');
                              }
                            : null,
                        child: Column(
                          children: [
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: const AssetImage("assets/img/bg.gif"),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                mgrBgMode == '2'
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.deepPurple,
                                      )
                                    : const Icon(
                                        Icons.circle_outlined,
                                        color: Colors.grey,
                                      ),
                                const Text("默认动态"),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final String? path = await FileFolderPicker.pickFile(
                          allowedExtensions: const [
                            'png',
                            'jpg',
                            'jpeg',
                            'gif',
                            'webp',
                          ],
                          label: 'Image File',
                        );
                        if (path == null) {
                          showSnackBar('导入失败');
                        } else {
                          mgrBgMode = await backupImg(path);
                          bgModeNotifier.value = mgrBgMode;
                          await saveMgrSrcData(key: 'bgMode');
                        }
                        if (!mounted) {
                          return;
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('导入'),
                    ),
                    TextButton(
                      onPressed: mgrBgMode != '0'
                          ? () async {
                              if (!mounted) {
                                return;
                              }
                              Navigator.pop(context);
                              bgModeNotifier.value = mgrBgMode = '0';
                              await saveMgrSrcData(key: 'bgMode');
                            }
                          : null,
                      child: const Text("去除"),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text("取消"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 加载方案，策略1
  Future<void> _mannerOne(List<FileSystemEntity> entries) async {
    debugPrint('策略1');
    for (final name in entries) {
      final path = name.path;

      /// 文件允许
      if (isSupportType(path) &&
          await FileSystemEntity.type(path) == FileSystemEntityType.file) {
        /// 记录存在
        if (mgrSrcData.containsKey(path)) {
          playerController.setFailSnackBarCounter(
            playerController.failSnackBarCounter + 1,
          );
          debugPrint("FileRecord $path is existing!");
        } else {
          final info = await MusicInfoReader.createAsync(
            path,
            formatTime: getFormatTime(),
          );
          setState(() {
            playerController.addMusicToPlaylistLib(info);
          });

          /// 写入pkl记录
          info.writeToSrcData();
        }
      } else {
        debugPrint("忽略不支持的文件: $path");
      }
    }
  }

  /// 策略2或者3，每10/20首
  Future<void> _mannerTwo(List<FileSystemEntity> entries, int which) async {
    debugPrint('策略$which');

    final count = which == 2 ? 10 : 20;

    /// 每次刷新成功加入的10首
    int counter = 0;

    for (final name in entries) {
      final path = name.path;

      /// 文件允许
      if (isSupportType(path) &&
          await FileSystemEntity.type(path) == FileSystemEntityType.file) {
        /// 记录存在
        if (mgrSrcData.containsKey(path)) {
          playerController.setFailSnackBarCounter(
            playerController.failSnackBarCounter + 1,
          );
          debugPrint("FileRecord $path is existing!");
        } else {
          final info = await MusicInfoReader.createAsync(
            path,
            formatTime: getFormatTime(),
          );
          playerController.addMusicToPlaylistLib(info);
          counter++;

          /// 写入pkl记录
          info.writeToSrcData();
          if (counter >= count) {
            counter = 0;
            setState(() {});
          }
        }
      } else {
        debugPrint("忽略不支持的文件: $path");
      }
    }

    /// 循环完兜底：如果还有剩余记录，再提交一次
    if (counter > 0) {
      setState(() {});
    }
  }
}
