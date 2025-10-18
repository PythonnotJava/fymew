import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';

import 'play_controller.dart';

late final MyAudioHandler audioHandler;

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

class MyAudioHandler extends BaseAudioHandler {
  final PlayerController playerController;

  late final Player audioPlayer;

  MyAudioHandler(this.playerController) {
    audioPlayer = playerController.audioPlayer;

    /// 插入初始化默认音乐
    addMediaItem(_defaultMediaItemFromController(playerController));

    /// 监听播放器的状态变化并更新给系统
    audioPlayer.stream.playing.listen((playing) {
      updatePlaybackState(audioPlayer.state);
    });
    audioPlayer.stream.position.listen((position) {
      updatePlaybackState(audioPlayer.state);
    });
  }

  @override
  Future<void> play() async {
    final session = await AudioSession.instance;
    final success = await session.setActive(true);
    if (success) {
      audioPlayer.play();
    }
  }

  @override
  Future<void> pause() async {
    audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [MediaControl.stop],
        processingState: AudioProcessingState.completed,
        playing: false,
      ),
    );
    await AudioSession.instance.then((s) => s.setActive(false));
    await audioPlayer.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    await audioPlayer.next();
  }

  @override
  Future<void> skipToPrevious() async {
    await audioPlayer.previous();
  }

  @override
  Future<void> seek(Duration position) async {
    await audioPlayer.seek(position);
  }

  void updatePlaybackState(PlayerState state) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (state.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _getProcessingState(state.position, state.duration),
        playing: state.playing,
        updatePosition: state.position,
        bufferedPosition: state.buffer,
        speed: state.rate,

        /// 允许系统显示可拖动进度条
        systemActions: {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
      ),
    );
  }

  AudioProcessingState _getProcessingState(
    Duration position,
    Duration duration,
  ) {
    if (duration == Duration.zero) {
      return AudioProcessingState.loading;
    }
    return position >= duration
        ? AudioProcessingState.completed
        : AudioProcessingState.ready;
  }

  /// 每个歌曲的元信息
  void addMediaItem(MediaItem item) {
    mediaItem.add(item);
  }
}
