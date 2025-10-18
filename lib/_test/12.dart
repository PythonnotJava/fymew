import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Model Viewer')),
        body: const ModelViewer(
          rotationPerSecond: "30deg",
          autoPlay: true,
          backgroundColor: Color.fromARGB(0xFF, 0xEE, 0xEE, 0xEE),
          src: 'https://www.robot-shadow.cn/src/pkg/Fymew/img/logo.glb',
          alt: '3D model of logo',
          loading: Loading.lazy,
          poster:
              'https://www.robot-shadow.cn/src/pkg/Fymew/img/splash_1024.png',
          ar: false,
          arModes: ['scene-viewer', 'webxr', 'quick-look'],
          autoRotate: true,
          disableZoom: false,
        ),
      ),
    );
  }
}
