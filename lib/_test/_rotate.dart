void _handleInterruptions(AudioSession audioSession) {
  bool playInterrupted = false;

  /// 耳机拔出等事件
  audioSession.becomingNoisyEventStream.listen((_) {
    audioPlayer.pause();
  });

  /// 播放状态 -> 设置会话激活
  _player.playingStream.listen((playing) {
    if (playing) {
      playInterrupted = false;
      audioSession.setActive(true);
    }
  });

  // 系统抢占事件
  audioSession.interruptionEventStream.listen((event) {
    if (event.begin) {
      switch (event.type) {
        case AudioInterruptionType.duck:
          _player.setVolume(_player.volume / 2);
          break;
        case AudioInterruptionType.pause:
        case AudioInterruptionType.unknown:
          if (_player.playing) {
            _player.pause();
            playInterrupted = true;
          }
          break;
      }
    } else {
      switch (event.type) {
        case AudioInterruptionType.duck:
          _player.setVolume(min(1.0, _player.volume * 2));
          break;
        case AudioInterruptionType.pause:
          if (playInterrupted) _player.play();
          break;
        case AudioInterruptionType.unknown:
          break;
      }
    }
  });
}