// import 'package:flutter/material.dart';
// import 'dart:typed_data';
//
// /// 模拟音乐信息
// class MusicInfoReader {
//   final Uint8List coverBytes;
//   MusicInfoReader(this.coverBytes);
// }
//
// /// 单例控制器
// class PlayerController extends ValueNotifier<MusicInfoReader?> {
//   static final PlayerController _instance = PlayerController._internal(null);
//   factory PlayerController() => _instance;
//   PlayerController._internal(super.value);
//
//   MusicInfoReader? get currentMusicInfo => value;
//   set currentMusicInfo(MusicInfoReader? info) {
//     value = info;
//   }
//
//   bool get isNull => value == null;
// }
//
// /// 全局 Overlay 悬浮球管理器
// class FloatingPlayerManager {
//   static final FloatingPlayerManager _instance = FloatingPlayerManager._internal();
//   factory FloatingPlayerManager() => _instance;
//   FloatingPlayerManager._internal();
//
//   OverlayEntry? _entry;
//
//   void show(BuildContext context) {
//     if (_entry != null) return; // 已经显示
//     _entry = OverlayEntry(builder: (context) => const FloatingPlayer());
//     Overlay.of(context).insert(_entry!);
//   }
//
//   void hide() {
//     _entry?.remove();
//     _entry = null;
//   }
//
//   void markNeedsBuild() {
//     _entry?.markNeedsBuild();
//   }
// }
//
// /// 全局悬浮球 Widget
// class FloatingPlayer extends StatefulWidget {
//   const FloatingPlayer({super.key});
//
//   @override
//   State<FloatingPlayer> createState() => _FloatingPlayerState();
// }
//
// class _FloatingPlayerState extends State<FloatingPlayer> {
//   final PlayerController playerController = PlayerController();
//
//   double _top = 200;
//   double _left = 10;
//   bool _expanded = false;
//
//   void _toggleExpanded(bool expand) {
//     setState(() {
//       _expanded = expand;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     final isRight = _left > screenSize.width / 2;
//
//     Widget content = _expanded ? _buildExpandedPlayer() : _buildFloatingButton();
//
//     return Positioned(
//       top: _top,
//       left: isRight && _expanded ? null : _left,
//       right: isRight && _expanded ? 10 : null,
//       child: Draggable(
//         feedback: content,
//         childWhenDragging: const SizedBox(),
//         onDragEnd: (details) {
//           double newLeft = details.offset.dx;
//           double newTop = details.offset.dy;
//
//           if (newLeft + 30 > screenSize.width / 2) {
//             newLeft = screenSize.width - 70;
//           } else {
//             newLeft = 10;
//           }
//           newTop = newTop.clamp(10.0, screenSize.height - 70);
//
//           setState(() {
//             _left = newLeft;
//             _top = newTop;
//           });
//         },
//         child: content,
//       ),
//     );
//   }
//
//   Widget _buildFloatingButton() {
//     return GestureDetector(
//       onTap: () => _toggleExpanded(true),
//       child: Material(
//         color: Colors.transparent,
//         child: Container(
//           width: 60,
//           height: 60,
//           decoration: const BoxDecoration(
//             color: Colors.blue,
//             shape: BoxShape.circle,
//             boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
//           ),
//           child: const Icon(Icons.menu, color: Colors.white),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildExpandedPlayer() {
//     return Material(
//       color: Colors.transparent,
//       child: Container(
//         margin: const EdgeInsets.all(5.0),
//         padding: const EdgeInsets.all(10.0),
//         decoration: BoxDecoration(
//           color: Colors.lightBlue[100],
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ValueListenableBuilder<MusicInfoReader?>(
//               valueListenable: playerController,
//               builder: (_, value, __) {
//                 return CircleAvatar(
//                   radius: 30,
//                   backgroundImage:
//                   value != null ? MemoryImage(value.coverBytes) : null,
//                   child: value == null ? const Icon(Icons.music_note) : null,
//                 );
//               },
//             ),
//             Row(
//               children: [
//                 IconButton(
//                     onPressed: () {}, icon: const Icon(Icons.skip_previous)),
//                 IconButton(onPressed: () {}, icon: const Icon(Icons.pause)),
//                 IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next)),
//                 IconButton(
//                     onPressed: () => _toggleExpanded(false),
//                     icon: const Icon(Icons.close)),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// /// 示例页面 1
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       FloatingPlayerManager().show(context);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: ElevatedButton(
//           child: const Text("跳转到第二页"),
//           onPressed: () => Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const SecondPage()),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// /// 示例页面 2
// class SecondPage extends StatelessWidget {
//   const SecondPage({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: ElevatedButton(
//           child: const Text("返回首页"),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//     );
//   }
// }
//
// void main() {
//   runApp(const MaterialApp(home: HomePage()));
// }
