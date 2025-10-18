import 'dart:io';
import 'dart:convert';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:path/path.dart' as flutter_path;
import 'package:permission_handler/permission_handler.dart';

import 'global_config.dart';

final _prettyJonEncoder = JsonEncoder.withIndent('  ');

/// 播放器不会封装已有MusicInfoReader中musicPath路径相同的音乐
class MusicInfoReader {
  final String musicPath;
  final String encodeName;
  final String artist;
  final String title;
  final int musicLength;
  final String loadTime;

  /// 每个歌曲导入的时候会被分配一个独一无二的id来记录导入顺序（只影响导入顺序）
  /// id可以被修改的唯一方法是，被置顶后anySign记录，退出保存pkl并且重启重新赋值
  final int id;

  /// 封面路径，保证都写到外部存储能让Image.file读取
  final String coverPath;

  /// 封面的格式
  final String mimeType;

  /// 该方法记录临时任意绑定信息
  /// 存在键web则表示来源于网络，web == 1则表示临时记录
  /// 存在键again表示临时重播，不考虑播放模式
  /// 存在键id表示重新设置导入顺序
  final Map<String, dynamic> anySign;

  /// 收藏时间，越小越早越靠前，没有表示没收藏
  int? favorId;

  MusicInfoReader._({
    required this.musicPath,
    required this.encodeName,
    required this.artist,
    required this.title,
    required this.musicLength,
    required this.coverPath,
    required this.anySign,
    required this.id,
    required this.loadTime,
    required this.mimeType,
  });

  @override
  String toString() {
    return 'MusicInfoReader('
        'musicPath: $musicPath, '
        'encodeName: $encodeName, '
        'artist: $artist, '
        'title: $title, '
        'musicLength: $musicLength, '
        'id: $id, '
        'coverPath: $coverPath'
        ')';
  }

  /// 从一个base64加密的pkl缓存读取信息
  static Future<MusicInfoReader> fromFile(String path) async {
    final String content = await File(path).readAsString(encoding: utf8);
    return MusicInfoReader.fromJson(jsonDecode(content));
  }

  /// 获取文件的名字并且写入封面，isTemp表示是不是暂时载入的音乐，是的话放在temp_online
  static Future<String> backupCover(
    Uint8List bytes, {

    /// 封面的bytes
    bool isTemp = false,
  }) async {
    final String targetPath =
        '${isTemp ? tempOnlineDir.path : coverDir.path}/${globalUuid.v1()}.${judgeMimeType(bytes)}';
    await File(targetPath).writeAsBytes(bytes, flush: true);
    return targetPath;
  }

  static MusicInfoReader get defaultReplace {
    final metadata = readMetadata(File(defaultMusicPath), getImage: true);
    final artist = metadata.artist ?? 'Unknown Artist';
    final title = metadata.title ?? 'Unknown Music Name';
    final musicLength = metadata.duration != null
        ? metadata.duration!.inSeconds
        : 0;
    final mt = 'image/jpeg';
    return MusicInfoReader._(
      musicPath: defaultMusicPath,
      encodeName: encodeSongName(defaultMusicPath),
      artist: artist,
      title: title,
      musicLength: musicLength,
      coverPath: defaultMusicCoverPath,
      id: 0,
      loadTime: '2025-08-06 21:29:00',
      mimeType: mt,
      anySign: {},
    );
  }

  /// 从本地音乐路径创建
  static Future<MusicInfoReader> createAsync(
    String musicPath, {
    String? formatTime,
    bool isTemp = false,

    /// 是否需要单独写入一次ID（单次建立建议用）
    bool needRecordCounter = false,
  }) async {
    final encodeName = encodeSongName(musicPath);

    final metadata = readMetadata(File(musicPath), getImage: true);
    late String artist;
    if (metadata.artist != null) {
      artist = await fixGarbledToUtf8(metadata.artist!);
    } else {
      artist = 'Unknown Artist';
    }

    late final String title;
    if (metadata.title != null) {
      title = await fixGarbledToUtf8(metadata.title!);
    } else {
      title = 'Unknown Music Name';
    }
    final musicLength = metadata.duration != null
        ? metadata.duration!.inSeconds
        : 0;

    final id = mgrMusicCounter++;
    late final String getCoverPath;
    late final String mimeType;
    if (metadata.pictures.isEmpty) {
      getCoverPath = replaceCoverPath;
      mimeType = 'image/png';
    } else {
      final front = metadata.pictures.firstWhere(
        (p) => p.pictureType == PictureType.coverFront,
        orElse: () => metadata.pictures[0],
      );
      final bytes = front.bytes;
      getCoverPath = await backupCover(bytes, isTemp: isTemp);
      mimeType = judgeMimeType(bytes) == 'png' ? 'image/png' : 'image/jpeg';
    }

    if (needRecordCounter) {
      await saveMgrSrcData(key: 'counter');
    }
    return MusicInfoReader._(
      musicPath: musicPath,
      encodeName: encodeName,
      artist: artist,
      title: title,
      musicLength: musicLength,
      coverPath: getCoverPath,
      mimeType: mimeType,
      anySign: {},
      id: id,
      loadTime: formatTime ?? getFormatTime(),
    );
  }

  /// 写操作，把类实例转换的pkl文件存在固定位置
  Future<void> toPickleAsync() async {
    final file = File('${pklDir.path}/$encodeName');
    final content = _prettyJonEncoder.convert(toJson());
    await file.writeAsString(content, encoding: utf8);
  }

  /// 记录到src备份
  void writeToSrcData() {
    mgrSrcData[musicPath] = true;
  }

  /// 根据根目录下文件转换，已经过滤掉不支持的格式
  @Signal('仅作为测试用')
  static Future<void> toPicklesAsync(String dirPath) async {
    final names = Directory(dirPath).list();
    await for (final name in names) {
      final path = name.path;
      final info = await MusicInfoReader.createAsync(
        path,
        formatTime: getFormatTime(),
        needRecordCounter: true,
      );
      await info.toPickleAsync();
      debugPrint("Current Path is $path");
      debugPrint("Exist ?? ${isExistFile(path)}");
      debugPrint(info.toString());
    }
  }

  /// 读取安卓端的Music
  @Signal('仅作为测试用')
  static Future<void> _readMusic() async {
    if (await Permission.storage.request().isGranted) {
      final musicDir = Directory('/storage/emulated/0/Music');
      await for (final name in musicDir.list()) {
        final path = name.path;
        if (isSupportType(path) &&
            await FileSystemEntity.type(path) == FileSystemEntityType.file) {
          final info = await MusicInfoReader.createAsync(
            path,
            needRecordCounter: true,
            formatTime: getFormatTime(),
          );
          final file = File('${pklDir.path}/${info.encodeName}');
          final content = _prettyJonEncoder.convert(info.toJson());
          await file.writeAsString(content, encoding: utf8);
          await saveMgrSrcData(key: 'counter');
          debugPrint("Suc in ${file.path}");
        } else {
          debugPrint("ignore！");
        }
      }
    } else {
      debugPrint("未授予权限！");
    }
  }

  /// 默认从各个系统的muisc文件夹根目录找音乐
  @Signal('仅作为测试用')
  static Future<void> toPicklesAsyncDefaultDir() async {
    isPlatformWithPC
        ? toPicklesAsync('${Platform.environment['USERPROFILE']}/Music')
        : _readMusic();
  }

  /// 读操作，只能从pkl文件夹载入
  /// 其中encodePklFilePath是完整的路径
  @Signal('初始化专用')
  static Future<MusicInfoReader> loadPickleAsync(
    String encodePklFilePath,
  ) async {
    final file = File(encodePklFilePath);
    final content = await file.readAsString(encoding: utf8);
    final Map<String, dynamic> json = jsonDecode(content);
    return MusicInfoReader.fromJson(json);
  }

  /// 异步流载入缓存文件生成器
  @Signal('初始化专用')
  static Stream<MusicInfoReader> loadPicklesAsync() async* {
    await for (var entity in pklDir.list()) {
      yield await loadPickleAsync(entity.path);
    }
  }

  Map<String, dynamic> toJson() {
    final int newId = anySign.containsKey('id') ? anySign['id'] : id;
    return {
      'musicPath': musicPath,
      'encodeName': encodeName,
      'artist': artist,
      'title': title,
      'musicLength': musicLength,
      'id': newId,
      'loadTime': loadTime,
      'mimeType': mimeType,
      'coverPath': coverPath,
    };
  }

  factory MusicInfoReader.fromJson(Map<String, dynamic> json) {
    return MusicInfoReader._(
      musicPath: json['musicPath'],
      encodeName: json['encodeName'],
      artist: json['artist'],
      title: json['title'],
      musicLength: json['musicLength'],
      id: json['id'],
      mimeType: json['mimeType'],
      loadTime: json['loadTime'],
      coverPath: json['coverPath'],
      anySign: {},
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is MusicInfoReader) {
      return musicPath == other.musicPath;
    }
    return false;
  }

  @override
  int get hashCode => musicPath.hashCode;

  bool get isReplaceCover => coverPath == replaceCoverPath;

  /// 删除自身
  /// 需要同步：src记录、pkl文件、不会删除本地文件、本地封面
  Future<void> deleteSelf() async {
    final pklPath = '${pklDir.path}/$encodeName';
    await File(pklPath).delete();
    mgrSrcData.remove(musicPath);
    await saveMgrSrcData(key: 'src');
    debugPrint("手动删除：\n\t$pklPath\n\t$musicPath");
    if (!isReplaceCover) {
      await File(coverPath).delete();
    }
  }

  bool get isMps => musicPath.toLowerCase().endsWith('mp3');

  /// 永久地把一个info复制到forever_online和covers文件夹中
  Future<MusicInfoReader> copyButPoint({
    String? pointArtist,
    String? pointTitle,
    String? pointCoverPath,
  }) async {
    final name = globalUuid.v1();
    final newMusicPath =
        "${foreverOnlineDir.path}/$name.${isMps ? ".mp3" : ".flac"}";

    /// 复制文件，包括封面和歌曲本身
    await File(musicPath).copy(newMusicPath);

    /// 歌曲有自己的封面
    late final String newCoverPath;
    if (pointCoverPath == null && !isReplaceCover) {
      newCoverPath =
          "${coverDir.path}/$name.${mimeType == 'image/png' ? 'png' : 'jpg'}";
      await File(coverPath).copy(newCoverPath);
    } else if (pointCoverPath != null) {
      newCoverPath = pointCoverPath;
    } else {
      newCoverPath = coverPath;
    }

    /// 分配新id并且记录以及生成pkl文件
    final info = MusicInfoReader._(
      musicPath: newMusicPath,
      encodeName: encodeSongName(newMusicPath),
      artist: pointArtist ?? artist,
      title: pointTitle ?? title,
      musicLength: musicLength,
      coverPath: newCoverPath,
      anySign: {},
      id: mgrMusicCounter++,
      loadTime: getFormatTime(),
      mimeType: mimeType,
    );
    await info.toPickleAsync();
    await saveMgrMixinData({'src': mgrSrcData, 'counter': mgrMusicCounter});
    return info;
  }
}

/// 非常有用的临时记录，队列中每个info（即使重复）封装到UI分配独一无二的key
int _queueUniqueKey = 0;

final class MusicInfoReaderWithUniqueKey {
  final MusicInfoReader info;
  final int uniqueKey;
  const MusicInfoReaderWithUniqueKey({
    required this.info,
    required this.uniqueKey,
  });

  static MusicInfoReaderWithUniqueKey generate(MusicInfoReader info) {
    return MusicInfoReaderWithUniqueKey(
      info: info,
      uniqueKey: _queueUniqueKey++,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is MusicInfoReaderWithUniqueKey) {
      return other.info.musicPath == info.musicPath;
    } else if (other is MusicInfoReader) {
      return other.musicPath == info.musicPath;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => info.hashCode;
}

/// 坏区检测
/// 当载入的存档音乐不再的时候，会删除MusicInfoReader的pkl记录和src的防重复记录还有封面记录
/// 返回True表示该文件存在不是坏区
Future<bool> badPklchecker(MusicInfoReader info) async {
  final path = flutter_path.absolute(info.musicPath);
  if (!File(path).existsSync()) {
    if (!info.isReplaceCover) {
      await File(info.coverPath).delete();
    }
    final pklFilePath = '${pklDir.path}/${info.encodeName}';
    await File(pklFilePath).delete();
    mgrSrcData.remove(path);
    debugPrint(
      'The $pklFilePath && $path && ${info.coverPath}（可能是空） are deleted!',
    );
    return false;
  }
  return true;
}
