import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// 按 UTF-8 字节数限制输入
class Utf8LengthLimitingFormatter extends TextInputFormatter {
  final int maxBytes;

  Utf8LengthLimitingFormatter(this.maxBytes);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    /// 先算字节长度
    final bytes = utf8.encode(newValue.text);
    if (bytes.length > maxBytes) {
      /// 超出时截断
      String truncated = newValue.text;
      while (utf8.encode(truncated).length > maxBytes && truncated.isNotEmpty) {
        truncated = truncated.characters
            .take(truncated.characters.length - 1)
            .toString();
      }
      return TextEditingValue(
        text: truncated,
        selection: TextSelection.collapsed(offset: truncated.length),
      );
    }
    return newValue;
  }
}

class UsernameFieldUtf8 extends StatelessWidget {
  final TextEditingController textEditingController;

  const UsernameFieldUtf8({super.key, required this.textEditingController});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textEditingController,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: const InputDecoration(
        hintText: "输入用户名",
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        counterText: '',
      ),
      inputFormatters: [Utf8LengthLimitingFormatter(21)],
    );
  }
}
