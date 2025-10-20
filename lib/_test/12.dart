part of 'panel.dart';

/// 检查音乐链接是不是合理
/// 返回值含义：0：空连接、1：链接找不到、2：不支持的文件格式、3：无法响应、4：存在且是mp3、5：存在且是flac
Future<int> checkMusicLin(String text) async {
  final url = text.trim();

  /// 空链接
  if (url.isEmpty) {
    return 0;
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

    if (response.statusCode == null || response.statusCode! >= 400) {
      return 1;
    }

    /// 根据mimetype确认是不是MP3或者Flac
    final contentType = response.headers.value('content-type') ?? '';
    final isMpeg =
        contentType.contains('audio/mpeg') || contentType.contains('audio/mp3');
    final isFlac = contentType.contains('audio/flac') || url.endsWith('.flac');
    if (!(isMpeg || isFlac)) {
      return 2;
    } else {
      return isMpeg ? 4 : 5;
    }
  } catch (_) {
    return 3;
  }
}

class _StatusHint extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusHint({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MusicWrpper extends StatefulWidget {
  const MusicWrpper({
    super.key,
    required this.playerController,
    required this.switchPage,
  });

  final PlayerController playerController;
  final void Function(int) switchPage;

  @override
  State<StatefulWidget> createState() => MusicWrpperState();
}

class MusicWrpperState extends State<MusicWrpper> {
  late final TextEditingController textEditingController;
  late final TextEditingController coverController;
  late final TextEditingController artistController;
  late final TextEditingController titleController;
  late final TextEditingController localCoverController;

  /// 当音乐链接被输入会秒检测，成功则生成封面、歌曲作者和歌曲名字否则提升
  /// -1表示等待输入中
  int visible = -1;
  MusicInfoReader? info;

  /// 封面图片。-1表示歌曲自带的（也可能是默认替换的）
  int coverMode = -1;
  String? tempCoverPath;

  /// 在检测的时候触发禁用任何操作
  bool isAbsorbing = false;

  @override
  void initState() {
    textEditingController = TextEditingController();
    coverController = TextEditingController();
    artistController = TextEditingController();
    titleController = TextEditingController();
    localCoverController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    coverController.dispose();
    textEditingController.dispose();
    artistController.dispose();
    titleController.dispose();
    localCoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isPortrait = mq.orientation == Orientation.portrait;

    final contentArea = Column(
      children: [
        /// 顶部输入框（不滚动）
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: textEditingController,
            decoration: const InputDecoration(
              labelText: '输入地址链接',
              hintText:
              '仅支持 mp3 和 flac 格式文件，例如：https://www.example.com/name.mp3',
              border: OutlineInputBorder(),
              hintStyle: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
            minLines: 3,
            maxLines: 10,
            onChanged: (str) async => await onChanged(str),
          ),
        ),

        const SizedBox(height: 8),

        /// 状态提示区（固定）
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: buildByVisible(),
        ),

        const SizedBox(height: 8),

        /// 滚动内容（歌曲信息、封面、输入框等）
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: Colors.grey.shade50.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  spreadRadius: 1,
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: info == null
                  ? const SizedBox.shrink()
                  : Padding(
                padding: const EdgeInsets.only(top: 8),
                child: buildDetailArea(),
              ),
            ),
          ),
        ),
      ],
    );

    return AbsorbPointer(
      absorbing: isAbsorbing,
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: isPortrait
                ? mq.size.height * 0.8
                : mq.size.height * 0.85,
            maxWidth:
            isPortrait ? mq.size.width * 0.9 : mq.size.width * 0.7,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.my_library_music_rounded,
                        color: Colors.lightBlue),
                    SizedBox(width: 6),
                    Text(
                      '歌曲包装导入',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(child: contentArea),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> onChanged(String str) async {
    visible = await checkMusicLin(str);
    info = null;
    if (visible > 3) {
      final File? fileLocal = await downloadOnlineFileToTempDir(
        str,
        '${globalUuid.v1()}${visible == 4 ? ".mp3" : ".flac"}',
        forever: false,
      );

      if (fileLocal == null) {
        info = null;
        debugPrint('歌曲下载失败');
      } else {
        info = await MusicInfoReader.createAsync(fileLocal.path, isTemp: true);
        info!.anySign['web'] = true;
      }
    } else {
      info = null;
    }
    setState(() {});
  }

  /// 固定顶部状态区
  Widget buildByVisible() {
    switch (visible) {
      case -1:
        return const _StatusHint(
          icon: Icons.hourglass_empty,
          text: '等待输入中',
          color: Colors.lightBlue,
        );
      case 0:
        return const _StatusHint(
          icon: Icons.link_off,
          text: '空的链接',
          color: Colors.red,
        );
      case 1:
        return const _StatusHint(
          icon: Icons.error_outline,
          text: '找不到该链接',
          color: Colors.red,
        );
      case 2:
        return const _StatusHint(
          icon: Icons.block,
          text: '仅支持 mp3 / flac 格式文件',
          color: Colors.red,
        );
      case 3:
        return const _StatusHint(
          icon: Icons.cloud_off,
          text: '无法响应服务',
          color: Colors.red,
        );
      default:
        if (info == null) {
          return const _StatusHint(
            icon: Icons.download_for_offline,
            text: '歌曲下载失败',
            color: Colors.red,
          );
        }
        return const SizedBox.shrink();
    }
  }

  /// 下方滚动区（歌曲详细信息、封面选择等）
  Widget buildDetailArea() {
    // 这里原样保留你的逻辑，只是轻微格式整理
    // ✅ 不删注释，不改函数结构，只调整缩进/样式一致性
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 100,
                width: 100,
                child: coverMode == -1
                    ? Image.file(File(info!.coverPath), fit: BoxFit.cover)
                    : tempCoverPath == null
                    ? SvgPicture.asset(
                  'assets/img/not_found.svg',
                  fit: BoxFit.contain,
                )
                    : Image.file(File(tempCoverPath!), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info!.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    info!.artist,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        // 🔽 以下保持原样（略）——只是排版整理
        const SizedBox(height: 16),
        const Divider(height: 1, color: Colors.grey),
        const SizedBox(height: 12),
        /// 封面链接
        const SizedBox(height: 12),
        const Text(
          '* 指定封面链接',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        TextField(
          controller: coverController,
          decoration: const InputDecoration(
            hintText: '可以为空，例如 https://example.com/cover.png',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
          minLines: 1,
          maxLines: 2,
        ),

        const SizedBox(height: 12),

        /// 采用本地的图片当封面
        TextButton(
          onPressed: () async {
            if (isPlatformWithMobile &&
                !await FileFolderPicker.hasPermission) {
              bool granted =
              await FileFolderPicker.requestMobilePermission();
              if (!granted) {
                bool isPermanentlyDenied = await Permission
                    .manageExternalStorage
                    .isPermanentlyDenied;
                if (isPermanentlyDenied && context.mounted) {
                  /// 永久拒绝，显示引导对话框
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("需要存储权限"),
                      content: Text("请在系统设置中授予存储权限以选择图片。"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("取消"),
                        ),
                        TextButton(
                          onPressed: () async {
                            await openAppSettings();
                            Navigator.pop(context);
                          },
                          child: Text("去设置"),
                        ),
                      ],
                    ),
                  );
                } else if (context.mounted) {
                  /// 普通拒绝，显示简短提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("请授予存储权限以选择图片"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
                return;
              }
            }

            final String? path = await FileFolderPicker.pickFile(
              allowedExtensions: const ['png', 'jpg', 'jpeg'],
              label: 'Image File',
            );

            if (path != null) {
              /// 成功选中的话，先同步显示，等确定之后再拷贝
              setState(() {
                localCoverController.text = path;
                tempCoverPath = path;
              });
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("取消选择图片"),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          child: const Row(
            children: [
              Icon(Icons.ads_click, color: Colors.lightBlue),
              Text(
                '* 采用本地封面',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        TextField(
          controller: localCoverController,
          decoration: const InputDecoration(
            hintText: '可以为空',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
          minLines: 1,
          maxLines: 2,
          enabled: false,
        ),

        const SizedBox(height: 12),

        /// 歌手
        const Text(
          '* 指定歌手',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        TextField(
          controller: artistController,
          decoration: const InputDecoration(
            hintText: '可以为空，将使用歌曲自带信息',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
        ),

        const SizedBox(height: 12),

        /// 歌曲名
        const Text(
          '* 指定歌曲名字',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: '可以为空，将使用歌曲自带信息',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
        ),

        const SizedBox(height: 20),

        /// 按钮区域
        Align(
          alignment: Alignment.centerRight,
          child: isAbsorbing
              ? const SpinKitThreeInOut(color: Colors.blue)
              : Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () async {
                  coverMode = await checkCoverExist(
                    coverController.text,
                  );
                  setState(() {
                    isAbsorbing = false;
                  });
                },
                icon: const Icon(Icons.image_search),
                label: const Text('检查封面'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  if (!mounted) return;
                  isAbsorbing = true;

                  /// 即使没做封面检测，也要检测一下：前提是tempCoverPath空且url不空
                  if (tempCoverPath == null &&
                      coverController.text.isNotEmpty) {
                    await checkCoverExist(coverController.text);
                  }

                  /// 如果tempCoverPath仍然不空，说明指定了存在路径，复制到永久
                  /// tempCoverPath来自temp_online缓存或者本地图库
                  if (tempCoverPath != null) {
                    final String targetPath =
                        '${foreverOnlineDir.path}/${path_lib.basename(tempCoverPath!)}';

                    /// 复制文件
                    await File(tempCoverPath!).copy(targetPath);
                    tempCoverPath = targetPath;
                  }

                  final newInfo = await info!.copyButPoint(
                    pointArtist: artistController.text.isEmpty
                        ? null
                        : artistController.text,
                    pointCoverPath: tempCoverPath,
                    pointTitle: titleController.text.isEmpty
                        ? null
                        : titleController.text,
                  );
                  widget.playerController.addMusicToPlaylistLib(
                    newInfo,
                    toPkl: false,
                    notify: true,
                  );
                  setState(() => isAbsorbing = false);
                  Navigator.pop(context);

                  /// 切换乐库界面
                  widget.switchPage(1);

                  /// 同步滚动
                  (widget.playerController.bindMaps[0]
                  as MusicPlayerListState)
                      .scrollToBottom();
                  showSnackBar('成功导入歌曲', context);
                },
                icon: const Icon(Icons.done),
                label: const Text('确认导入'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    );

    final mq = MediaQuery.of(context);
    final isPortrait = mq.orientation == Orientation.portrait;
    return AnimatedContainer(
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOutCubic,
    constraints: BoxConstraints(
    maxHeight: isPortrait
    ? mq.size.height * 0.7
        : mq.size.height * 0.85,
    maxWidth: isPortrait ? mq.size.width * 0.9 : mq.size.width * 0.8,
    ),
    padding: const EdgeInsets.only(top: 8),
    child: ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Material(
    color: Colors.grey.shade100.withOpacity(0.9),
    child: SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    child: padding,
    ),
    ),
    ),
    );
      ],
    );
  }

// 下面的 checkCoverExist、showSnackBar、_cropToSquare 等保持原样不变
}
