import 'package:flutter/material.dart';

import 'play_list_searcher.dart' show MusicPlayerList;
import 'home_page.dart' show HomePage;
import 'user_drawer.dart' show UserDrawer;
import 'floating_player.dart' show FloatingPlayerManager;

class AppCore extends StatefulWidget {
  const AppCore({super.key});

  @override
  State<StatefulWidget> createState() => AppCoreState();
}

class AppCoreState extends State<AppCore> {
  int currentIndex = 0;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late final List<Widget> binds;

  @override
  void dispose() {
    debugPrint('销毁测试.');
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    binds = [
      HomePage(scaffoldKey: scaffoldKey, switchPage: switchPage),
      MusicPlayerList(scaffoldKey: scaffoldKey),
    ];

    /// 页面构建完成后再添加悬浮球到全局 Overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FloatingPlayerManager().show(context);
    });

    /// 监听抽屉状态变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void checkDrawerState() {
        if (scaffoldKey.currentState?.isDrawerOpen == true) {
          FloatingPlayerManager().hide();
        } else {
          FloatingPlayerManager().show(context);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => checkDrawerState());
      }

      checkDrawerState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: const UserDrawer(),
      body: SafeArea(
        child: Stack(
          children: [IndexedStack(index: currentIndex, children: binds)],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedIconTheme: const IconThemeData(size: 30),
        unselectedIconTheme: const IconThemeData(size: 22),
        onTap: switchPage,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "主页"),
          BottomNavigationBarItem(icon: Icon(Icons.music_video), label: "乐库"),
        ],
      ),
    );
  }

  /// 界面切换函数, index = 0 or 1 不做检查
  void switchPage(int index) {
    setState(() {
      if (currentIndex == index) {
        return;
      }
      currentIndex = index;
      debugPrint('切换到界面: $index');
    });
  }
}
