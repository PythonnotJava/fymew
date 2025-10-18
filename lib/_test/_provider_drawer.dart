import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => DrawerState(), child: const MyApp()),
  );
}

/// 主应用
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Provider Drawer Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FirstPage(),
    );
  }
}

class DrawerState extends ChangeNotifier {
  String? userName;
  String? bgImagePath;
  String? userAvatarPath;

  void updateUserName(String value) {
    userName = value;
    notifyListeners();
  }

  void updateBgImagePath(String path) {
    bgImagePath = path;
    notifyListeners();
  }

  void updateUserAvatarPath(String path) {
    userAvatarPath = path;
    notifyListeners();
  }
}

class UserDrawer extends StatefulWidget {
  const UserDrawer({super.key});

  @override
  State<StatefulWidget> createState() => UserDrawerState();
}

/// 第一次初始化后会写入配置
class UserDrawerState extends State<UserDrawer> {
  /// 第一次初始化随机生成的名字
  static String _initUserName() {
    final adj = ['可爱的', '帅气的', '潇洒的', '疯狂的', '睿智的'];
    final obj = ['男孩', '美少女', '帽子'];
    final rd = Random();
    return adj[rd.nextInt(adj.length)] + obj[rd.nextInt(obj.length)];
  }

  @override
  void initState() {
    super.initState();
    final drawerState = context.read<DrawerState>();
    if (drawerState.userName == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        drawerState.updateUserName(_initUserName());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawerState = context.watch<DrawerState>();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 自定义 DrawerHeader
          DrawerHeader(
            decoration: drawerState.bgImagePath != null
                ? BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(drawerState.bgImagePath!),
                      fit: BoxFit.cover,
                    ),
                  )
                : BoxDecoration(color: Colors.lightBlue[100]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                drawerState.userAvatarPath == null
                    ? const CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage('assets/img/unicorn.png'),
                      )
                    : CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage(
                          drawerState.userAvatarPath!,
                        ),
                      ),
                const SizedBox(height: 10),
                TextField(
                  controller:
                      TextEditingController(text: drawerState.userName ?? '')
                        ..selection = TextSelection.fromPosition(
                          TextPosition(
                            offset: (drawerState.userName ?? '').length,
                          ),
                        ),
                  onChanged: (value) => drawerState.updateUserName(value),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: "输入用户名",
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.sunny),
            title: const Text("主题设置"),
            onTap: () => debugPrint("主题设置"),
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text("修改背景"),
            onTap: () => debugPrint("修改背景"),
          ),
        ],
      ),
    );
  }
}

/// 页面 1
class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text("第一页"),
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: const UserDrawer(),
      body: Center(
        child: ElevatedButton(
          child: const Text("跳转到第二页"),
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SecondPage()));
          },
        ),
      ),
    );
  }
}

/// 页面 2
class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text("第二页"),
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: const UserDrawer(),
      body: const Center(child: Text("这是第二页")),
    );
  }
}
