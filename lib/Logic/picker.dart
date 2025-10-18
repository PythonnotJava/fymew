import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:permission_handler/permission_handler.dart';

import 'global_config.dart';

/// 返回绝对路径的文件、文件夹选择器
class FileFolderPicker {
  /// 移动端存储权限是否已经授权
  static Future<bool> requestMobilePermission() async {
    PermissionStatus status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
      if (status.isPermanentlyDenied) {
        debugPrint("权限被永久拒绝，用户需手动开启");
        return false; // 由调用方处理永久拒绝
      }
      if (!status.isGranted) {
        debugPrint("未授予访问存储的权限");
        return false;
      }
      debugPrint("刚刚授予访问存储的权限");
    }
    return true;
  }

  static Future<bool> get hasPermission async => await Permission.manageExternalStorage.isGranted;

  /// 选择单个文件
  /// [allowedExtensions] 限制文件后缀（可空）
  static Future<String?> pickFile({
    List<String> allowedExtensions = supportType,
    String label = 'Music File',
  }) async {
    if (!await hasPermission) {
      bool granted = await requestMobilePermission();
      if (!granted){
        debugPrint("未授予访问存储的权限!!!!!!!!!!!");
        return null;
      }
    }

    if (isPlatformWithPC) {
      /// 桌面平台使用 file_selector
      final XTypeGroup typeGroup = XTypeGroup(
        label: label,
        extensions: allowedExtensions,
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      return file?.path;
    } else {
      /// 移动端使用 file_picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );
      return result?.files.single.path;
    }
  }

  /// 选择文件夹
  static Future<String?> pickFolder() async {
    if (!await hasPermission) {
      bool granted = await requestMobilePermission();
      if (!granted) {
        debugPrint("未授予访问存储的权限!!!!!!!!!!!");
        return null;
      }
    }
    if (isPlatformWithPC) {
      return await getDirectoryPath();
    } else {
      /// 移动端使用 file_picker
      return await FilePicker.platform.getDirectoryPath();
    }
  }

  /// 选择多个文件
  static Future<List<String>> pickMultipleFiles({
    List<String> allowedExtensions = supportType,
    String label = 'Music File',
  }) async {
    if (!await hasPermission) {
      bool granted = await requestMobilePermission();
      if (!granted) {
        debugPrint("未授予访问存储的权限!!!!!!!!!!!");
        return [];
      }
    }
    if (isPlatformWithPC) {
      final XTypeGroup typeGroup = XTypeGroup(
        label: label,
        extensions: allowedExtensions,
      );
      final List<XFile> files = await openFiles(
        acceptedTypeGroups: [typeGroup],
      );
      return files.map((e) => e.path).whereType<String>().toList();
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );
      return result?.paths.whereType<String>().toList() ?? [];
    }
  }
}
