import 'package:flutter/material.dart';

import '../Logic/play_controller.dart';
import 'floating_player.dart' show FloatingPlayerState;

/// 左上角是标题
/// 直接是Row：Text + TextField
/// 最后一行三个按钮均分Row
/// 返回值：第一个是否定时（总控）、第二个值true表示确认定时、false表示销毁存在的定时器（如果有）、第三个值表示确认定时的时长
Future<(bool, bool, int)?> createTimerDialog(BuildContext context) async {
  return showDialog<(bool, bool, int)>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final textEditingController = TextEditingController();
      String? whenError = '';

      /// 当输入合法，才能确认
      bool canConfirm = false;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SimpleDialog(
            title: const Row(
              children: [
                Icon(Icons.lock_clock, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text('定时关闭'),
              ],
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text('时长（分钟）'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        textAlignVertical: TextAlignVertical.center,
                        controller: textEditingController,
                        onTap: () {
                          setState(() {
                            whenError = '';
                            canConfirm = false;
                          });
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '请输入 1~180 的整数',
                          errorText: whenError,
                        ),
                        onChanged: (value) {
                          setState(() {
                            final n = int.tryParse(value);
                            if (n == null || (n < 1 || n > 180)) {
                              whenError = '请输入1~180的整数';
                              canConfirm = false;
                            } else {
                              whenError = null;
                              canConfirm = true;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: canConfirm
                          ? () => Navigator.of(context).pop((
                              true,
                              true,
                              int.parse(textEditingController.text),
                            ))
                          : null,
                      child: const Text('确认'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop((true, false, 0)),
                      child: const Text('销毁'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop((false, false, 0)),
                      child: const Text('取消'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> createTimerDialogCompletely(
  BuildContext context,
  PlayerController playerController,
) async {
  final floatingState = playerController.bindMaps[1] as FloatingPlayerState;
  floatingState.justHide();

  final reply = await createTimerDialog(context);
  debugPrint("isTimerDlg == $reply");

  void showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  if (reply == null) {
    showSnackBar('定时操作失败');
    floatingState.justShow();
    return;
  }
  if (!context.mounted) {
    floatingState.justShow();
    return;
  }
  if (!reply.$1) {
    showSnackBar('取消定时操作');
    floatingState.justShow();
    return;
  }

  var (_, confirm, value) = reply;

  /// 先处理销毁情况
  if (!confirm) {
    playerController.cancelAutoStop();
    showSnackBar('销毁定时器');
  } else {
    playerController.setAutoStopMinute(value);
    showSnackBar('播放器将在$value分钟后自动关闭');
  }
  floatingState.justShow();
}
