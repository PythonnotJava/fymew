import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';

import 'play_controller.dart';

/// 全局音频 handler（用于从 UI 访问）
late AudioHandler audioHandler;

/// 定义一个占位的 MediaItem，用于 UI 和通知栏显示，使用默认音乐
MediaItem _defaultMediaItemFromController(PlayerController playerController) {
  final current = playerController.currentMusicInfo;
  return MediaItem(
    id: current.musicPath,
    title: current.title,
    artist: current.artist,
    duration: Duration(seconds: current.musicLength),

    /// coverBytes是Uint8List
    artUri: Uri.file(current.coverPath),
  );
}

/// 定义音频处理程序（添加 mediaItem 和所有播放控制逻辑）
class MyAudioHandler extends BaseAudioHandler {

  /// 全局播放控制器
  final PlayerController playerController;

  MyAudioHandler({required this.playerController}) {
    /// 设置初始媒体项
    mediaItem.add(_defaultMediaItemFromController(playerController));

    /// 设置初始播放状态（包括所有控制按钮，UI是三个，中间两个是暂停和播放切换）
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.pause,
          MediaControl.skipToNext,
        ],
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );

    /// 监听 PlayerController 的状态流，更新通知栏
    playerController.stateStream.listen((state) {
      playbackState.add(
        playbackState.value.copyWith(
          playing: state.playing,
          processingState: state.processingState,
          controls: state.playing
              ? [
            MediaControl.skipToPrevious,
            MediaControl.pause,
            MediaControl.skipToNext,
          ]
              : [
            MediaControl.skipToPrevious,
            MediaControl.play,
            MediaControl.skipToNext,
          ],
        ),
      );
    });

    /// 监听媒体项流，更新通知栏歌曲信息
    playerController.mediaItemStream.listen((newMediaItem) {
      mediaItem.add(newMediaItem);
    });
  }

  /// 实现播放逻辑，委托给控制器（如果是暂停则播放）
  @override
  Future<void> play() async {
    await playerController.playPause();
    debugPrint('AudioHandler: 开始播放');
  }

  /// 实现暂停逻辑，委托（如果是播放则暂停）
  @override
  Future<void> pause() async {
    await playerController.playPause();
    debugPrint('AudioHandler: 暂停播放');
  }

  /// 实现停止逻辑（系统级）
  @override
  Future<void> stop() async {
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
        controls: [],
      ),
    );
    debugPrint('AudioHandler: 停止服务');
    await super.stop();
  }

  /// 实现上一首（系统级）
  @override
  Future<void> skipToPrevious() async {
    await playerController.previous(previousIsClicked: true);
    debugPrint('AudioHandler: 跳到上一首');
  }

  /// 实现下一首（系统级）
  @override
  Future<void> skipToNext() async {
    await playerController.next(nextIsClicked: true);
    debugPrint('AudioHandler: 跳到下一首');
  }
}
