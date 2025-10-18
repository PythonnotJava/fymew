import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: Scaffold(body: MyApp())));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey _textKey = GlobalKey();
  final GlobalKey _buttonKey = GlobalKey();
  final GlobalKey _iconKey = GlobalKey();

  Timer? _pressTimer;
  GlobalKey? _activeKey; // 当前拖动控件

  // 控件初始位置
  final Map<GlobalKey, Offset> _positions = {};
  Offset _lastDragPos = Offset.zero;
  @override
  void initState() {
    super.initState();
    // 初始布局位置
    _positions[_textKey] = const Offset(50, 50);
    _positions[_buttonKey] = const Offset(50, 120);
    _positions[_iconKey] = const Offset(50, 200);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 长按开始
      onLongPressStart: (details) {
        _pressTimer?.cancel();
        _pressTimer = Timer(const Duration(seconds: 1), () {
          final pos = details.globalPosition;
          _lastDragPos = details.globalPosition;
          _checkHit(pos);
        });
      },
      onLongPressMoveUpdate: (details) {
        if (_activeKey == null) return;       // 先检查 activeKey
        if (_positions[_activeKey!] == null) return; // 再检查位置是否初始化

        final delta = details.globalPosition - _lastDragPos;
        setState(() {
          _positions[_activeKey!] = _positions[_activeKey!]! + delta;
          _lastDragPos = details.globalPosition;
        });
      },
      onLongPressEnd: (_) {
        _pressTimer?.cancel();
        _activeKey = null; // 结束拖动
      },
      child: Stack(
        children: [
          _buildDraggableWidget(_textKey, const Text('data')),
          _buildDraggableWidget(
              _buttonKey, TextButton(onPressed: () {}, child: const Text('data'))),
          _buildDraggableWidget(_iconKey, const Icon(Icons.person)),
        ],
      ),
    );
  }

  /// 根据 GlobalKey 构建控件，位置由 _positions 控制
  Widget _buildDraggableWidget(GlobalKey key, Widget child) {
    return Positioned(
      left: _positions[key]!.dx,
      top: _positions[key]!.dy,
      child: Container(
        key: key,
        child: child,
      ),
    );
  }

  /// 检查长按命中哪个控件
  void _checkHit(Offset globalPos) {
    for (var key in [_textKey, _buttonKey, _iconKey]) {
      final ctx = key.currentContext;
      if (ctx == null) continue;
      RenderBox box = ctx.findRenderObject() as RenderBox;
      Offset local = box.globalToLocal(globalPos);
      if (local.dx >= 0 &&
          local.dy >= 0 &&
          local.dx <= box.size.width &&
          local.dy <= box.size.height) {
        _activeKey = key;
        debugPrint('命中控件：${ctx.widget.runtimeType}');
        break;
      }
    }
  }
}
