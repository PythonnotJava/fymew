import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import '../Logic/global_config.dart';
import '../Logic/play_controller.dart';
import 'floating_player.dart' show FloatingPlayerState;

class DebugViewer extends StatefulWidget {
  const DebugViewer({super.key});

  @override
  State<DebugViewer> createState() => DebugViewerState();
}

class DebugViewerState extends State<DebugViewer> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<String?> loadLog() async {
    final file = File(logFilePath);
    if (await file.exists()) {
      return await file.readAsString(encoding: utf8);
    } else {
      return null;
    }
  }

  Widget builderSomeUI(Widget w) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.bug_report, color: Colors.yellowAccent),
          Text('调试日志'),
        ],
      ),
      content: w,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: loadLog(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return builderSomeUI(const CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return builderSomeUI(Text('出错了: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final data = snapshot.data;
          if (data == null) {
            return builderSomeUI(const Text('没有数据'));
          } else {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.bug_report, color: Colors.yellowAccent),
                  const Text('调试日志'),
                  const Spacer(),

                  /// 滚动到顶部
                  IconButton(
                    icon: const Icon(
                      Icons.vertical_align_top,
                      color: Colors.lightBlue,
                    ),
                    onPressed: () {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                  ),

                  /// 滚动到底部
                  IconButton(
                    icon: const Icon(
                      Icons.vertical_align_bottom,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                  ),
                ],
              ),
              content: Container(
                margin: isPlatformWithPC ? const EdgeInsets.symmetric(
                  horizontal: 5.0,
                  vertical: 2.5,
                ) : const EdgeInsets.symmetric(
                  horizontal: 0.0,
                  vertical: 2.5,
                ),
                color: Colors.black,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: SelectableText(
                    data,
                    style: TextStyle(
                      fontSize: platformDefaultFontSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }
        } else {
          return const Text('没有数据');
        }
      },
    );
  }
}

Future<void> showDebugViewer(
  BuildContext context,
  PlayerController playerController,
) async {
  final floatingState = playerController.bindMaps[1] as FloatingPlayerState;
  floatingState.justHide();
  return await showDialog<void>(
    context: context,
    builder: (context) => const DebugViewer(),
  ).then((_) {
    floatingState.justShow();
  });
}
