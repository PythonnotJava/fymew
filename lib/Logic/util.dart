part of 'global_config.dart';

/// 封面系统
const String defaultCover = 'assets/img/music.png';
late final Uint8List defaultCoverBytes;

/// 初始化封面字节（PC用File，移动端用rootBundle）
Future<void> initDefaultCoverBytes() async {
  defaultCoverBytes = (await rootBundle.load(
    defaultCover,
  )).buffer.asUint8List();
}

/// 获取封面
Uint8List getCoverBytes(AudioMetadata mt) {
  if (mt.pictures.isEmpty) {
    debugPrint('无嵌入封面，使用默认替换封面');
    return defaultCoverBytes;
  }
  for (final p in mt.pictures) {
    if (p.pictureType == PictureType.coverFront) {
      return p.bytes;
    }
  }
  return mt.pictures[0].bytes;
}

/// 判断是png还是jpg
String judgeMimeType(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return 'png';
  }

  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'jpg';
  }
  return 'png';
}

/// 获取封面bytes和mimetype
(Uint8List, String) getCoverBytesAndMimeType(AudioMetadata mt) {
  final bytes = getCoverBytes(mt);
  final mm = judgeMimeType(bytes) == "jpg" ? 'image/jpeg' : 'image/png';
  return (bytes, mm);
}

String encodeSongName(String songName) =>
    base64UrlEncode(utf8.encode(songName));
String decodeSongName(String encodedStr) =>
    utf8.decode(base64Url.decode(encodedStr));

/// 获取时间格式
String getFormatTime() {
  final now = DateTime.now();
  return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
}

String parseYMD(DateTime date) {
  return "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";
}


/// 返回在线时长，格式：HHH:MM:SS
String formatDurationHMS(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// 反解析我规定的时间格式为DateTime
DateTime parseCustomDateTime(String formatted) {
  final dateTimeParts = formatted.split(' ');
  final dateParts = dateTimeParts[0].split('-');
  final timeParts = dateTimeParts[1].split(':');

  return DateTime(
    int.parse(dateParts[0]), // year
    int.parse(dateParts[1]), // month
    int.parse(dateParts[2]), // day
    int.parse(timeParts[0]), // hour
    int.parse(timeParts[1]), // minute
    int.parse(timeParts[2]), // second
  );
}

/// 获取注册时长
int registerDays() {
  final r = parseCustomDateTime(mgrUserData['register']);
  Duration diff = DateTime.now().difference(r);
  return diff.inDays;
}

/// 判断文本是否可能是乱码
/// 允许的字符：
/// 1. ASCII 可打印字符 (\x20-\x7E)
/// 2. 中文汉字 (\u4E00-\u9FFF)
/// 3. 日文假名 (\u3040-\u30FF)
/// 4. 韩文音节 (\uAC00-\uD7AF)
/// 5. 常见的中文符号和标点 (\u3000-\u303F, \uFF00-\uFFEF)
/// 6. Emoji (此处未显式包含，通常在 \u200D-\u3299 等范围，但上述正则已经涵盖了最常见的)
bool _isLikelyGarbled(String text) {
  if (text.isEmpty) return false;

  // 扩展后的允许字符范围
  final allowedRegex = RegExp(r'[^\x20-\x7E' // ASCII 可打印字符
  r'\u4E00-\u9FFF' // 中文汉字
  r'\u3040-\u30FF' // 日文平假名/片假名
  r'\uAC00-\uD7AF' // 韩文音节
  r'\u3000-\u303F' // 中日韩标点符号
  r'\uFF00-\uFFEF' // 全角ASCII、半角片假名等
  r']');

  // 匹配所有不属于“允许”范围的字符
  final garbledMatches = allowedRegex.allMatches(text);

  // 乱码字符占总长度的比例
  final ratio = garbledMatches.length / text.length;

  // 超过一定比例就认为可能是乱码
  return ratio > 0.4;
}

/// 对乱码重新编码为UTF-8（尝试中文、日文、韩文等常见编码）
/// 若修复失败，则返回原文
Future<String> fixGarbledToUtf8(String text) async {
  if (!_isLikelyGarbled(text)) return text;

  // 将字符串视为 UTF-8/默认编码的字节序列
  final bytes = Uint8List.fromList(text.codeUnits);

  // CJK (中日韩) 主要字符范围，用于判断修复是否成功
  final cjkSuccessRegex = RegExp(r'[\u4e00-\u9fff\u3040-\u30ff\uac00-\ud7af]');

  // 依次尝试常见的多语言编码方案
  final charsets = [
    // 中文
    'gbk',
    'gb18030',
    // 日文
    'Shift_JIS',
    'EUC-JP',
    // 韩文
    'EUC-KR',
    'windows-949', // 扩展的韩文编码
    // 通用
    'utf-16le',
    'utf-16be',
    // 其他，根据需要添加
    // 'windows-1258', // 越南语
    // 'windows-874',  // 泰语
  ];

  for (final charset in charsets) {
    try {
      // 尝试用当前编码解码
      final decoded = await CharsetConverter.decode(charset, bytes);

      // 如果结果里包含任何中日韩字符，说明修复成功
      if (cjkSuccessRegex.hasMatch(decoded)) {
        return decoded;
      }
    } catch (_) {
      // 解码失败则继续尝试下一个编码
    }
  }

  /// 全部失败则返回原字符串
  return text;
}

Iterable<(int, T)> enumerate<T>(Iterable<T> iterable, [int start = 0]) sync* {
  var index = start;
  for (final element in iterable) {
    yield (index++, element);
  }
}
