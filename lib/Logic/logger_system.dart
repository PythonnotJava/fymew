part of 'global_config.dart';

/// 调试日志，调出来可以查看报错信息
late final Directory debugLogDir;

/// 记录路径
late final String logFilePath;

/// 每次启动生成的调试日志文件，软件关闭的时候才会关闭，要先调用
late final IOSink logSink;
Future<void> initLogCfgFirst() async {
  if (isPlatformWithPC) {
    debugLogDir = Directory('assets/log/');
  } else {
    debugLogDir = Directory('${dirOfLongTimeStorage.path}/log');
  }
  if (!await debugLogDir.exists()) {
    await debugLogDir.create(recursive: true);
  }

  final t = (DateTime dt) {
    return "${dt.year}_${dt.month}_${dt.day}_${dt.hour}_${dt.minute}_${dt.second}";
  }(DateTime.now());
  logFilePath = "${debugLogDir.path}/$t.log";
  final file = File(logFilePath);
  logSink = file.openWrite(mode: FileMode.writeOnlyAppend, encoding: utf8);
  debugPrint('日志系统加载完毕！');
}

void writeLog(String message) {
  try {
    final log = "[${DateTime.now()}] $message";
    logSink.writeln(log);
  } catch (e) {
    if (e.toString().contains('Bad state') ||
        e.toString().contains('is closed')) {
      debugPrint('Log sink invalid, recreating...');
      _recreateLogSink();
      final log = "[${DateTime.now()}] $message";
      logSink.writeln(log);
    } else {
      debugPrint('Write log error: $e');
    }
  }
}

void _recreateLogSink() {
  try {
    debugPrint('logSink关闭重来');
    logSink.close();
  } catch (_) {}
  final file = File(logFilePath);
  logSink = file.openWrite(mode: FileMode.writeOnlyAppend, encoding: utf8);
  debugPrint('logSink _recreateLogSink触发.');
}

Future<void> closeLogFile() async {
  await logSink.flush();
  logSink.close();
}
