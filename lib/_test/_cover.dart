import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/material.dart';

class WidgetCover extends StatelessWidget {
  const WidgetCover({super.key});

  @override
  Widget build(BuildContext context) {
    var l = <Widget>[];
    final k = [
      "C:/Users/25654/Music/ENV - Microburst (8级别).flac",
      "C:/Users/25654/Music/JigglePuff - Poet's Heart.ogg",
      "C:/Users/25654/Music/K-391_RØRY - Aurora.ogg",
      "C:/Users/25654/Music/Radical Face - Welcome Home, Son.ogg",
      "C:/Users/25654/Music/Sofia Jannok - Liekkas.wav",
      "C:/Users/25654/Music/T-ara _ 筷子兄弟 - Little Apple.wav",
      "C:/Users/25654/Music/Vicetone _ WILLIM缪维霖 _ 黄霄雲 - 平行线 (Wish You Were Here) (V0).mp3",
      "C:/Users/25654/Music/李贞贤 - ワ-come on-.ogg",
      "C:/Users/25654/Music/赵雷 - 鼓楼.ogg",
      "C:/Users/25654/Music/黄勇_任书怀 - 你看到的我 (DJ版).ogg",
    ];
    for (final name in k) {
      final meta = readMetadata(File(name), getImage: true);
      debugPrint(meta.duration?.inSeconds.toString());
      debugPrint(meta.artist);
      if (meta.pictures.isNotEmpty) {
        l.add(Image.memory(meta.pictures[0].bytes));
      } else {
        l.add(Text('data'));
      }
    }

    return Scaffold(
      body: Center(
        child: Column(
          children:l,
        )
      ),
    );
  }
}

main() => runApp(MaterialApp(home: WidgetCover(),));