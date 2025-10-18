import 'package:flutter/material.dart';

import '../Logic/global_config.dart';
import '../Logic/music_info_reader.dart';

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          children: [
            TextButton(
              child: Text('create'),
              onPressed: () {
                final dir = pklDir.path;
                debugPrint('new == $dir');
              },
            ),
            TextButton(
              child: Text('check'),
              onPressed: () async {
                final dir = await createDirOnMobile('pkl');
                debugPrint('exsit ?? = ${dir.$2}');
              },
            ),
            TextButton(
              child: Text('what'),
              onPressed: () async {
                await MusicInfoReader.toPicklesAsyncDefaultDir();
              },
            ),
          ],
        )
      ),
    );
  }
}

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initGlobalSystem();
  runApp(MaterialApp(home: Main(),));
}