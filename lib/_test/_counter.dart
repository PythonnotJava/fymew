import 'dart:io';

void main(List<String> args) async {
  // 默认从当前目录开始，也可以传入路径参数
  final directoryPath = args.isNotEmpty ? args.first : Directory.current.path;

  final total = await countDartLines(Directory(directoryPath));
  print('📊 Dart 文件总行数: ${total['lines']} 行');
  print('📄 Dart 文件数量: ${total['files']} 个');
}

Future<Map<String, int>> countDartLines(Directory dir) async {
  int totalLines = 0;
  int totalFiles = 0;

  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      totalFiles++;
      final lines = await entity.readAsLines();
      totalLines += lines.length;
    }
  }

  return {'lines': totalLines, 'files': totalFiles};
}
