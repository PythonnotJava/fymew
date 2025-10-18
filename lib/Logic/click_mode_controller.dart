import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'global_config.dart' show singleClick, saveMgrSrcData;

/// 全局点击模式控制器
class ClickModeController extends ChangeNotifier {
  bool isSingleClicked = singleClick;

  /// 切换模式
  Future<void> toggleMode() async {
    isSingleClicked = !isSingleClicked;
    await saveMgrSrcData(key: 'singleClick', value: isSingleClicked);
    notifyListeners();
  }
}
