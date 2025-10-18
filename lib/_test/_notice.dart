import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';

// 全局音频 handler（用于从 UI 访问）
late AudioHandler audioHandler;

// 定义一个占位的 MediaItem，用于 UI 和通知栏显示
final _defaultMediaItem = MediaItem(
  id: 'https://example.com/audio/track1',
  album: '宁静音乐精选',
  title: '宁静的湖畔',
  artist: 'AI 创作大师',
  duration: const Duration(minutes: 3, seconds: 30),
  // 占位图 URL，在实际应用中需要替换为有效的网络或本地资源
  artUri: Uri.parse('https://placehold.co/200x200/535C91/FFFFFF/png?text=音乐封面'),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 确保在初始化之前设置日志级别为警告或更高级别
  // AudioService.init(...)
  audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.pythonnotjava.fymew',
      androidNotificationChannelName: 'Fymew Service',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fymew 音频播放器',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.deepPurple,
      ),
      home: const AudioPlayerScreen(),
    );
  }
}

// 包含自定义播放器 UI 的屏幕
class AudioPlayerScreen extends StatelessWidget {
  const AudioPlayerScreen({super.key});

  // 模拟带有 Logo, App 名称和扬声器选项的顶部栏
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      // Logo 图标
      leading: const Padding(
        padding: EdgeInsets.only(left: 10.0),
        child: Icon(Icons.queue_music, color: Colors.deepPurple, size: 28),
      ),
      // 软件名字
      title: const Text('Fymew 播放器', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
      actions: const [
        // 扬声器选项
        IconButton(
          icon: Icon(Icons.speaker, color: Colors.deepPurple),
          onPressed: null, // 占位
        ),
        SizedBox(width: 8),
      ],
    );
  }

  // 构建封面图片 Widget
  Widget _buildCoverImage(Uri? artUri) {
    return Container(
      width: 150, // 保持固定宽度
      height: 150,
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: artUri != null
            ? Image.network(
          artUri.toString(),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
          const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.deepPurple)),
        )
            : const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.deepPurple)),
      ),
    );
  }

  // 构建播放控制按钮 Row
  Widget _buildControls() {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;
        final processingState = snapshot.data?.processingState ?? AudioProcessingState.idle;

        // 检查是否处于加载或缓冲状态
        final isBufferingOrLoading = processingState == AudioProcessingState.buffering ||
            processingState == AudioProcessingState.loading;

        // 根据状态确定播放/暂停图标和点击事件
        IconData playPauseIcon = isBufferingOrLoading
            ? Icons.sync // 正在加载中
            : (isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled);

        VoidCallback? onPlayPause = isBufferingOrLoading
            ? null // 正在加载时禁用点击
            : (isPlaying ? audioHandler.pause : audioHandler.play);

        return Center(child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 上一首
            IconButton(
              icon: const Icon(Icons.skip_previous),
              iconSize: 40.0, // 缩小尺寸以避免溢出
              color: Colors.deepPurple,
              onPressed: audioHandler.skipToPrevious,
            ),
            // 播放/暂停
            IconButton(
              icon: Icon(playPauseIcon),
              iconSize: 72.0, // 缩小尺寸以避免溢出
              color: Colors.deepPurple,
              onPressed: onPlayPause,
            ),
            // 下一首
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: 40.0, // 缩小尺寸以避免溢出
              color: Colors.deepPurple,
              onPressed: audioHandler.skipToNext,
            ),
          ],
        ),);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: _buildAppBar(),
      body: Center(child: Text('data'),)
    );
  }
}

// 定义音频处理程序（添加 mediaItem 和所有播放控制逻辑）
class MyAudioHandler extends BaseAudioHandler {
  MyAudioHandler() {
    // 1. 设置初始媒体项
    mediaItem.add(_defaultMediaItem);

    // 2. 设置初始播放状态（包括所有控制按钮）
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.pause,
        MediaControl.skipToNext
      ],
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
  }

  // 实现播放逻辑
  @override
  Future<void> play() async {
    // 模拟启动音频播放，将状态切换到 ready/playing，触发通知栏显示
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.pause, MediaControl.skipToPrevious, MediaControl.skipToNext],
      processingState: AudioProcessingState.ready,
      playing: true,
      // 模拟播放位置更新
      updatePosition: const Duration(seconds: 0),
    ));
    print('AudioHandler: 开始播放');
  }

  // 实现暂停逻辑
  @override
  Future<void> pause() async {
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      controls: [MediaControl.play, MediaControl.skipToPrevious, MediaControl.skipToNext],
    ));
    print('AudioHandler: 暂停播放');
  }

  // 实现停止逻辑
  @override
  Future<void> stop() async {
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
      controls: [],
    ));
    print('AudioHandler: 停止服务');
    await super.stop();
  }

  // 实现上一首
  @override
  Future<void> skipToPrevious() async {
    // 模拟加载上一首歌曲
    _simulateLoad();
    mediaItem.add(mediaItem.value!.copyWith(title: '上一首: 梦境漫游', artist: '灵感捕捉者'));
    await Future.delayed(const Duration(milliseconds: 500));
    _simulateReady();

    print('AudioHandler: 跳到上一首');
  }

  // 实现下一首
  @override
  Future<void> skipToNext() async {
    // 模拟加载下一首歌曲
    _simulateLoad();
    mediaItem.add(mediaItem.value!.copyWith(title: '下一首: 星空下的冥想', artist: '宇宙漫步者'));
    await Future.delayed(const Duration(milliseconds: 500));
    _simulateReady();

    print('AudioHandler: 跳到下一首');
  }

  // 辅助方法：模拟加载中状态
  void _simulateLoad() {
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.loading,
      playing: false,
      controls: [MediaControl.skipToPrevious, MediaControl.skipToNext],
    ));
  }

  // 辅助方法：模拟加载完成并播放状态
  void _simulateReady() {
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.ready,
      playing: true,
      updatePosition: Duration.zero,
      controls: [MediaControl.pause, MediaControl.skipToPrevious, MediaControl.skipToNext],
    ));
  }
}
