part of 'panel.dart';

/// 保存至图片
Future<void> saveUint8ListToWindows(
  Uint8List bytes,
  void Function(String) showSnackBar,
) async {
  final filename = '${getFormatTime()}.png';
  if (isPlatformWithPC) {
    final directory = await getDownloadsDirectory();
    final file = File(
      '${directory != null ? directory.path : dirOfLongTimeStorage}/$filename',
    );
    await file.writeAsBytes(bytes);
    showSnackBar('保存成功');
    return;
  }

  /// 要权限
  final ps = await PhotoManager.requestPermissionExtend();
  if (!ps.isAuth) {
    showSnackBar('没有权限保存到相册');
    return;
  }

  /// 保存图片到相册
  final to = await PhotoManager.editor.saveImage(
    bytes,
    title: filename,
    filename: filename,
  );
  showSnackBar('保存至相册成功');
  debugPrint("保存路径：${(await to.file)?.path}");
}

/// 每日卡片zan'bu
class PersonalizedCard extends StatelessWidget {
  final MusicInfoReader info;

  /// 放鸡汤
  final String saying;

  /// 放日期
  final String date;

  /// 底部背景大图
  final String bottomImg;

  /// 是否是默认音乐
  final bool isDefault;
  const PersonalizedCard({
    super.key,
    required this.info,
    required this.bottomImg,
    required this.saying,
    required this.date,
    required this.isDefault,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.8;
    final cardHeight = size.height * 0.6;

    return Center(
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// 今日日期
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  date,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              /// 心灵鸡汤
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  saying,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Ygy',
                  ),
                ),
              ),

              /// 歌曲信息 Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// 小封面图
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(info.coverPath),
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),

                    /// 歌曲名字
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "今日推荐",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${info.title} - ${info.artist}',
                            style: TextStyle(
                              fontSize: platformDefaultFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// 底部大背景图（类似 BottomSheet）
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  height: cardHeight,
                  child: CachedNetworkImage(
                    imageUrl: bottomImg,
                    fit: BoxFit.cover,
                    progressIndicatorBuilder: (context, url, downloadProgress) => Center(
                      child: CircularProgressIndicator(
                        value: downloadProgress.progress,
                      ),
                    ),

                    /// 加载失败时使用本地图片
                    errorWidget: (context, url, error) {
                      debugPrint("图片加载失败: $error，切换本地图片");
                      return Image.asset(
                        'assets/img/cardLocal.jpg',
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum SaveStatus { idle, saving, success, fail }

/// 卡片系统的单独随机数器，私用防线程问题
final _cardRandomGen = Random();

Future<void> showPersonalizedCardDialog(
  BuildContext context,
  PlayerController playerController, {
  required MusicInfoReader info,
  required bool isDefault,
}) async {
  /// 从card api加载
  /// 如果是未加载状态，则首次加载并且记录，如果失败，下一次点击卡片功能还可以重新请求，直到成功
  if (!cardApiAskCompletely) {
    await readCardAssets();
  }
  late final String saying;
  late final String bottomImg;

  /// 验证是不是成功了，成功好说，失败了则传入一个空链接
  if (cardApiAskCompletely) {
    /// 成功加载，优先从 cardPairs 随机，否则走 sayings/pictures
    if (cardPairs != null &&
        cardPairs!.isNotEmpty &&
        _cardRandomGen.nextBool()) {
      final pair = cardPairs![_cardRandomGen.nextInt(cardPairs!.length)];
      saying = pair['saying'];
      bottomImg = pair['picture'];
      debugPrint('卡片数据源：组合');
    } else {
      saying = cardSayings[_cardRandomGen.nextInt(cardSayings.length)];
      bottomImg = cardPictures[_cardRandomGen.nextInt(cardPictures.length)];
      debugPrint('卡片数据源：随机');
    }
  } else {
    /// 加载失败，使用默认兜底
    saying = '竹杖芒鞋轻胜马，谁怕？一蓑烟雨任平生。';
    bottomImg = '';
    debugPrint('卡片数据源：请求失败的默认处理');
  }

  final floatingState = playerController.bindMaps[1] as FloatingPlayerState;
  floatingState.justHide();
  WidgetsToImageController controller = WidgetsToImageController();

  void showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  await showDialog(
    context: context,
    barrierDismissible: false,

    /// 点外面不能关闭
    builder: (context) {
      /// 保存是否成功
      SaveStatus saveStatus = SaveStatus.idle;
      return StatefulBuilder(
        builder: (context, setState) {
          /// 保存函数
          Future<void> doSave() async {
            setState(() => saveStatus = SaveStatus.saving);

            try {
              if (!context.mounted) {
                showSnackBar('保存失败');
                setState(() => saveStatus = SaveStatus.fail);
                return;
              }

              Uint8List? bytes = await controller.capture(
                options: const CaptureOptions(
                  format: ImageFormat.png,
                  pixelRatio: 4.0,
                  quality: 95,
                  waitForAnimations: true,
                  delayMs: 100,
                ),
              );

              /// 强制等待 1 秒，防UI触碰
              await Future.delayed(const Duration(seconds: 1));

              if (bytes == null) {
                showSnackBar('保存失败');
                setState(() => saveStatus = SaveStatus.fail);
              } else {
                await saveUint8ListToWindows(bytes, showSnackBar);
                setState(() => saveStatus = SaveStatus.success);
              }
            } catch (e) {
              debugPrint('出错了: $e');
              showSnackBar('保存失败');
              setState(() => saveStatus = SaveStatus.fail);
            }
          }

          return AbsorbPointer(
            absorbing: saveStatus == SaveStatus.saving,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// 卡片主体
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: WidgetsToImage(
                      controller: controller,
                      child: PersonalizedCard(
                        isDefault: isDefault,
                        info: info,
                        bottomImg: bottomImg,
                        saying: saying,
                        date: parseYMD(DateTime.now()),
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  /// 底部按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          /// 保存功能
                          onPressed: saveStatus == SaveStatus.saving
                              ? null
                              : doSave,
                          icon: () {
                            switch (saveStatus) {
                              case SaveStatus.saving:
                                return const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              case SaveStatus.success:
                                return const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                );
                              case SaveStatus.fail:
                                return const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                );
                              default:
                                return const Icon(Icons.save);
                            }
                          }(),
                          label: const Text("保存"),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          /// 听推荐歌曲功能
                          onPressed: () {
                            playerController.setPlaylist(0);
                            playerController.updateInfoByExistAutoIndex(
                              info,
                              isDefault,
                              shouldPlay: true,
                              forceRestart: true,
                            );
                            Navigator.pop(context);
                            floatingState.justShow();
                          },
                          icon: const Icon(
                            Icons.play_circle,
                            color: Colors.lightBlue,
                          ),
                          label: const Text("试听"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          /// 手动关闭
                          onPressed: () {
                            Navigator.pop(context);
                            floatingState.justShow();
                          },
                          icon: const Icon(Icons.close),
                          label: const Text("关闭"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  ).then((_) {
    controller.dispose();
  });
}
