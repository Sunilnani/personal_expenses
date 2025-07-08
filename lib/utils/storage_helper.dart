// lib/utils/storage_helper.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<Directory> getStorageDirectory() async {
  try {
    final extDir = await getExternalStorageDirectory();
    final dir = Directory('${extDir!.path}/ExpenseTracker');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  } catch (_) {
    return await getApplicationDocumentsDirectory();
  }
}
