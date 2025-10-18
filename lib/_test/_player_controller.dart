import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_service/audio_service.dart';

import '../Logic/global_config.dart';
import '../Logic/music_info_reader.dart';

/// 播放模式
enum PlaybackMode {
  /// 顺序播放
  sequence,

  /// 单曲循环
  loopOne,

  /// 随机播放
  random,
}

/// 记录每个播放列表的播放源、播放进度
final class PlayListInfo {
  final PlayList playList;
  int currentIndex = -1;
  PlayListInfo({required this.playList, int? index}) {
    if (index != null) {
      currentIndex = index;
    }
  }
}

/// 软件在线计时
class OnlineController extends ChangeNotifier {
  late final DateTime startTime;
  late Timer _timer;
  Duration onlineDuration = Duration.zero;

  OnlineController() {
    startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      onlineDuration = DateTime.now().difference(startTime);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

typedef PlayList = List<MusicInfoReader>;

/// 全局播放器控制器
/// 功能不限于播放、上一首、下一首、播放模式（单曲循环、顺序、随机）、网络播放
/// 随机歌单、收藏歌单、临时队列歌单，均源于乐库，乐库的歌曲被删除的时候，会影响除了临时队列的全部歌单
class PlayerController extends ChangeNotifier {
  /// 播放器
  final AudioPlayer audioPlayer = AudioPlayer();

  /// 当前音乐
  MusicInfoReader _currentMusicInfo = initInfo;

  /// 播放模式
  PlaybackMode playbackMode = {
    0: PlaybackMode.sequence,
    1: PlaybackMode.random,
    2: PlaybackMode.loopOne,
  }[mgrPreMusicData['playbackMode'] as int]!;

  /// 当前处于哪个播放列表中（我的收藏、乐库也是特殊的播放列表），0表示乐库、1表示我的收藏
  int currentPlayTarget = mgrPlayTarget;
  final List<PlayListInfo> playListInfos = [];

  /// 播放列表，当前歌曲
  PlayList _playlist = [];
  int _currentIndex = -1;

  /// 播放/暂停状态
  bool _isPaused = true; // 默认状态为暂停

  /// 当前添加失败个数，展示在搜索栏的SnackBar
  int failSnackBarCounter = 0;

  /// 访问当前音乐信息
  MusicInfoReader get currentMusicInfo => _currentMusicInfo;

  /// 绑定单例
  /// 0是搜索栏状态，1是浮动球状态
  final Map<int, dynamic> bindMaps = {};

  /// 队列，用于“加入队列”功能
  /// 可以这样听歌：歌曲ABABABABAAACDCDDA，这是本软件设计的最终目的之一
  final List<MusicInfoReaderWithUniqueKey> _queue = [];

  /// 队列指针，用于同步上、下首歌曲
  int queueIndex = -1;

  bool get isPaused => _isPaused;
  PlayList get playLists => _playlist;
  bool get isPlaying => audioPlayer.state == PlayerState.playing;
  int get currentIndex => _currentIndex;
  List<MusicInfoReaderWithUniqueKey> get queue => _queue;
  bool get isDefaultMusic => currentMusicInfo.musicPath == mgrDefaultMusicPath;
  bool get isPlayingFavors => currentPlayTarget == 1;
  bool get isPlayingLib => currentPlayTarget == 0;
  bool get isPlayingQueue => -1 < queueIndex && queueIndex < _queue.length;
  bool get isPlayingOnlineOneTime =>
      currentMusicInfo.anySign.containsKey('web') &&
          currentMusicInfo.anySign['web'] != 1;
  bool get isPlayingOnlineTemp =>
      currentMusicInfo.anySign.containsKey('web') &&
          currentMusicInfo.anySign['web'] == 1;
  (bool, MusicInfoReader) get randomInfo => playTotalLib.isEmpty
      ? (true, PlayerController.defaultReplace)
      : (false, playTotalLib[randomGenerate.nextInt(playTotalLib.length)]);

  /// 乐库
  late PlayList playTotalLib;

  /// 随机模式控制器
  Random randomGenerate = Random();

  /// 自动关闭用的计时器
  Timer? _autoStopTimer;
  Timer? _autoStopTick; // 每秒更新剩余时间
  DateTime? _autoStopStartTime;
  Duration? _autoStopDuration;

  /// 计时器剩余时间（分钟\秒），向上取，比如说剩余1分2秒，取2分钟
  int timerLeft = 0;

  /// 设置定时关闭，long为倒计时时长
  void setAutoStop(int long, bool seconds) {
    _autoStopTimer?.cancel();
    _autoStopTick?.cancel();

    _autoStopStartTime = DateTime.now();
    _autoStopDuration = seconds
        ? Duration(seconds: long)
        : Duration(minutes: long);
    timerLeft =
        _autoStopDuration!.inSeconds ~/ 60 +
            (_autoStopDuration!.inSeconds % 60 > 0 ? 1 : 0);

    _autoStopTimer = Timer(_autoStopDuration!, () async {
      await audioPlayer.pause();
      _isPaused = true;
      _autoStopTimer = null;
      _autoStopTick?.cancel();
      _autoStopTick = null;
      timerLeft = 0;
      notifyListeners();
      debugPrint("播放器已定时停止");
    });

    /// 每秒更新剩余分钟
    _autoStopTick = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(_autoStopStartTime!);
      final remain = _autoStopDuration! - elapsed;
      timerLeft = remain.inSeconds <= 0
          ? 0
          : remain.inSeconds ~/ 60 + (remain.inSeconds % 60 > 0 ? 1 : 0);
      notifyListeners();

      if (timerLeft <= 0) {
        timer.cancel();
      }
    });

    debugPrint("定时器已启动，将在 $long${seconds ? "秒" : "分钟"}后停止播放器");
  }

  void setAutoStopMinute(int long) => setAutoStop(long, false);

  /// 取消定时关闭
  void cancelAutoStop() {
    if (_autoStopTimer == null) {
      debugPrint("没设置定时器，操作取消。");
      return;
    }
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _autoStopTick?.cancel();
    _autoStopTick = null;
    _autoStopStartTime = null;
    _autoStopDuration = null;
    timerLeft = 0;
    debugPrint("定时关闭已取消");
  }

  PlayerController() {
    /// 监听播放状态变化
    audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      // 仅根据播放器的真实状态更新 _isPaused
      _isPaused = state == PlayerState.paused;
      notifyListeners();
    });

    /// 监听播放完成并告诉播放器是自动下一首
    audioPlayer.onPlayerComplete.listen((_) {
      next(autoNext: true);
    });
  }

  /// 跳转歌曲至某进度
  Future<void> seekToPercent(double to) async {
    final duration = await audioPlayer.getDuration();
    if (duration == null) {
      debugPrint("⚠️ 歌曲还没准备好，无法获取总时长");
      return;
    }

    final target = Duration(
      milliseconds: (duration.inMilliseconds * to).round(),
    );
    await audioPlayer.seek(target);
    debugPrint("⏩ 已跳转到 ${to * 100}%");
  }

  /// 载入一首新音乐到乐库
  Future<void> addMusicToPlaylistLib(
      MusicInfoReader info, {
        bool? headIndex,
        bool toPkl = true,
        bool notify = false,
      }) async {
    debugPrint('载入新音乐: ${info.musicPath}');
    headIndex == true ? playTotalLib.insert(0, info) : playTotalLib.add(info);
    if (toPkl) {
      /// 写入缓存
      await info.toPickleAsync();
      debugPrint("Write ${info.musicPath} to Src");
    }
    if (notify) {
      notifyListeners();
    }
  }

  /// 是否顺序模式下队列的歌曲播放到最后一首了
  bool get isQueueEnd {
    return playbackMode == PlaybackMode.sequence &&
        queueIndex > -1 &&
        queueIndex == _queue.length - 1;
  }

  /// 重设队列至初始化
  void resetQueue() {
    _queue.clear();
    queueIndex = -1;
    debugPrint('队列被再次初始化');
    notifyListeners();
  }

  /// 删除队列的指定歌曲
  void removeItemAtQueue(int index) {
    _queue.removeAt(index);
    notifyListeners();
  }

  /// 插入指定歌曲到队列
  /// 只做插入，[queueIndex]同步另外考虑
  void insertItemAtQueue(MusicInfoReaderWithUniqueKey info, int index) {
    _queue.insert(index, info);
    notifyListeners();
  }

  /// 更换当前的音乐列表
  Future<void> setPlaylist(int toIndex) async {
    if (toIndex == _currentIndex) {
      debugPrint('已经处于当前播放列表');
      return;
    }

    /// 原来模式备份信息
    playListInfos[currentPlayTarget].currentIndex = _currentIndex;

    /// 更新
    _playlist = playListInfos[toIndex].playList;
    _currentIndex = playListInfos[toIndex].currentIndex;
    currentPlayTarget = toIndex;
    await saveMgrSrcData(key: 'playTarget', value: currentPlayTarget);
  }

  /// 初始化当前的音乐列表
  void initPlaylist(PlayList list) {
    _playlist = list;
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
  }

  void setFailSnackBarCounter(int number) {
    failSnackBarCounter = number;
    notifyListeners();
  }

  /// 初始化异步加载所有歌曲记录，并设置播放列表和历史歌曲索引
  Future<void> loadInitialPlaylistAndRecord() async {
    playTotalLib = [];

    /// 异步加载所有音乐记录顺便进行坏区检查
    await for (final music in MusicInfoReader.loadPicklesAsync()) {
      final isValid = await badPklchecker(music);
      if (isValid) {
        playTotalLib.add(music);

        /// 是否被收藏
        if (favorsMap.containsKey(music.musicPath)) {
          music.favorId = favorsMap[music.musicPath];
          favors.add(music);
          debugPrint('其中${music.musicPath}被收藏。');
        }
        debugPrint('载入音乐: ${music.musicPath}');
      } else {
        debugPrint('坏区检测，出了问题直接删除base64文件 : ${music.musicPath}');

        /// 顺便从我的收藏中移除
        favorsMap.remove(music.musicPath);
      }
    }

    /// 万一有坏区
    /// 同步到Src的Json，同步到我的收藏Json
    await saveMgrMixinData({'src': mgrSrcData, 'favor': mgrMyFavor});

    /// 乐库按照id排序
    playTotalLib.sort((a, b) => a.id.compareTo(b.id));

    /// 收藏按照字典中的收藏顺序，一定不为空
    favors.sort((a, b) => a.favorId!.compareTo(b.favorId!));

    /// 写入歌单列表
    playListInfos.add(PlayListInfo(playList: playTotalLib));
    playListInfos.add(PlayListInfo(playList: favors));

    /// 将加载好的列表设置给播放器
    initPlaylist(playListInfos[currentPlayTarget].playList);

    debugPrint("加载至上次停留的音乐列表 ：$currentPlayTarget");

    /// 历史音乐记录，找到它的索引并设置
    if (initInfoState == 4) {
      final index = _playlist.indexOf(initInfo);
      _currentIndex = index;

      debugPrint("Init _currentIndex = $_currentIndex");

      /// 从全局配置中读取上次播放退出时的音乐信息到初始音乐
      /// 这一步只是获取了音乐信息，但没有加载到播放器
      /// 另外套一层try防止意想不到的bug
      try {
        _currentMusicInfo = _playlist[index];
      } catch (e) {
        _currentIndex = -1;
        _currentMusicInfo = defaultReplace;
        debugPrint('意外捕捉，原因：$e');
      }

      await audioPlayer.setSourceDeviceFile(_currentMusicInfo.musicPath);
      if (!_currentMusicInfo.anySign.containsKey('web')) {
        await writeInfoToRecord(_currentMusicInfo);
      }
      notifyListeners();
      return;
    }

    /// 这样保证无论有没有历史记录，都有歌曲在浮动球上
    _currentMusicInfo = PlayerController.defaultReplace;
    await audioPlayer.setSourceDeviceFile(_currentMusicInfo.musicPath);
    notifyListeners();
  }

  static MusicInfoReader get defaultReplace =>
      MusicInfoReader.createSync(mgrDefaultMusicPath, isDefaultPath: true);

  /// 仅仅是更新索引和信息
  void justUpdateMusicAndIndex(MusicInfoReader info, int index) {
    _currentIndex = index;
    _currentMusicInfo = info;
    notifyListeners();
  }

  /// 只是临时听歌曲，索引保持不变
  Future<void> listenButNochangedIndex(MusicInfoReader info) async {
    _currentMusicInfo = info;
    await audioPlayer.stop();
    await audioPlayer.setSourceDeviceFile(info.musicPath);
    await audioPlayer.resume();
    notifyListeners();
  }

  /// 自动查索引（一定存在）
  Future<void> updateInfoByExistAutoIndex(
      MusicInfoReader info,
      bool isDefault, {
        bool forceRestart = false,
        bool shouldPlay = true,
      }) async {
    return await updateInfoByExist(
      info,
      isDefault ? -1 : playTotalLib.indexOf(info),
      forceRestart: forceRestart,
      shouldPlay: shouldPlay,
    );
  }

  /// 设置forceRestart来强制一首在播放歌曲重新播放
  Future<void> updateInfoByExist(
      MusicInfoReader info,
      int index, {
        bool forceRestart = false,
        bool shouldPlay = true,
      }) async {
    _currentMusicInfo = info;
    _currentIndex = index;
    if (forceRestart) {
      /// 单曲循环需要强制从头开始
      await audioPlayer.stop();
      await audioPlayer.setSourceDeviceFile(info.musicPath);
      if (shouldPlay) {
        await audioPlayer.resume();
      }
    } else {
      await audioPlayer.setSourceDeviceFile(info.musicPath);
      if (shouldPlay) {
        await audioPlayer.resume();
      }
    }

    /// 若是本地导入则同时记录到上次播放记录，网络来源这种临时歌曲则不会被记录
    if (!info.anySign.containsKey('web')) {
      await writeInfoToRecord(info);
    }
    notifyListeners();
  }

  void updateMode(PlaybackMode p) {
    playbackMode = p;
    notifyListeners();
  }

  Future<void> playPause() async {
    _isPaused ? await audioPlayer.resume() : await audioPlayer.pause();
  }

  /// 允许临时重播功能
  void allowAgainTemp(MusicInfoReader info) {
    info.anySign['again'] = true;
    notifyListeners();
  }

  /// 触发临时重播功能
  Future<void> playAgainTemp() async {
    currentMusicInfo.anySign.remove('again');
    return await updateInfoByExist(
      _currentMusicInfo,
      _currentIndex,
      forceRestart: true,
    );
  }

  Future<void> next({bool nextIsClicked = false, bool autoNext = false}) async {
    if (_playlist.isEmpty) {
      debugPrint('Playlist is empty.');
      if (currentMusicInfo.anySign.containsKey('again')) {
        return await playAgainTemp();
      }
      return await updateInfoByExist(
        _currentMusicInfo,
        _currentIndex,
        forceRestart: true,
      );
    }

    /// 临时重播优先级 > 队列模式
    if (currentMusicInfo.anySign.containsKey('again')) {
      return await playAgainTemp();
    }

    int newIndex = _currentIndex;
    bool needRestart = false;
    MusicInfoReader info = currentMusicInfo;

    switch (playbackMode) {
      case PlaybackMode.sequence:

      /// 顺序播放模式下，如果该轮队列的最后一首歌曲播放结束或者切到下一首（这时候队列以及没有歌曲了），队列会重新初始化
      /// 没放完队列的最后一首歌曲或者不主动切换是不会清理队列的
        if (queueIndex == _queue.length - 1 && queueIndex > -1) {
          resetQueue();
        }

        /// 队列歌曲是否放完了，空队列也可以跟着判断
        if (_queue.isNotEmpty) {
          /// 队列还有歌曲
          info = _queue[++queueIndex].info;
          needRestart = true;

          /// 不然做不到重复播放
          debugPrint('从队列播放: ${info.musicPath}');
          break;
        }

        newIndex = (_currentIndex + 1) % _playlist.length;
        info = _playlist[newIndex];
        break;
      case PlaybackMode.random:
        if (_playlist.length > 1) {
          newIndex = randomGenerate.nextInt(_playlist.length);
          info = _playlist[newIndex];
        }

        /// 即使随机到同一首，也要重播
        needRestart = true;
        break;
      case PlaybackMode.loopOne:

      /// 循环模式、自动下一首的时候，支持在线播放单曲循环
        if (info.anySign.containsKey('web') && autoNext) {
          debugPrint('循环模式、自动下一首的时候，支持在线播放单曲循环');
          return listenButNochangedIndex(info);
        }
        newIndex = nextIsClicked
            ? (_currentIndex + 1) % _playlist.length
            : _currentIndex;
        info = _playlist[newIndex];
        needRestart = true;
        break;
    }
    await updateInfoByExist(info, newIndex, forceRestart: needRestart);
  }

  Future<void> previous({bool previousIsClicked = false}) async {
    if (_playlist.isEmpty) {
      debugPrint('Playlist is empty.');
      if (currentMusicInfo.anySign.containsKey('again')) {
        return await playAgainTemp();
      }
      return await updateInfoByExist(
        _currentMusicInfo,
        _currentIndex,
        forceRestart: true,
      );
    }

    if (currentMusicInfo.anySign.containsKey('again')) {
      return await playAgainTemp();
    }

    int newIndex = currentIndex;
    bool needRestart = false;
    MusicInfoReader info = currentMusicInfo;

    switch (playbackMode) {
      case PlaybackMode.sequence:

      /// 还在队列模式中
      /// 未达到队头
        if (queueIndex > 0) {
          needRestart = true;

          /// 不然做不到重复播放
          info = _queue[--queueIndex].info;
          break;
        } else if (queueIndex == 0) {
          /// 已经在队列的第一首，再点上一首就退出队列，否则--queueIndex后到达-1
          /// 跳到队列播放之前的最近一首歌曲
          queueIndex--;
          newIndex = currentIndex;
          info = _playlist[newIndex];
          needRestart = true;
          break;
        }

        newIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
        info = _playlist[newIndex];
        break;
      case PlaybackMode.random:
        if (_playlist.length > 1) {
          newIndex = randomGenerate.nextInt(_playlist.length);
          info = _playlist[newIndex];
        }

        /// 即使随机到同一首，也要重播
        needRestart = true;
        break;
      case PlaybackMode.loopOne:
        newIndex = previousIsClicked
            ? (_currentIndex - 1 + _playlist.length) % _playlist.length
            : _currentIndex;
        info = _playlist[newIndex];
        needRestart = true;
        break;
    }

    await updateInfoByExist(info, newIndex, forceRestart: needRestart);
  }

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  /// 检测乐库列表是否为空或者歌曲是不是默认替代音乐
  /// 这时候保证浮动球的歌曲禁用删除功能按键
  bool isEmptyOrDefault() {
    return playTotalLib.isEmpty || _currentIndex == -1;
  }

  /// 我的收藏
  final PlayList favors = [];
  final Map<String, dynamic> favorsMap = mgrMyFavor;

  /// 移除一个收藏
  /// 包括列表记录、收藏时间点、写入保存
  Future<void> removeFavorItem(
      MusicInfoReader info, {
        bool notify = false,
      }) async {
    info.favorId = null;
    favors.remove(info);
    favorsMap.remove(info.musicPath);
    await saveMgrSrcData(key: 'favor');
    if (notify) {
      notifyListeners();
    }
  }

  /// 添加一首收藏并且保存记录
  Future<void> appendToFavor(MusicInfoReader info) async {
    info.favorId = mgrFovorCounter++;
    mgrMyFavor[info.musicPath] = info.favorId!;
    favors.add(info);
    await saveMgrMixinData({
      'favorCounter': mgrFovorCounter,
      'favor': mgrMyFavor,
    });
    notifyListeners();
  }

  /// 系统播放器的分发
  /// 状态流，用于通知 AudioHandler 更新通知栏
  final _stateStreamController = StreamController<PlaybackState>.broadcast();
  Stream<PlaybackState> get stateStream => _stateStreamController.stream;

  /// 位置流，用于更新进度，通知栏需要显示进度
  final _positionStreamController = StreamController<Duration>.broadcast();
  Stream<Duration> get positionStream => _positionStreamController.stream;

  /// 媒体项流，用于更新歌曲信息
  final _mediaItemStreamController = StreamController<MediaItem>.broadcast();
  Stream<MediaItem> get mediaItemStream => _mediaItemStreamController.stream;


}

