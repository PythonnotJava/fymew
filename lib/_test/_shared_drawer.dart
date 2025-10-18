import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// 全局共享 TextEditingController
final TextEditingController globalController = TextEditingController();

/// 全局 Drawer Widget
class UserDrawer extends StatelessWidget {
  const UserDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              "User Panel",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          ListTile(
            title: const Text("创建事件"),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            title: const Text("我的收藏"),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            title: TextField(
              controller: globalController, // 使用全局 controller
              decoration: const InputDecoration(hintText: "请输入内容"),
            ),
          ),
        ],
      ),
    );
  }
}

/// 主应用
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shared Drawer Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FirstPage(),
    );
  }
}

/// 页面 1
class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("第一页"),
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: const UserDrawer(),
      body: Center(
        child: ElevatedButton(
          child: const Text("跳转到第二页"),
          onPressed: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SecondPage()));
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
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("第二页"),
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: const UserDrawer(), // 同样使用全局 controller
      body: const Center(
        child: Text("这是第二页"),
      ),
    );
  }
}
