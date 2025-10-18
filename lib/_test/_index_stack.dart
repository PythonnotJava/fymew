import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// 整个 App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MainPage(),
    );
  }
}

/// 主页面，使用 IndexedStack 管理多个子页面
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    PageOne(),
    PageTwo(),
    PageThree(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // IndexedStack 保留每个页面的状态
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          // 悬浮球（Overlay-like 效果）
          const Positioned(
            right: 20,
            bottom: 80,
            child: FloatingBall(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "首页"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "搜索"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "我的"),
        ],
      ),
    );
  }
}

/// 页面1
class PageOne extends StatelessWidget {
  const PageOne({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("页面 1", style: TextStyle(fontSize: 30)));
  }
}

/// 页面2
class PageTwo extends StatelessWidget {
  const PageTwo({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("页面 2", style: TextStyle(fontSize: 30)));
  }
}

/// 页面3
class PageThree extends StatelessWidget {
  const PageThree({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("页面 3", style: TextStyle(fontSize: 30)));
  }
}

/// 悬浮球 Widget
class FloatingBall extends StatefulWidget {
  const FloatingBall({super.key});
  @override
  State<FloatingBall> createState() => _FloatingBallState();
}

class _FloatingBallState extends State<FloatingBall> {
  Offset offset = const Offset(0, 0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          offset += details.delta;
        });
      },
      child: Transform.translate(
        offset: offset,
        child: FloatingActionButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("悬浮球被点击")),
            );
          },
          child: const Icon(Icons.play_arrow),
        ),
      ),
    );
  }
}
