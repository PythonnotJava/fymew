import 'package:flutter/material.dart';
import 'package:flutter_swiper_plus/flutter_swiper_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../Logic/global_config.dart';
import '../Prefabrication/prefabrication.dart';

class HomeSiwper extends StatefulWidget {
  const HomeSiwper({super.key});

  @override
  State<StatefulWidget> createState() => HomeSiwperState();
}

class HomeSiwperState extends State<HomeSiwper> {
  @override
  void initState() {
    super.initState();
    _startWatchingData();
  }

  /// 若失败拉取API，则每3秒会重新拉取，直到成功
  void _startWatchingData() async {
    while (mounted && !swiperisLoaded) {
      debugPrint('⏳ 尝试拉取 swiperJsonData...');
      await initSwiperJsonIrrelevant();

      if (!swiperisLoaded) {
        debugPrint('❌ 加载失败，3秒后重试');
        await Future.delayed(const Duration(seconds: 3));
      } else {
        debugPrint('✅ 加载成功');
        if (mounted) setState(() {});
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return SizedBox(
      height: mq.size.height * 0.25,
      child: swiperisLoaded
          ? Swiper(
              itemBuilder: (context, index) {
                final Map<String, dynamic> json = swiperJsonData[index];
                return SwiperCard(json: json);
              },
              itemCount: swiperJsonData.length,
              autoplay: true,
              control: null,
              pagination: SwiperPagination(
                alignment: const Alignment(0.8, 0.95),
                builder: DotSwiperPaginationBuilder(
                  color: Colors.grey,
                  activeColor: Colors.blue,
                  size: 8,
                  activeSize: 12,
                ),
              ),
            )
          : const Center(child: SpinKitThreeInOut(color: Colors.blue)),
    );
  }
}
