part of 'global_config.dart';

/// 资源系统。只读
/// 卡片系统，软件启动的时候不加载，在调用卡片生成才一次加载完毕，设置加载完成标记
/// 这里只写处理逻辑
const cardLinkApi = 'https://www.robot-shadow.cn/src/pkg/Fymew/cards.json';

/// 加载已完毕
bool cardApiAskCompletely = false;

/// 加载资料记录
late Map<String, dynamic> cardAssetsJson;

/// sayings大全
late List<dynamic> cardSayings;

/// 背景图片大全
late List<dynamic> cardPictures;

/// 组合大全（可为空）
late List? cardPairs;

/// 加载逻辑
Future<void> readCardAssets() async {
  try {
    final response = await globalDio.get(cardLinkApi);

    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) {
        cardAssetsJson = response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        cardAssetsJson = jsonDecode(response.data) as Map<String, dynamic>;
      } else {
        debugPrint('读取 cardAssets 解析出意外格式');
        cardAssetsJson = {
          "saying": ["竹杖芒鞋轻胜马，谁怕？一蓑烟雨任平生。"],
          "pictures": [
            "https://www.robot-shadow.cn/src/pkg/Fymew/img/sea_moon.jpg",
          ],
        };
      }

      cardSayings = cardAssetsJson['sayings'];
      cardPictures = cardAssetsJson['pictures'];
      cardPairs = cardAssetsJson['pairs'];
      debugPrint('初始化卡片系统!!!');
      cardApiAskCompletely = true;
    } else {
      debugPrint('cardAssetsJson请求失败！！！');
      cardApiAskCompletely = false;
    }
  } catch (e) {
    debugPrint('读取 cardAssets 出错: $e');
    cardApiAskCompletely = false;
  }
}
