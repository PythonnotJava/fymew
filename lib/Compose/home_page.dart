import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Logic/play_controller.dart';
import 'panel.dart';
import 'background_builder.dart';
import 'user_drawer.dart' show DrawerState;
import 'home_swiper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.scaffoldKey, required this.switchPage});

  final void Function(int) switchPage;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late final List<Widget> panels;

  @override
  void initState() {
    panels = [
      ExpandableContainer(switchPage: widget.switchPage),
      Panel(
        imgSvgPath: 'assets/img/favor.svg',
        opacity: .25,
        panelData: PanelData(
          panelType: PanelType.favor,
          title: '我的收藏',
          color: Colors.red,
        ),
      ),
      Panel(
        imgSvgPath: 'assets/img/queue.svg',
        opacity: .15,
        panelData: PanelData(
          panelType: PanelType.queue,
          title: '我的队列',
          color: Colors.orange,
        ),
        finalLinearColor: Colors.yellow.withAlpha(150),
      ),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Consumer<DrawerState>(
          builder: (_, state, __) {
            return Text("Hello, ${state.userName}");
          },
        ),
        leading: GestureDetector(
          onTap: () {
            widget.scaffoldKey?.currentState?.openDrawer();
          },
          child: Consumer<DrawerState>(
            builder: (_, drawerState, _) {
              final avatar = drawerState.userAvatarPath == null
                  ? const AssetImage('assets/img/unicorn.png')
                  : FileImage(File(drawerState.userAvatarPath!))
                        as ImageProvider;
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CircleAvatar(backgroundImage: avatar),
                ),
              );
            },
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            backgroundBuilder(),
            CustomScrollView(
              slivers: [
                if (MediaQuery.of(context).orientation == Orientation.portrait)
                  SliverToBoxAdapter(child: const HomeSiwper()),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => panels[index],
                      childCount: panels.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 10,
                          childAspectRatio: 4 / 3,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer<PlayerController>(
        builder: (context, p, _) {
          return FloatingActionButton(
            onPressed: () async => showFloatingExpander(context, p),
            child: const Icon(Icons.expand, color: Colors.blue),
          );
        },
      ),
    );
  }
}
