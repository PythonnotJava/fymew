import 'dart:math';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as ja;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _player = ja.AudioPlayer(
    handleInterruptions: false,
    androidApplyAudioAttributes: false,
    handleAudioSessionActivation: false,
  );

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    final audioSession = await AudioSession.instance;
    await audioSession.configure(AudioSessionConfiguration.speech());
    _handleInterruptions(audioSession);

    await _player.setAsset("assets/music/default.mp3");
  }

  void _handleInterruptions(AudioSession audioSession) {
    bool playInterrupted = false;

    // 耳机拔出等事件
    audioSession.becomingNoisyEventStream.listen((_) {
      _player.pause();
    });

    // 播放状态 -> 设置会话激活
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("音频互斥 Demo")),
        body: Center(
          child: StreamBuilder<ja.PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final state = snapshot.data;
              if (state?.processingState != ja.ProcessingState.ready) {
                return const CircularProgressIndicator();
              }
              if (state?.playing == true) {
                return IconButton(
                  icon: const Icon(Icons.pause),
                  iconSize: 64,
                  onPressed: _player.pause,
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.play_arrow),
                  iconSize: 64,
                  onPressed: _player.play,
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
