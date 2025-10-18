part of 'panel.dart';

final class IconType {
  final IconData logo;
  final void Function() onTap;
  final String title;
  final Color color;

  const IconType({
    required this.title,
    required this.logo,
    required this.color,
    required this.onTap,
  });
}

Orientation currentOrientation(BuildContext context) {
  return MediaQuery.of(context).orientation;
}

class ExpandableContainer extends StatefulWidget {
  final void Function(int) switchPage;

  const ExpandableContainer({super.key, required this.switchPage});

  @override
  ExpandableContainerState createState() => ExpandableContainerState();
}

class ExpandableContainerState extends State<ExpandableContainer> {
  bool _pressed = false;
  bool _isButtonDisabled = false;
  Timer? _disableTimer;
  late final List<IconType> iconTypes;
  late final PlayerController playerController;

  void showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _disableButtonsTemporarily() {
    setState(() => _isButtonDisabled = true);
    _disableTimer?.cancel();
    _disableTimer = Timer(const Duration(seconds: 1), () {
      setState(() => _isButtonDisabled = false);
    });
  }

  @override
  void dispose() {
    _disableTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    playerController = Provider.of<PlayerController>(context, listen: false);
    iconTypes = [
      IconType(
        logo: Icons.cloud_download,
        title: '网络载入',
        color: Colors.tealAccent,
        onTap: () async {
          _disableButtonsTemporarily();
          await loadFromWebCompletely(
            context,
            playerController,
            showJumpToLib: true,
            switchPage: widget.switchPage,
            scrollToBottom:
                (playerController.bindMaps[0] as MusicPlayerListState)
                    .scrollToBottom,
          );
        },
      ),
      IconType(
        logo: Icons.lock_clock,
        title: '定时关闭',
        color: Colors.blueAccent,
        onTap: () async {
          _disableButtonsTemporarily();
          await createTimerDialogCompletely(context, playerController);
        },
      ),
      IconType(
        logo: Icons.bug_report,
        title: '调试日志',
        color: Colors.yellowAccent,
        onTap: () async {
          _disableButtonsTemporarily();
          await showDebugViewer(context, playerController);
        },
      ),
      IconType(
        logo: Icons.card_giftcard,
        title: '抽卡',
        color: Colors.orangeAccent,
        onTap: () async {
          _disableButtonsTemporarily();
          final orientation = MediaQuery.of(context).orientation;
          if (orientation == Orientation.landscape) {
            showSnackBar('不支持横屏模式');
            return;
          }
          var (isDefault, info) = playerController.randomInfo;
          await showPersonalizedCardDialog(
            context,
            playerController,
            info: info,
            isDefault: isDefault,
          );
        },
      ),
      IconType(
        title: '歌曲封装',
        logo: Icons.my_library_music_rounded,
        color: Colors.lightBlue,
        onTap: () async {
          _disableButtonsTemporarily();
          await showMusicWrapper(context, playerController, widget.switchPage);
        },
      ),
    ];
    super.initState();
  }

  Future<void> _toggleExpand() async {
    if (_isButtonDisabled) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => ExpandedContainerDialog(
        iconTypes: iconTypes,
        isButtonDisabled: false,
        disableButtons: _disableButtonsTemporarily,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Colors.blueAccent;

    final content = Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.15), Colors.white],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(2, 3),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size =
                  min(constraints.maxWidth, constraints.maxHeight) * 0.5;
              return Center(
                child: Icon(Icons.grid_view, size: size, color: color),
              );
            },
          ),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async => await _toggleExpand(),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AspectRatio(aspectRatio: 4 / 3, child: content),
        ),
      ),
    );
  }

  Widget _logoWidget(IconType iconType, {required bool inDialog}) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: inDialog ? Colors.white70 : null,
      child: Icon(iconType.logo, color: iconType.color),
    );
  }
}

class ExpandedContainerDialog extends StatelessWidget {
  final List<IconType> iconTypes;
  final bool isButtonDisabled;
  final void Function() disableButtons;

  const ExpandedContainerDialog({
    super.key,
    required this.iconTypes,
    required this.isButtonDisabled,
    required this.disableButtons,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.8;
    final dialogHeight = screenSize.height * 0.8;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              width: dialogWidth,
              height: dialogHeight,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(52),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withAlpha(77), width: 1),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '展开工具面板',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white54),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final availableWidth = constraints.maxWidth;
                          const spacing = 16.0;

                          /// 展开情况
                          return Wrap(
                            spacing: spacing,
                            runSpacing: 16,
                            children: [
                              for (int i = 0; i < iconTypes.length; i++)
                                SizedBox(
                                  width: (availableWidth - 2 * spacing) / 3,
                                  child: GestureDetector(
                                    onTap: isButtonDisabled
                                        ? null
                                        : () {
                                            Navigator.pop(context);
                                            final it = iconTypes[i];
                                            disableButtons();
                                            it.onTap();
                                          },
                                    behavior: HitTestBehavior.opaque,
                                    child: _logoWidget(
                                      iconTypes[i],
                                      inDialog: true,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logoWidget(IconType iconType, {required bool inDialog}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: inDialog ? Colors.white70 : null,
          child: Icon(iconType.logo, color: iconType.color),
        ),
        const SizedBox(height: 4),
        Text(
          iconType.title,
          style: inDialog
              ? const TextStyle(color: Colors.white)
              : const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
