part of 'global_config.dart';

/// 第一次初始化或者有记录启动的代替音乐（default or record）
late MusicInfoReader initInfo;

/// 记录检测状态
late final int initInfoState;

/// 历史听歌记录（若有）
late String? mgrMusicRecordPath;

/// default.mp3
late String defaultMusicPath;

/// ------------------------------两个封面：丢失封面、默认音乐封面---------------------
/// 顶层配置文件，专门放基础配置
late final File topFile;
late Map<String, dynamic> topJsonData;

/// 找不到封面的音乐专用处理，默认封面写到根目录
late String replaceCoverPath;

/// default.mp3的封面，也放在根目录文件夹
late String defaultMusicCoverPath;

/// 移动默认到顶层
Future<void> initMoveDefaultMusicToTop() async {
  defaultMusicPath = '${dirOfLongTimeStorage.path}/default.mp3';
  if (await File(defaultMusicPath).exists()) {
    debugPrint('默认音乐现在已经存在于顶层文件夹');
    return;
  }
  final ByteData data = await rootBundle.load('assets/music/default.mp3');
  Uint8List bytes = data.buffer.asUint8List();
  File file = File(defaultMusicPath);
  await file.writeAsBytes(bytes, flush: true);
  debugPrint('已经成功把默认音乐写入顶层文件夹');
}

Future<void> initTopJsonFile() async {
  topFile = File('${dirOfLongTimeStorage.path}/top.json');
  if (!await topFile.exists()) {
    debugPrint('首次启动，创建顶层文件：${topFile.path}');
    await topFile.writeAsString(
      jsonEncode({"replaceCover": '', "defaultCover": ''}),
    );
  } else {
    debugPrint('顶层配置文件已存在：${topFile.path}');
  }
  topJsonData = jsonDecode(await topFile.readAsString());
  replaceCoverPath = topJsonData['replaceCover'];
  defaultMusicCoverPath = topJsonData['defaultCover'];
  bool changed = false;
  if (replaceCoverPath.isEmpty) {
    final ByteData data = await rootBundle.load('assets/img/music.png');
    Uint8List bytes = data.buffer.asUint8List();
    final toPath = '${dirOfLongTimeStorage.path}/replaceCover.png';
    File file = File(toPath);
    await file.writeAsBytes(bytes, flush: true);
    topJsonData['replaceCover'] = toPath;
    replaceCoverPath = toPath;
    debugPrint('第一次初始化替换封面到顶层文件：$replaceCoverPath');
    changed = true;
  }
  if (defaultMusicCoverPath.isEmpty) {
    final bytes = getCoverBytes(
      readMetadata(File(defaultMusicPath), getImage: true),
    );
    final String targetPath =
        '${dirOfLongTimeStorage.path}/defaultMusicCover.${judgeMimeType(bytes)}';
    await File(targetPath).writeAsBytes(bytes, flush: true);
    topJsonData['defaultCover'] = targetPath;
    defaultMusicCoverPath = targetPath;
    debugPrint('第一次初始化默认封面到顶层文件：$defaultMusicCoverPath');
    changed = true;
  }
  debugPrint("替换封面路径：$replaceCoverPath\n默认音乐封面：$defaultMusicCoverPath");
  if (changed) {
    final path = topFile.path;
    final data = _jsonEncoder.convert(topJsonData);

    /// 后台写入，避免阻塞 UI
    await compute(_writeToFileIsolate, {'path': path, 'data': data});
    debugPrint('因修改写入：$path，内容：$data');
  }
}

/// -----------------------------------------------------

/// 该函数保证有启动的记录音乐 MusicInfoReader到initInfo
Future<void> initCheckNullMusic() async {
  mgrMusicRecordPath = mgrPreMusicData['currentMusic'];
  debugPrint('mgrMusicRecordPath == $mgrMusicRecordPath');

  /// 完全是第一次初始化或者只初始化就没有导入 initInfo = MusicInfoReader.defaultReplace
  /// 已经初始化（可能没有一个满足条件歌曲）且导入音乐但是没有播放（也就是没有写入记录） initInfo = MusicInfoReader.defaultReplace
  /// 已经初始化（可能没有一个满足条件歌曲）且导入音乐但是音乐路径不存在 initInfo = MusicInfoReader.defaultReplace
  /// 已经初始化且导入音乐、音乐路径存在但是找不到缓存 initInfo = MusicInfoReader.defaultReplace
  /// 已经初始化（可能没有一个满足条件歌曲）且导入音乐且音乐路径存在 initInfo = MusicInfoReader.defaultReplace

  if (mgrSrcData.isEmpty) {
    initInfoState = 0;
    initInfo = MusicInfoReader.defaultReplace;
    debugPrint(">>> 0");
    if (mgrMusicRecordPath != null) {
      debugPrint(">>> 0-1");
      mgrPreMusicData['currentMusic'] = null;
      await saveMgrSrcData(key: 'music');
    }
    debugPrint("initInfoState == 0");
    return;
  }
  if (mgrSrcData.isNotEmpty && mgrMusicRecordPath == null) {
    debugPrint(">>> 1");
    initInfoState = 1;
    initInfo = MusicInfoReader.defaultReplace;
    debugPrint('initInfoState = 1');
    return;
  }
  final pkl = '${pklDir.path}/${mgrPreMusicData['infopkl']}';
  if (mgrSrcData.isNotEmpty &&
      mgrMusicRecordPath != null &&
      !isExistFile(mgrMusicRecordPath!)) {
    debugPrint(">>> 2");
    mgrPreMusicData['currentMusic'] = null;
    await saveMgrSrcData(key: 'music');
    initInfoState = 2;
    initInfo = MusicInfoReader.defaultReplace;
    debugPrint('initInfoState = 2');
    return;
  }
  if (!isExistFile(pkl)) {
    debugPrint(">>> 3");
    debugPrint('$pkl 已经被删除');
    mgrPreMusicData['infopkl'] = null;
    mgrPreMusicData['currentMusic'] = null;
    await saveMgrSrcData(key: 'music');
    initInfoState = 3;
    initInfo = MusicInfoReader.defaultReplace;
    debugPrint("initInfoState == 3");
    return;
  }
  debugPrint(">>> 4");
  initInfo = await MusicInfoReader.loadPickleAsync(pkl);
  initInfoState = 4;
  debugPrint('initInfoState = 4');
  return;
}

/// 启动前清理缓存，在clearCache = mgrJsonFileData['clearCache']和临时文件初始化之后
/// 不能直接代码里面clearCacheSwitch0换成mgrJsonFileData['clearCache']，因为后台 isolate与主线程内存隔离机制，tempOnlineDir同理
Future<void> initClearCacheWhenStart(Map<String, dynamic> args) async {
  final clearCacheSwitch0 = args['clearCache'];
  Directory tempOnlineDir = args['tempOnlineDir'];
  if (clearCacheSwitch0 != true) {
    debugPrint('没设置清理缓存.');
    return;
  }
  debugPrint('触发清理缓存.');
  int counter = 0;
  await for (final f in tempOnlineDir.list()) {
    try {
      await f.delete();
      counter++;
    } catch (_) {}
  }
  debugPrint('从缓存中删除$counter');
}

/// 必须被调用的初始化函数，先后顺序很重要
final List<Future<void> Function()> _initFuncs = [
  /// 初始化基础存储目录 √
  initDirOfLongTimeStorage,

  /// 初始化日志系统
  initLogCfgFirst,

  /// 默认封面的内存读取
  initDefaultCoverBytes,

  /// 默认音乐移动
  initMoveDefaultMusicToTop,

  /// 顶层文件中配置软件默认音乐的封面
  initTopJsonFile,

  /// 初始化pkl存储文件夹
  initAppPklDirectory,

  /// 初始化在线听专用目录，包括临时和永久，临时歌曲和自己封面都放在一起，便于清理缓存
  initOnlineDirectory,

  /// 初始化封面存放目录
  initCoversDirectory,

  /// 初始化配置文件
  initRecordFileManager,

  /// 保证初始化有默认音乐
  initCheckNullMusic,
];

/// 注入新初始化函数，但是要注意注入顺序
void registerInitFunc(Future<void> Function() func) {
  _initFuncs.add(func);
}

/// 统一初始化系统，需要在构建`runApp`之前调用一次
/// 要保留注入顺序，别用[Future.wait]
Future<void> initGlobalSystem() async {
  for (final f in _initFuncs) {
    await f();
  }

  /// 获取设备内存,linux不考虑
  /// 初始化轮播
  await Future.wait([
    initFetchMemoryInfoIrrelevant(),
    initSwiperJsonIrrelevant(),
  ]);
  await compute(initClearCacheWhenStart, {
    'clearCache': mgrJsonFileData['clearCache'],
    'tempOnlineDir': tempOnlineDir,
  }).catchError((e, s) => debugPrint('后台清理失败: $e\n$s'));
}
