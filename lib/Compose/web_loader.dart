import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'floating_player.dart' show FloatingPlayerState;
import '../Logic/global_config.dart';
import '../Logic/play_controller.dart';
import '../Logic/music_info_reader.dart' show MusicInfoReader;

/// 返回一个记录，第一个值表示是否确认操作（总控）、第二个值表示处理模式，第三个值表示歌曲链接、第四个值歌曲类型、第五个值是否在不在乐库的时候跳转乐库（前提是设置showJumpToLib为true）
/// 在线听：播放器直接放这首在线歌曲，该歌曲只能临时播放一次和临时重播、单曲循环
/// 临时加入乐库：临时写入信息且加入乐库尾部最后跳转尾部，该歌曲不支持收藏、永久置顶
/// 下载至乐库：永久写入信息且加入乐库尾部最后跳转尾部
Future<(bool, int, String, String, bool)?> webLoader(
  BuildContext context, {
  bool? showJumpToLib,
}) async {
  return showDialog<(bool, int, String, String, bool)>(
    context: context,

    /// 禁止点击外部关闭
    barrierDismissible: false,

    builder: (BuildContext context) {
      /// 0=在线听, 1=临时, 2=下载
      int selectedIndex = 0;

      final textEditingController = TextEditingController();

      /// 是否失败以及原因
      int? reasonOfFail;

      /// 在检测的时候触发禁用Dlg任何操作
      bool isAbsorbing = false;

      String mType = '';

      /// 是否勾选了跳转
      bool jumpConfirm = showJumpToLib == true;

      return StatefulBuilder(
        builder: (context, setState) {
          return PopScope(
            canPop: !isAbsorbing,
            child: AbsorbPointer(
              absorbing: isAbsorbing, // 正在检测时禁用所有操作
              child: SimpleDialog(
                title: const Row(
                  children: [
                    Icon(Icons.cloud_download_rounded),
                    SizedBox(width: 8),
                    Text('网络载入'),
                  ],
                ),
                children: <Widget>[
                  /// 包一层 Container 加边框
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: textEditingController,
                          decoration: InputDecoration(
                            labelText: '输入地址链接',
                            hintText:
                                '仅支持mp3和flac格式文件，如：https://www.example.com/name.mp3',
                            border: InputBorder.none,
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w700,
                            ),
                            constraints: BoxConstraints(
                              maxHeight: showJumpToLib == true ? 170 : 150,
                            ),
                          ),
                          minLines: 3,
                          maxLines: 10,
                          onTap: () {
                            setState(() {
                              reasonOfFail = null;
                            });
                          },
                        ),
                        reasonOfFail == null
                            ? const SizedBox(height: 12)
                            : SizedBox(
                                height: 25,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_sharp,
                                      color: Colors.red,
                                    ),
                                    whenFailed(reasonOfFail!),
                                  ],
                                ),
                              ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('处理模式'),
                            Flexible(
                              child: DropdownButton<int>(
                                isExpanded: false,
                                value: selectedIndex,
                                items: const [
                                  DropdownMenuItem(
                                    value: 0,
                                    child: Row(
                                      children: [
                                        Icon(Icons.online_prediction),
                                        SizedBox(width: 8),
                                        Text("在线听"),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 1,
                                    child: Row(
                                      children: [
                                        Icon(Icons.timelapse_outlined),
                                        SizedBox(width: 8),
                                        Text("临时加入乐库"),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 2,
                                    child: Row(
                                      children: [
                                        Icon(Icons.download_rounded),
                                        SizedBox(width: 8),
                                        Text("下载至乐库"),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedIndex = value!;
                                    debugPrint('选择了载入模式:$selectedIndex');
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        showJumpToLib != true
                            ? const SizedBox.shrink()
                            : Row(
                                children: [
                                  Checkbox(
                                    activeColor: Colors.green,
                                    checkColor: Colors.white,
                                    value: jumpConfirm,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        jumpConfirm = value ?? false;
                                      });
                                    },
                                  ),
                                  const Text('载入成功则跳转乐库'),
                                ],
                              ),
                      ],
                    ),
                  ),

                  /// 🔹 底部按钮单独放外面
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        /// 确认的时候进行地址检查，如果是非空输入、能响应、链接存在、是mp3文件都满足，则立刻返回
                        /// 否则，对话框不消失，而且在
                        onPressed: () async {
                          final url = textEditingController.text.trim();

                          /// 开始检测，禁用操作
                          setState(() {
                            isAbsorbing = true;
                          });

                          /// 空链接
                          if (url.isEmpty) {
                            setState(() {
                              reasonOfFail = -1;
                              isAbsorbing = false;
                            });
                            return;
                          }

                          /// 尝试请求头部，快速检测链接有效性
                          try {
                            final response = await globalDio.head(
                              url,
                              options: Options(
                                followRedirects: true,
                                validateStatus: (status) => status! < 500,
                              ),
                            );

                            if (response.statusCode == null ||
                                response.statusCode! >= 400) {
                              setState(() {
                                reasonOfFail = 1; // 链接找不到
                                isAbsorbing = false;
                              });
                              return;
                            }

                            /// 根据mimetype确认是不是MP3或者Flac
                            final contentType =
                                response.headers.value('content-type') ?? '';
                            final isMpeg = contentType.contains('audio/mpeg');
                            final isFlac = contentType.contains('audio/flac');
                            if (!(isMpeg || isFlac)) {
                              setState(() {
                                reasonOfFail = 2;
                                isAbsorbing = false;
                              });
                              return;
                            } else {
                              mType = isMpeg ? '.mp3' : '.flac';
                            }

                            /// 通过验证，关闭对话框并返回
                            if (!context.mounted) {
                              reasonOfFail = -2;
                              isAbsorbing = false;
                              return;
                            }
                            Navigator.of(context).pop((
                              true,
                              selectedIndex,
                              url,
                              mType,
                              jumpConfirm,
                            ));
                          } catch (e) {
                            setState(() {
                              reasonOfFail = 0; // 无法响应
                              isAbsorbing = false;
                            });
                          }
                        },
                        child: isAbsorbing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('确认'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pop((false, selectedIndex, '', mType, jumpConfirm)),
                        child: const Text('取消'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget whenFailed(int reasonOfFail) {
  const textStyle = TextStyle(color: Colors.red, fontWeight: FontWeight.w700);
  switch (reasonOfFail) {
    case -2:
      return const Text('意外错误。', style: textStyle);
    case -1:
      return const Text('尚未输入任何链接', style: textStyle);
    case 0:
      return const Text('无法响应', style: textStyle);
    case 1:
      return const Text('链接找不到', style: textStyle);
    default:
      return const Text('仅支持MP3或者Flac格式的歌曲', style: textStyle);
  }
}

/// 从网络下载一首歌曲到online文件夹，即使是在线听，也要先下载下来缓存
Future<File?> downloadOnlineFileToTempDir(
  String url,
  String fileName, {
  bool forever = false,
}) async {
  final tempFile = File(
    '${forever ? foreverOnlineDir.path : tempOnlineDir.path}/$fileName',
  );
  final response = await globalDio.download(url, tempFile.path);

  /// 下载成功
  if (response.statusCode == 200 || response.statusCode == 206) {
    if (await tempFile.exists() && await tempFile.length() > 0) {
      return tempFile;
    }
  }
  return null;
}

Future<void> loadFromWebCompletely(
  BuildContext context,
  PlayerController playerController, {
  void Function()? scrollToBottom,

  /// 不在乐库调用此功能，是否切换至乐库
  bool? showJumpToLib,

  /// 切换界面
  void Function(int)? switchPage,
}) async {
  final floatingState = playerController.bindMaps[1] as FloatingPlayerState;
  floatingState.justHide();

  final reply = await webLoader(context, showJumpToLib: showJumpToLib);
  debugPrint("isWebLoader == $reply");

  void showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  /// 网络请求再次失败
  if (reply == null) {
    if (!context.mounted) {
      floatingState.justShow();
      return;
    }
    showSnackBar('网络请求异常!');
    floatingState.justShow();
    return;
  }

  /// 手动取消
  if (!(reply.$1)) {
    showSnackBar('取消操作');
    floatingState.justShow();
    return;
  }

  /// 这时候拿到了信息
  var (_, copeMode, url, mType, jumpConfirm) = reply;

  debugPrint('跳转情况：$jumpConfirm');

  final fileName = '${globalUuid.v1()}$mType';

  /// 包装
  final File? fileLocal = await downloadOnlineFileToTempDir(
    url,
    fileName,
    forever: copeMode == 2,
  );

  if (fileLocal == null) {
    return showSnackBar('歌曲下载失败');
  }

  final musicPath = fileLocal.path;

  if (copeMode == 0) {
    final info = await MusicInfoReader.createAsync(musicPath, isTemp: true);
    info.anySign['web'] = true;
    playerController.listenButNochangedIndex(info);
    if (jumpConfirm) {
      switchPage!(1);
    }
    debugPrint("歌曲下载：$fileName，在线听模式");
  } else if (copeMode == 1) {
    final info = await MusicInfoReader.createAsync(musicPath, isTemp: true);
    info.anySign['web'] = 1;

    /// 添加到乐库尾部(不生成pkl缓存)并且滚动到乐库尾部
    playerController.addMusicToPlaylistLib(info, toPkl: false, notify: true);
    if (jumpConfirm) {
      switchPage!(1);
    }
    scrollToBottom!();
    debugPrint("歌曲下载：$fileName，临时记录");
  } else {
    /// 不需要 info.anySign['web'] = true;
    /// 添加到乐库尾部(生成pkl缓存)并且滚动到乐库尾部
    final info = await MusicInfoReader.createAsync(musicPath, isTemp: false);
    playerController.addMusicToPlaylistLib(info, toPkl: true, notify: true);
    if (jumpConfirm) {
      switchPage!(1);
    }
    scrollToBottom!();

    /// 写入记录
    await saveMgrMixinData({'src': mgrSrcData, 'counter': mgrMusicCounter});
    showSnackBar('已从网络永久记录歌曲到本地乐库。');
    debugPrint("歌曲下载：$fileName，永久写入");
  }

  floatingState.justShow();
  return;
}
