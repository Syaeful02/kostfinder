import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Demo ini hanya menyimpan satu draft pada SATU perangkat.
class DraftRepository {
  static const _draftKey = 'kosfinder_device_demo_draft_v1';
  static const _photoKey = 'kosfinder_device_demo_photo_v1';
  
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<Map<String, dynamic>> load() async {
    final raw = await _prefs.getString(_draftKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }

  Future<void> save(Map<String, dynamic> draft) async {
    await _prefs.setString(_draftKey, jsonEncode(draft));
  }

  Future<String> savePermanentPhoto(XFile selected) async {
    final ext = selected.name.split('.').last.toLowerCase();
    if (!{'jpg', 'jpeg', 'png'}.contains(ext)) {
      throw const FormatException('Foto harus berupa JPG/JPEG/PNG.');
    }
    if (await selected.length() > 5 * 1024 * 1024) {
      throw const FormatException('Ukuran foto maksimal 5 MB.');
    }

    if (kIsWeb) {
      // JIKA DI WEB: Simpan sebagai Base64 String
      final bytes = await selected.readAsBytes();
      final base64String = base64Encode(bytes);
      await _prefs.setString(_photoKey, base64String);
      return 'web_base64_image'; // Penanda path khusus web
    } else {
      // JIKA DI MOBILE: Simpan ke folder permanen
      final root = await getApplicationDocumentsDirectory();
      final folder = Directory('${root.path}/kosfinder_photos');
      await folder.create(recursive: true);
      final output = File(
        '${folder.path}/${DateTime.now().microsecondsSinceEpoch}.$ext',
      );
      await selected.saveTo(output.path);
      return output.path;
    }
  }

  // Fungsi bantuan untuk mengambil gambar Base64 di Web
  Future<String?> getWebPhotoBase64() async {
    if (kIsWeb) {
      return await _prefs.getString(_photoKey);
    }
    return null;
  }
}