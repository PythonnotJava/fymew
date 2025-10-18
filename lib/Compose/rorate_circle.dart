import 'dart:io';
import 'package:flutter/material.dart';

/// 可控旋转图片，放歌曲触发旋转
class RotatingCircleImage extends StatefulWidget {
  final String coverPath;

  /// 初始是否旋转
  final bool isRotating;

  /// 每转一圈时长
  final Duration duration;

  const RotatingCircleImage({
    super.key,
    required this.coverPath,
    this.isRotating = true,
    this.duration = const Duration(seconds: 10),
  });

  @override
  State<RotatingCircleImage> createState() => RotatingCircleImageState();
}

class RotatingCircleImageState extends State<RotatingCircleImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late bool _isRotating;

  @override
  void initState() {
    super.initState();
    _isRotating = widget.isRotating;

    _rotationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (_isRotating) {
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  /// 外部可调用的方法：开启旋转
  void startRotation() {
    if (!_isRotating) {
      _isRotating = true;
      _rotationController.repeat();
    }
  }

  /// 外部可调用的方法：停止旋转
  void stopRotation() {
    if (_isRotating) {
      _isRotating = false;
      _rotationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _rotationController,
      child: ClipOval(
        child: Image.file(
          File(widget.coverPath),
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        )
      ),
    );
  }
}
