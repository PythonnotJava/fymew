part of 'global_config.dart';

const swiperJsonLink = "https://www.robot-shadow.cn/src/pkg/Fymew/pre.json";

late final List<dynamic> swiperJsonData;

bool swiperisLoaded = false;

Future<void> initSwiperJsonIrrelevant() async {
  try {
    final response = await globalDio.get(swiperJsonLink);

    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) {
        swiperJsonData = response.data['src'];
        swiperisLoaded = true;
      } else if (response.data is String) {
        swiperJsonData = (jsonDecode(response.data) as Map<String, dynamic>)['src'];
        swiperisLoaded = true;
      } else {
        debugPrint('swiperJsonData文件问题，服务api问题');
        swiperisLoaded = false;
      }
    } else {
      debugPrint('swiperJsonData请求失败！！！');
      swiperisLoaded = false;
    }
  } catch (e) {
    debugPrint('读取 swiperJsonData 出错: $e');
    swiperisLoaded = false;
  }
}
