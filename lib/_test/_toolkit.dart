import 'package:flutter/material.dart';

import '../Logic/music_info_reader.dart';
import '../Logic/global_config.dart';

class _Toolkit extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async {
            await MusicInfoReader.toPicklesAsyncDefaultDir();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('转换完成！')),
            );
          },
          child: Text('转换为pkl'),
        ),
      ),
    );
  }
}

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initGlobalSystem();
  runApp(MaterialApp(
    home: _Toolkit(),
  ));
}

/// flutter run lib\Compose\_toolkit.dart -d windows