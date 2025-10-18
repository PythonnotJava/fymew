import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path_lib;
import 'package:provider/provider.dart';
import 'package:gif_view/gif_view.dart';
import 'package:permission_handler/permission_handler.dart';

import 'about_fymew.dart';
import '../Logic/global_config.dart';
import '../Logic/picker.dart';
import 'limit_text_input.dart';
import '../Logic/click_mode_controller.dart';

/// mgrUserData = {name, bg, avatar, register, mode}

/// 用户配置同步，不需要后台线程，每次修改图片会备份图片防止日后删除丢失
Future<void> writeUserData() async {
  mgrJsonFileData['user'] = mgrUserData;
  final data = JsonEncoder.withIndent('  ').convert(mgrJsonFileData);
  await mgrJsonFile.writeAsString(data);
}

/// 备份到mgr文件夹
Future<String> backupImg(String path) async {
  /// 获取文件的名字
  final String fileName = path_lib.basename(path);
  final String targetPath = path_lib.join(mgrDir.path, fileName);

  /// 复制文件
  await File(path).copy(targetPath);
  debugPrint('图片已保存到mgr文件夹: $targetPath');
  return targetPath;
}

/// 点击头像、背景可以修改
Future<void> getUserImagePath(
  DrawerState state,
  BuildContext context, {
  bool bg = false,
}) async {
  if (isPlatformWithMobile && !await FileFolderPicker.hasPermission) {
    bool granted = await FileFolderPicker.requestMobilePermission();
    if (!granted) {
      bool isPermanentlyDenied =
          await Permission.manageExternalStorage.isPermanentlyDenied;
      if (isPermanentlyDenied && context.mounted) {
        /// 永久拒绝，显示引导对话框
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("需要存储权限"),
            content: Text("请在系统设置中授予存储权限以选择图片。"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("取消"),
              ),
              TextButton(
                onPressed: () async {
                  await openAppSettings();
                  Navigator.pop(context);
                },
                child: Text("去设置"),
              ),
            ],
          ),
        );
      } else if (context.mounted) {
        /// 普通拒绝，显示简短提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("请授予存储权限以选择图片"),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
  }

  final String? path = await FileFolderPicker.pickFile(
    allowedExtensions: const ['png', 'jpg', 'jpeg', 'gif', 'webp'],
    label: 'Image File',
  );

  if (path != null) {
    final backupPath = await backupImg(path);
    bg
        ? state.updateBgImagePath(backupPath)
        : state.updateUserAvatarPath(backupPath);
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("取消选择图片"), duration: Duration(seconds: 2)),
    );
  }
}

/// 管理Drawer的统一部件并且写入配置
class DrawerState extends ChangeNotifier {
  /// name是软件初始化就有的
  String userName = mgrUserData['name'];
  String? bgImagePath = mgrUserData['bg'];
  String? userAvatarPath = mgrUserData['avatar'];
  int mode = mgrUserData['mode'];

  void updateUserName(String value) {
    userName = value;
    mgrUserData['name'] = value;
    notifyListeners();
    writeUserData();
  }

  void updateBgImagePath(String path) {
    bgImagePath = path;
    mgrUserData['bg'] = path;
    notifyListeners();
    writeUserData();
  }

  void updateUserAvatarPath(String path) {
    userAvatarPath = path;
    mgrUserData['avatar'] = path;
    notifyListeners();
    writeUserData();
  }

  void updateMode(int newMode) {
    mode = newMode;
    mgrUserData['mode'] = newMode;
    notifyListeners();
    writeUserData();
  }
}

class UserDrawer extends StatefulWidget {
  const UserDrawer({super.key});

  @override
  State<StatefulWidget> createState() => UserDrawerState();
}

class UserDrawerState extends State<UserDrawer> {
  late final TextEditingController textEditingController;

  late final ValueNotifier<bool> clearTileController;

  @override
  void initState() {
    final drawerState = context.read<DrawerState>();
    textEditingController = TextEditingController(text: drawerState.userName)
      ..addListener(() {
        drawerState.updateUserName(textEditingController.text);
      });
    clearTileController = ValueNotifier(mgrJsonFileData['clearCache']);
    super.initState();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    clearTileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawerState = context.watch<DrawerState>();

    debugPrint('载入背景图片：${drawerState.bgImagePath}');
    debugPrint('载入头像图片：${drawerState.userAvatarPath}');

    final drawerList = ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              drawerState.bgImagePath != null
                  ? _buildBackground(drawerState.bgImagePath!)
                  : Container(color: Colors.lightBlue[100]),

              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () async => await getUserImagePath(
                        drawerState,
                        context,
                        bg: false,
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: drawerState.userAvatarPath == null
                            ? const AssetImage('assets/img/unicorn.png')
                            : FileImage(File(drawerState.userAvatarPath!)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    UsernameFieldUtf8(
                      textEditingController: textEditingController,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.purpleAccent),
              title: const Row(children: [SizedBox(width: 15), Text("修改背景")]),
              onTap: () async =>
                  await getUserImagePath(drawerState, context, bg: true),
            ),

            /// 点击模式，单击卡片播放还是双击播放（防误触）
            Consumer<ClickModeController>(
              builder: (_, clickModeController, __) {
                return ListTile(
                  leading: const Icon(
                    Icons.touch_app_outlined,
                    color: Colors.teal,
                  ),
                  title: Row(
                    children: [
                      const SizedBox(width: 15),
                      clickModeController.isSingleClicked
                          ? const Text("卡片播放（单击）")
                          : const Text("卡片播放（双击）"),
                    ],
                  ),
                  onTap: () async => await clickModeController.toggleMode(),
                );
              },
            ),

            /// 阻断模式：有系统音频注册，Fymew播放被别的媒体阻断时，但其他音频又被中断时，Fymew仍处于暂停，需要手动打开（默认）
            /// 抢占模式：有系统音频注册，Fymew播放被别的媒体阻断时，但其他音频又被中断时，Fymew会立马恢复播放（无论是否被主动暂停）
            /// 并行模式：有系统音频注册，Fymew可以与其他媒体播放器同时播放
            /// 独占模式：下次启动的时候，取消系统音频注册，无论播放什么音频，Fymew都始终播放
            ExpansionTile(
              leading: const Icon(
                Icons.mode_of_travel,
                color: Colors.black26,
              ),
              title: const Row(children: [SizedBox(width: 15), Text("音频模式")]),
              children: [
                for (final (i, titles) in enumerate(const [
                  [
                    '阻断模式',
                    '（⚠ 重启生效）有系统音频注册，Fymew播放被别的媒体阻断时，但其他音频又被中断时，Fymew仍处于暂停，需要手动打开',
                  ],
                  [
                    '抢占模式',
                    '（⚠ 重启生效）有系统音频注册，Fymew播放被别的媒体阻断时，但其他音频又被中断时，Fymew会立马恢复播放（无论是否被主动暂停）',
                  ],
                  ['并行模式', '（⚠ 重启生效）有系统音频注册，Fymew可以与其他媒体播放器同时播放'],
                  ['独占模式', '（⚠ 重启生效）取消系统音频注册，无论播放什么音频，Fymew都始终播放'],
                ]))
                  ListTile(
                    leading: Icon(
                      drawerState.mode == i
                          ? Icons.circle
                          : Icons.circle_outlined,
                    ),
                    title: Text("\t\t${titles[0]}"),
                    trailing: Tooltip(
                      message: titles[1],
                      child: IconButton(
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => Opacity(
                              opacity: 0.8,
                              child: AlertDialog(
                                title: Text(titles[0]),
                                content: Text(titles[1]),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.info),
                      ),
                    ),
                    onTap: () async {
                      if (drawerState.mode != i) {
                        drawerState.updateMode(i);
                        debugPrint("现在drawerState mode = ${drawerState.mode}");
                      }
                    },
                  ),
              ],
            ),

            /// 清理网络在线缓存(temp_online文件夹所有)和网页控件的缓存
            clearTile(),

            /// 关于
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.orange),
              title: const Row(children: [SizedBox(width: 15), Text("关于")]),
              onTap: () async => await showDialog(
                context: context,
                builder: (context) => AboutFymewDialog(),
              ),
            ),
          ],
        ),
      ],
    );

    return Drawer(child: drawerList);
  }

  /// 背景图片
  Widget _buildBackground(String path) {
    final ext = path_lib.extension(path).toLowerCase();
    if (ext == '.gif') {
      /// 动态 GIF 背景
      return GifView.memory(
        File(path).readAsBytesSync(),
        fit: BoxFit.fill,
        autoPlay: true,
        loop: true,
        frameRate: gifFps,
      );
    } else {
      /// 静态图片背景
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File(path)),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      );
    }
  }

  ValueListenableBuilder<bool> clearTile() {
    return ValueListenableBuilder<bool>(
      valueListenable: clearTileController,
      builder: (context, isOpen, _) {
        return ListTile(
          leading: const Icon(
            Icons.cleaning_services_rounded,
            color: Colors.green,
          ),
          title: Row(
            children: [
              const SizedBox(width: 15),
              isOpen ? const Text('启动前清理缓存（开）') : const Text('启动前清理缓存（关）'),
            ],
          ),
          onTap: () async {
            clearTileController.value = !isOpen;
            if (isOpen) {
              debugPrint("取消了启动前清理缓存。");
              return await saveMgrSrcData(key: 'clearCache', value: false);
            } else {
              debugPrint("设置了启动前清理缓存。");
              return await saveMgrSrcData(key: 'clearCache', value: true);
            }
          },
        );
      },
    );
  }
}
