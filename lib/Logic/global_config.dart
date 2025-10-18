import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:charset_converter/charset_converter.dart';

import 'music_info_reader.dart' show MusicInfoReader;

part 'logger_system.dart';
part 'need_call.dart';
part 'util.dart';
part 'card_assets_api.dart';
part 'swiper_card_loader.dart';

const List<String> supportType = ['mp3', 'flac'];
const List<String> dotSupportType = ['.mp3', '.flac'];

final _jsonEncoder = JsonEncoder.withIndent('  ');

final globalDio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 2), // 连接超时 2 秒
    receiveTimeout: const Duration(seconds: 2), // 响应接收超时 2 秒
    followRedirects: true,
    validateStatus: (status) => status! < 500,
  ),
);

final globalUuid = const Uuid();

/// 默认安卓，其他不考虑
final isPlatformWithMobile = Platform.isAndroid;

/// 默认字体大小
final double platformDefaultFontSize = isPlatformWithPC ? 16.0 : 12.0;

/// 多item的限高、宽亦如此
final double maxHeightForPlatform = isPlatformWithPC ? 70.0 : 55.0;

/// | 类型              | 目录                                                                   | 是否随卸载删除 | 是否随升级删除 | 用途                               |
/// | --------------- | -------------------------------------------------------------------- | ------- | ------- | -------------------------------- |
/// | **内部存储 App 专属** | `/data/data/<package>/files`  或 `getApplicationDocumentsDirectory()` | ✅删除     | ❌保留     | 配置、数据库、重要数据（升级不会丢）               |
/// | **内部缓存**        | `/data/data/<package>/cache` 或 `getTemporaryDirectory()`             | ✅删除     | ❌保留     | 临时缓存，系统空间紧张时也会清理                 |
/// | **外部存储 App 专属** | `/storage/emulated/0/Android/data/<package>/files`                   | ✅删除     | ❌保留     | 大文件、可导出数据（但 Android 11+ 受分区存储限制） |
/// | **外部缓存**        | `/storage/emulated/0/Android/data/<package>/cache`                   | ✅删除     | ❌保留     | 大缓存文件                            |
/// | **公共目录**        | `/storage/emulated/0/Download`, `Pictures` 等                         | ❌保留     | ❌保留     | 用户可见文件，需要权限管理                    |
/// 为了在每次更新软件的时候保留持久化存储，把配置+缓存放到/storage/emulated/0/Android/data/com.xxx.xxx/files (可能为空)
late final Directory dirOfLongTimeStorage;
Future<void> initDirOfLongTimeStorage() async {
  var dir = isPlatformWithPC
      ? await getApplicationDocumentsDirectory()
      : await getExternalStorageDirectory();
  dirOfLongTimeStorage = dir ?? await getApplicationDocumentsDirectory();
  debugPrint('顶层文件夹（总目录）:${dirOfLongTimeStorage.path}');
}

/// 移动端沙盒创建文件夹，false表示已经存在了，创建失败了
Future<(Directory, bool)> createDirOnMobile(String dirName) async {
  if (isPlatformWithPC) {
    return (pklDir, false);
  }
  final targetDir = Directory('${dirOfLongTimeStorage.path}/$dirName');
  if (await targetDir.exists()) {
    return (targetDir, false);
  } else {
    return (await targetDir.create(recursive: true), true);
  }
}

/// 缓存系统
late final Directory pklDir;

/// 桌面端写到assets的pkl文件夹，移动端写在内置沙箱的pkl文件夹，没有先创建
Future<void> initAppPklDirectory() async {
  if (isPlatformWithPC) {
    pklDir = Directory('assets/pkl/');
  } else {
    final targetDir = Directory('${dirOfLongTimeStorage.path}/pkl');
    if (!(await targetDir.exists())) {
      await targetDir.create(recursive: true);
    }
    pklDir = targetDir;
  }
  debugPrint('加载PKL文件夹完毕！');
}

/// 两个在线专用文件夹，分开写方便清空临时缓存
/// 临时缓存歌曲本体文件夹
late Directory tempOnlineDir;

/// 永久缓存歌曲本体文件夹
late Directory foreverOnlineDir;

/// 桌面端写到assets的'temp_online'/'forever_online'文件夹，移动端写在内置沙箱的temp_online/forever_online文件夹，没有先创建
Future<void> initOnlineDirectory() async {
  if (isPlatformWithPC) {
    tempOnlineDir = Directory('assets/temp_online/');
    foreverOnlineDir = Directory('assets/forever_online');
  } else {
    final targetDir = Directory('${dirOfLongTimeStorage.path}/temp_online');
    if (!(await targetDir.exists())) {
      await targetDir.create(recursive: true);
    }
    tempOnlineDir = targetDir;
    final targetDir2 = Directory('${dirOfLongTimeStorage.path}/forever_online');
    if (!(await targetDir2.exists())) {
      await targetDir2.create(recursive: true);
    }
    foreverOnlineDir = targetDir2;
  }
  debugPrint("'temp_online'/'forever_online'文件夹");
}

/// 歌曲封面系统
late final Directory coverDir;

/// 桌面端写到assets的covers文件夹，移动端写在内置沙箱的covers文件夹，没有先创建
Future<void> initCoversDirectory() async {
  if (isPlatformWithPC) {
    coverDir = Directory('assets/covers/');
  } else {
    final targetDir = Directory('${dirOfLongTimeStorage.path}/covers');
    if (!(await targetDir.exists())) {
      await targetDir.create(recursive: true);
    }
    coverDir = targetDir;
  }
  debugPrint('载入封面路径：${coverDir.path}');
}

/// 第一次初始化随机生成的名字
String _initUserName() {
  final adj = ['可爱的', '帅气的', '潇洒的', '疯狂的', '睿智的'];
  final obj = ['男孩', '美少女', '帽子', '菠萝包'];
  final rd = Random();
  return adj[rd.nextInt(adj.length)] + obj[rd.nextInt(obj.length)];
}

/// 文件记录系统，软件第一次运行后会生成该记录配置文件
late final Directory mgrDir;
late final File mgrJsonFile;
late final Map<String, dynamic> mgrJsonFileData;

/// 只有被缓存到pkl文件夹才能查询，mgrSrcData防查重
late final Map<String, dynamic> mgrSrcData;

/// 用户画像
late final Map<String, dynamic> mgrUserData;

/// 上一次听歌记录
late final Map<String, dynamic> mgrPreMusicData;

/// 音乐导入记录和置顶记录
late int mgrMusicCounter;
late int mgrMusicToTop;

/// 我的收藏，实际上是`Map<String, int>`
late final Map<String, dynamic> mgrMyFavor;

/// 收藏记录
late int mgrFovorCounter;

/// 播放目标列表记录
late int mgrPlayTarget;

/// 乐库卡片透明度、乐库透明度、每秒gif帧率，不对外开放修改
late final double cardOpacity;
late final double listOpacity;
late final int gifFps;

/// 乐库背景图片，字符串0表示无，字符串1表示默认图片，字符串2表示默认gif，其他字符串表示本地设置的图片
late String mgrBgMode;

/// 播放手势：单击播放还是双击播放（防误触）
late bool singleClick;

/// 桌面端写到assets的mgr文件夹，移动端写在内置沙箱的mgr文件夹，都叫mgr.json
Future<void> initRecordFileManager() async {
  if (isPlatformWithPC) {
    mgrDir = Directory('assets/mgr/');
  } else {
    mgrDir = Directory('${dirOfLongTimeStorage.path}/mgr');
  }
  if (!await mgrDir.exists()) {
    await mgrDir.create(recursive: true);
  }
  mgrJsonFile = File('${mgrDir.path}/mgr.json');
  if (!await mgrJsonFile.exists()) {
    debugPrint('首次启动，创建配置文件：${mgrJsonFile.path}');
    await mgrJsonFile.writeAsString(
      jsonEncode({
        "src": {},
        "user": {"name": _initUserName(), "register": getFormatTime(), "mode" : 0},
        "music": {"currentMusic": null, 'playbackMode': 0, 'infopkl': null},
        "counter": 1,
        "toTop": -1,
        "favorCounter": 0,
        "favor": {},
        "playTarget": 0,
        "copacity": 0.5,
        "lopacity": 0.9,
        "bgMode": "0",
        "gifFps": 15,
        "clearCache" : false,
        "singleClick" : true
      }),
    );
  } else {
    debugPrint('配置文件已存在：${mgrJsonFile.path}');
  }
  mgrJsonFileData = jsonDecode(await mgrJsonFile.readAsString());
  mgrSrcData = mgrJsonFileData['src'];
  mgrUserData = mgrJsonFileData['user'];
  mgrPreMusicData = mgrJsonFileData['music'];
  mgrMusicCounter = mgrJsonFileData['counter'];
  mgrMusicToTop = mgrJsonFileData['toTop'];
  mgrMyFavor = mgrJsonFileData['favor'];
  mgrFovorCounter = mgrJsonFileData['favorCounter'];
  mgrPlayTarget = mgrJsonFileData['playTarget'];
  cardOpacity = mgrJsonFileData['copacity'];
  listOpacity = mgrJsonFileData['lopacity'];
  mgrBgMode = mgrJsonFileData['bgMode'];
  gifFps = mgrJsonFileData['gifFps'];
  singleClick = mgrJsonFileData['singleClick'];
  debugPrint('用户信息加载完毕！');
}

/// 保存mgrSrcData
/// 顶层函数，compute 调用必须是顶层或静态函数
Future<void> _writeToFileIsolate(Map<String, String> args) async {
  final file = File(args['path']!);
  await file.writeAsString(args['data']!, flush: true);
}

/// 后台保存mgrJson信息
Future<void> saveMgrSrcData({String key = 'src', Object? value}) async {
  switch (key) {
    case 'src':
      mgrJsonFileData['src'] = mgrSrcData;
      break;
    case 'user':
      mgrJsonFileData['user'] = mgrUserData;
      break;
    case 'music':
      mgrJsonFileData['music'] = mgrPreMusicData;
      break;
    case "counter":
      mgrJsonFileData['counter'] = mgrMusicCounter;
    case "toTop":
      mgrJsonFileData['toTop'] = mgrMusicToTop;
    case "favor":
      mgrJsonFileData['favor'] = mgrMyFavor;
    case "favorCounter":
      mgrJsonFileData['favorCounter'] = mgrFovorCounter;
    case "playTarget":
      mgrJsonFileData['playTarget'] = value;
    case "sortIds":
      mgrJsonFileData['sortIds'] = value;
    case "bgMode":
      mgrJsonFileData['bgMode'] = mgrBgMode;
    case "defaultMusicCover":
      mgrJsonFileData['defaultMusicCover'] = value;
    case "clearCache":
      mgrJsonFileData['clearCache'] = value;
    case "singleClick":
      mgrJsonFileData['singleClick'] = value;
    default:
      debugPrint('未找到key: $key');
      /// 不支持果断退出
      return;
  }
  final path = mgrJsonFile.path;
  final data = _jsonEncoder.convert(mgrJsonFileData);

  /// 后台写入，避免阻塞 UI
  await compute(_writeToFileIsolate, {'path': path, 'data': data});
}

/// 后台保存多mgrJson信息
Future<void> saveMgrMixinData(Map<String, dynamic> data) async {
  data.forEach((k, v) {
    mgrJsonFileData[k] = v;
  });
  final path = mgrJsonFile.path;
  final dataFinal = _jsonEncoder.convert(mgrJsonFileData);

  /// 后台写入，避免阻塞 UI
  await compute(_writeToFileIsolate, {'path': path, 'data': dataFinal});
}

/// 文件名字
String getFileName(String path) => path.split(Platform.pathSeparator).last;

/// 文件类型
String getFileType(String path) => '.${getFileName(path).split('.').last}';

/// 是否支持
bool isSupportType(String path) =>
    supportType.contains(getFileType(path)) ||
    dotSupportType.contains(getFileType(path));

/// 文件存在
bool isExistFile(String path) => File(path).existsSync();

/// 默认这三种都是PC
final isPlatformWithPC =
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

/// 标记罢了
final class Signal {
  final String mgs;
  const Signal(this.mgs);
}

/// 获取设备内存,linux不考虑 Irrelevant结尾表示与调用顺序无关
late final int ramTotal;
Future<void> initFetchMemoryInfoIrrelevant() async {
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    ramTotal = androidInfo.physicalRamSize;
  } else if (Platform.isWindows) {
    final windowsInfo = await deviceInfo.windowsInfo;
    ramTotal = windowsInfo.systemMemoryInMegabytes;
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    ramTotal = iosInfo.physicalRamSize;
  } else if (Platform.isLinux) {
    ramTotal = 0;
  }
  debugPrint('初始化内存读取');
}
