import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(home: OverlayExample()));

class OverlayExample extends StatefulWidget {
  const OverlayExample({super.key});

  @override
  State<OverlayExample> createState() => _OverlayExampleState();
}

class _OverlayExampleState extends State<OverlayExample> {
  OverlayEntry? _overlayEntry;

  // 当前浮动按钮位置
  double _top = 200;
  double _left = 0;

  // 是否展开按钮
  bool _expanded = false;

  void _showOverlay(BuildContext context) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: _top,
          left: _left,
          child: Draggable(
            feedback: _expanded ? _buildExpandedButtons() : _floatingButton(),
            childWhenDragging: const SizedBox(),
            onDragEnd: (details) {
              final screenSize = MediaQuery.of(context).size;
              double newLeft = details.offset.dx;
              double newTop = details.offset.dy;

              // 自动吸附左右
              if (newLeft + 30 > screenSize.width / 2) {
                newLeft = screenSize.width - 70;
              } else {
                newLeft = 10;
              }
              // 保证不超出屏幕高度
              newTop = newTop.clamp(10.0, screenSize.height - 70);

              setState(() {
                _left = newLeft;
                _top = newTop;
              });
            },
            child: _expanded ? _buildExpandedButtons() : _floatingButton(),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// 悬浮球
  Widget _floatingButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expanded = true; // 点击展开
        });
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: const Icon(Icons.menu, color: Colors.white),
        ),
      ),
    );
  }

  /// 展开后的 4 个按钮
  Widget _buildExpandedButtons() {
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(Icons.music_note, Colors.red, () {
            debugPrint("点击音乐");
          }),
          const SizedBox(width: 8),
          _buildActionButton(Icons.video_collection, Colors.green, () {
            debugPrint("点击视频");
          }),
          const SizedBox(width: 8),
          _buildActionButton(Icons.photo, Colors.orange, () {
            debugPrint("点击照片");
          }),
          const SizedBox(width: 8),
          _buildActionButton(Icons.close, Colors.blue, () {
            setState(() {
              _expanded = false; // 点击收起
            });
          }),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overlay 浮动控件案例')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showOverlay(context),
          child: const Text('显示浮动控件'),
        ),
      ),
    );
  }
}
