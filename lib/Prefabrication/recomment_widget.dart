part of 'prefabrication.dart';

/// 从网络下载一首歌曲（确定是支持的格式不做检查）到本地并且读取到信息（不写入乐库而是到temp_online文件夹）
/// 临时没必要记录ID
Future<MusicInfoReader?> loadFromWebAndWriteToInfoOrReadLocal(
  String url,
  String name,
  String mimetype,
) async {
  final fileName = "$name.$mimetype";

  /// 如果已经存在
  final allPath = '${tempOnlineDir.path}/$fileName';
  final file = File(allPath);
  if (await file.exists()) {
    debugPrint('从本地缓存载入信息');
    return await MusicInfoReader.createAsync(
      allPath,
      isTemp: true,
      needRecordCounter: false,
    );
  }

  /// 删除或第一次检测
  final File? response = await downloadOnlineFileToTempDir(
    url,
    fileName,
    forever: false,
  );
  if (response != null) {
    debugPrint('从网上下载到本地缓存然后载入信息');
    return await MusicInfoReader.createAsync(
      response.path,
      isTemp: true,
      needRecordCounter: false,
    );
  }
  return null;
}

/// templete
/// ```{
///   "url" : "https:///xxxx",
///   "name": "歌曲唯一名字，下次不下载而是本地寻址，没有再重新下载",
///   "mimetype" : "mp3",
///   "description" : "xxxxxxxxxxxx"
/// }```
class RecommentWidget extends StatefulWidget {
  final String url;
  final String mimetype;
  final String name;
  final String description;
  const RecommentWidget({
    super.key,
    required this.mimetype,
    required this.name,
    required this.url,
    required this.description,
  });

  @override
  State<StatefulWidget> createState() => RecommentWidgetState();
}

class RecommentWidgetState extends State<RecommentWidget> {
  MusicInfoReader? info;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final result = await loadFromWebAndWriteToInfoOrReadLocal(
      widget.url,
      widget.name,
      widget.mimetype,
    );
    if (mounted) {
      setState(() {
        info = result;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_outlined, color: Colors.orange),
        ),
      ),
      body: loading
          ? Center(
              child: SpinKitRing(
                color: Colors.lightBlue,
                size: math.min(width, height) / 2.5,
              ),
            )
          : buildByInfo(width),

      /// 固定底部按钮，不随滚动
      bottomNavigationBar: info == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        info!.anySign['web'] = true;
                        await Provider.of<PlayerController>(
                          context,
                          listen: false,
                        ).listenButNochangedIndex(info!);
                        debugPrint("在线试听歌曲 from：${widget.url}");
                      },
                      icon: const Icon(Icons.music_note),
                      label: const Text("试听歌曲"),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final filePath =
                            '${foreverOnlineDir.path}/${widget.name}.${widget.mimetype}';
                        if (await File(filePath).exists()) {
                          showSnackBar('本地已有此歌曲，可以去听了~', context);
                          return;
                        }
                        final newInfo = await info!.copyButPoint();
                        final PlayerController playerController =
                            Provider.of<PlayerController>(
                              context,
                              listen: false,
                            );
                        await playerController.addMusicToPlaylistLib(
                          newInfo,
                          toPkl: true,
                          notify: true,
                        );
                        (playerController.bindMaps[0] as MusicPlayerListState)
                            .scrollToBottom();
                        showSnackBar('成功下载至本地', context);
                      },
                      icon: const Icon(Icons.download),
                      label: const Text("下载至乐库"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildByInfo(double width) {
    if (info == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/img/disconnected.svg', width: width * 0.9),
            const SizedBox(height: 16),
            const Text('网络资源请求失败'),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// 封面
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.file(
              File(info!.coverPath),
              width: width,
              height: width * 0.7,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),

          /// 歌曲名字 + 演唱者
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                info!.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(width: 6),
              const Text('•', style: TextStyle(color: Colors.blue)),
              const SizedBox(width: 6),
              Text(
                info!.artist,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          /// 歌曲介绍（自动分段 + 首行缩进）
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.description
                .split('\n')
                .where((e) => e.trim().isNotEmpty)
                .map(
                  (para) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      "　　$para",
                      textAlign: TextAlign.start,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
