import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';

/// ------------------------------------------------------------
/// MyAudioHandler
/// ------------------------------------------------------------
///
/// 这个类继承自 [BaseAudioHandler]，是整个音频后台逻辑的核心。
/// 它把三个库结合起来：
///
/// - [media_kit]：实际的音频播放（底层）
/// - [audio_session]：管理媒体焦点（如电话、闹钟、其他App音频冲突）
/// - [audio_service]：连接系统通知栏、锁屏控件、后台播放等系统级功能
///
class MyAudioHandler extends BaseAudioHandler {
  // 使用 media_kit 提供的 Player 实例进行播放
  final Player _player = Player();

  MyAudioHandler() {
    _init();
  }

  /// 初始化逻辑：设置 AudioSession、监听中断事件、监听播放状态
  Future<void> _init() async {
    // 1️⃣ 配置 audio_session
    // 这告诉系统当前 App 是“音乐播放”用途，会影响焦点策略。
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // 2️⃣ 监听系统音频中断事件
    // 比如来电、闹钟、语音助手启动等。
    session.interruptionEventStream.listen((event) async {
      if (event.begin) {
        // 如果中断开始（例如来电），暂停播放
        await _player.pause();
        playbackState.add(playbackState.value.copyWith(playing: false));
      } else {
        // 中断结束时，这里不自动恢复播放（你可改成自动恢复）
      }
    });

    // 3️⃣ 监听 media_kit 的播放状态变化
    // 用来同步 audio_service 的 [playbackState]，
    // 这样系统通知栏和锁屏控件就能正确反映状态。
    _player.stream.playing.listen((isPlaying) {
      final position = _player.state.position ?? Duration.zero;

      // 更新 AudioService 的状态（通知栏按钮、播放位置等）
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: AudioProcessingState.ready,
        playing: isPlaying,
        updatePosition: position,
        speed: _player.state.rate,
      ));
    });
  }

  /// ------------------------------------------------------------
  /// 播放
  /// ------------------------------------------------------------
  @override
  Future<void> play() async {
    // 向系统请求“激活音频焦点”
    // 如果返回 false，说明焦点没拿到（被别的App占用）
    final session = await AudioSession.instance;
    final success = await session.setActive(true);
    if (!success) return;

    try {
      // 打开一个远程 mp3 音频文件
      await _player.open(Media(
        r'https://lw-sycdn.kuwo.cn/18dce63aad64521791c69c799e506739/68ef9520/resource/30106/trackmedia/M500002QE4Dt4Gkrgd.mp3?bitrate$128&from=vip',
      ));

      await _player.play();

      // 设置系统通知栏显示的歌曲信息
      mediaItem.add(MediaItem(
        id: 'https://example.com/example.mp3',
        album: "Example Album",
        title: "Example Track",
        artist: "SoundHelix",
        duration: const Duration(minutes: 5),
      ));
    } catch (e) {
      debugPrint('play error: $e');
    }
  }

  /// ------------------------------------------------------------
  /// 暂停
  /// ------------------------------------------------------------
  @override
  Future<void> pause() async {
    await _player.pause();
    // 释放媒体焦点，允许其他App播放音频
    await AudioSession.instance.then((s) => s.setActive(false));
  }

  /// ------------------------------------------------------------
  /// 停止
  /// ------------------------------------------------------------
  @override
  Future<void> stop() async {
    await _player.stop();
    // 同样释放音频焦点
    await AudioSession.instance.then((s) => s.setActive(false));

    // 通知 audio_service 状态变更
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
  }

  /// ------------------------------------------------------------
  /// 跳转播放位置
  /// ------------------------------------------------------------
  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// ------------------------------------------------------------
  /// 释放资源（可选）
  /// ------------------------------------------------------------
  Future<void> disposePlayer() async {
    await _player.dispose();
  }
}

/// ------------------------------------------------------------
/// main() 启动入口
/// ------------------------------------------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized(); // 初始化 media_kit

  // 初始化 audio_service，创建后台播放 handler
  final handler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.app.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );

  runApp(MyApp(audioHandler: handler));
}

/// ------------------------------------------------------------
/// Flutter UI 部分
/// ------------------------------------------------------------
class MyApp extends StatelessWidget {
  final AudioHandler audioHandler;
  const MyApp({required this.audioHandler, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'media_kit + audio_session + audio_service demo',
      home: HomePage(audioHandler: audioHandler),
    );
  }
}

class HomePage extends StatefulWidget {
  final AudioHandler audioHandler;
  const HomePage({required this.audioHandler, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool playing = false;

  @override
  void initState() {
    super.initState();

    // 监听播放状态变化，更新 UI（播放/暂停图标）
    widget.audioHandler.playbackState.listen((state) {
      setState(() {
        playing = state.playing;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio focus demo')),
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 播放 / 暂停按钮
            IconButton(
              iconSize: 48,
              icon: Icon(playing ? Icons.pause_circle : Icons.play_circle),
              onPressed: () {
                if (playing) {
                  widget.audioHandler.pause();
                } else {
                  widget.audioHandler.play();
                }
              },
            ),
            // 停止按钮
            IconButton(
              iconSize: 36,
              icon: const Icon(Icons.stop_circle_outlined),
              onPressed: () {
                widget.audioHandler.stop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
