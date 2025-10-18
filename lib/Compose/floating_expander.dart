part of 'panel.dart';

class FloatingExpander extends StatefulWidget {
  const FloatingExpander({super.key});

  @override
  State<StatefulWidget> createState() => FloatingExpanderState();
}

class FloatingExpanderState extends State<FloatingExpander> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      /// 移除默认间隙
      insetPadding: const EdgeInsets.symmetric(horizontal: 5.0),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AspectRatio(
        aspectRatio: 1,

        /// 保证正方形
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 6.0;

            /// 控件之间的间隙
            final unit = (constraints.maxWidth - gap * 4) / 5;
            double leftOf(int col) => col * unit + col * gap;
            double topOf(int row) => row * unit + row * gap;
            double widthOf(int cols) => cols * unit + (cols - 1) * gap;
            double heightOf(int rows) => rows * unit + (rows - 1) * gap;

            return Stack(
              children: [
                Positioned(
                  left: leftOf(0),
                  top: topOf(0),
                  width: widthOf(2),
                  height: heightOf(3),
                  child: buildUserViewer(),
                ),
                Positioned(
                  left: leftOf(2),
                  top: topOf(0),
                  width: widthOf(3),
                  height: heightOf(3),
                  child: buildPlayerWidget(),
                ),
                Positioned(
                  left: leftOf(0),
                  top: topOf(3),
                  width: widthOf(2),
                  height: heightOf(2),
                  child: buildMemoryWidget(),
                ),
                Positioned(
                  left: leftOf(2),
                  top: topOf(3),
                  width: widthOf(3),
                  height: heightOf(2),
                  child: buildTimerWidget(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// w是核心控件
  Widget buildCommon(String title, Widget w) {
    return Container(
      decoration: BoxDecoration(
        color: Color.fromARGB(225, 240, 240, 240),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          /// 左上角放标题
          Positioned(
            left: 1,
            top: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.transparent,
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Center(child: w),
        ],
      ),
    );
  }

  /// 定时器面板，放在右下角
  Widget buildTimerWidget() {
    return buildCommon(
      '定时器',
      Consumer<PlayerController>(
        builder: (context, playerController, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: playerController.timerLeft == 0
                ? const [
                    Icon(Icons.timer_off_outlined, color: Colors.grey),
                    SizedBox(width: 10),
                    Text('您尚未设置定时器'),
                  ]
                : [
                    const SpinKitPouringHourGlass(color: Colors.lightBlue),
                    const SizedBox(width: 10),
                    Text('倒计时：${playerController.timerLeft}分钟'),
                  ],
          );
        },
      ),
    );
  }

  /// 程序本身的占用
  Widget buildMemoryWidget() {
    final currentMemory = ProcessInfo.currentRss ~/ (1024 * 1024);
    debugPrint('当前程序占用：${ProcessInfo.currentRss}');
    return buildCommon(
      '占用',
      LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0.0,
                  end: (currentMemory / ramTotal).clamp(0.0, 1.0),
                ),
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return CircularPercentIndicator(
                    radius: width / 3.5,
                    lineWidth: 10.0,
                    percent: value,
                    linearGradient: LinearGradient(
                      colors: [Colors.blue, Colors.lightBlue[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    backgroundColor: Colors.lightBlue[50]!,
                    circularStrokeCap: CircularStrokeCap.round,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '内存',
                          style: TextStyle(
                            fontSize: platformDefaultFontSize + 4,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(ramTotal * value).toInt()}MB',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// 注册时长
  Widget buildUserViewer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        return SizedBox(
          width: width,
          height: width,
          child: buildCommon(
            '歌龄',
            Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: SvgPicture.asset(
                    'assets/img/accompany.svg',
                    fit: BoxFit.fitWidth,
                    colorFilter: ColorFilter.mode(
                      Colors.pink[100]!,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '陪伴时长',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: platformDefaultFontSize + 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${registerDays()}天',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: platformDefaultFontSize + 8,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 播放信息，不要标题
  Widget buildPlayerWidget() {
    return buildCommon(
      '',
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 在线时长卡片
          Card(
            color: Colors.deepPurple[50],
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.deepPurple),
                  const SizedBox(width: 12),
                  const Text(
                    '时长',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Consumer<OnlineController>(
                    builder: (_, onlineController, _) {
                      return Text(
                        formatDurationHMS(onlineController.onlineDuration),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          /// 队列挂载卡片
          Card(
            color: Colors.lightBlue[50],
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.queue_music, color: Colors.lightBlue),
                  const SizedBox(width: 12),
                  const Text(
                    '队列挂载',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Consumer<PlayerController>(
                    builder: (context, playerController, _) {
                      return Icon(
                        playerController.isPlayingQueue
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: playerController.isPlayingQueue
                            ? Colors.lightBlue
                            : Colors.red,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 当前列表卡片
          Card(
            color: Colors.green[50],
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.library_music, color: Colors.green),
                  const SizedBox(width: 12),
                  const Text(
                    '当前列表',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Consumer<PlayerController>(
                    builder: (context, playerController, _) {
                      return Text(
                        playerController.isPlayingFavors ? '我的收藏' : '乐库',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showFloatingExpander(
  BuildContext context,
  PlayerController playerController,
) async {
  final floatingState = playerController.bindMaps[1] as FloatingPlayerState;
  floatingState.justHide();

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withAlpha(120),
    transitionDuration: const Duration(milliseconds: 800),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      /// 从底部滑入的 SlideTransition，弹簧“冒出来”效果，可换成 Curves.bounceOut
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.elasticOut)),
        child: child,
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return FloatingExpander();
    },
  );

  floatingState.justShow();
}
