import 'package:flutter/material.dart';
import 'dart:io';
import '../Logic/picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File/Folder Picker Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PickerTestPage(),
    );
  }
}

class PickerTestPage extends StatefulWidget {
  const PickerTestPage({super.key});

  @override
  State<PickerTestPage> createState() => _PickerTestPageState();
}

class _PickerTestPageState extends State<PickerTestPage> {
  String _selectedFile = '';
  String _selectedFolder = '';
  List<String> _selectedFiles = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("File/Folder Picker Test")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                String? path = await FileFolderPicker.pickFile();
                if (path != null) {
                  setState(() => _selectedFile = path);
                  debugPrint("Selected file: $path");
                }
              },
              child: const Text("选择单个文件"),
            ),
            Text(_selectedFile.isEmpty ? '未选择文件' : _selectedFile),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                List<String> paths = await FileFolderPicker.pickMultipleFiles();
                if (paths.isNotEmpty) {
                  setState(() => _selectedFiles = paths);
                  debugPrint("Selected files: $paths");
                }
              },
              child: const Text("选择多个文件"),
            ),
            Text(_selectedFiles.isEmpty ? '未选择文件' : _selectedFiles.join('\n')),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                String? path = await FileFolderPicker.pickFolder();
                if (path != null) {

                  setState(() => _selectedFolder = path);

                  debugPrint("Selected folder: $path");

                  final dir = Directory(path);

                  await for (final name in dir.list()) {
                    debugPrint("Get == ${name.path}");
                  }
                }
              },
              child: const Text("选择文件夹"),
            ),
            Text(_selectedFolder.isEmpty ? '未选择文件夹' : _selectedFolder),
          ],
        ),
      ),
    );
  }
}
