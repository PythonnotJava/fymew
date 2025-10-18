import 'package:flutter/material.dart';


class PopupMenuDemo extends StatelessWidget {
  const PopupMenuDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PopupMenuButton 示例"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert), // 三个点的图标
            onSelected: (String value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("你选择了: $value")),
              );
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('编辑'),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('删除'),
              ),
              const PopupMenuItem<String>(
                value: 'share',
                child: Text('分享'),
              ),
            ],
          ),
        ],
      ),
      body: const Center(child: Text("点击右上角三个点试试")),
    );
  }
}

main() => runApp(MaterialApp(home: PopupMenuDemo(),));