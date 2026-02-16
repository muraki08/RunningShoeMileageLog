import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/shoe.dart';
import 'storage_service.dart';

class DataMigrationService {
  final StorageService _storageService = StorageService();

  Future<void> exportData() async {
    final shoes = await _storageService.loadShoes();

    final List<Map<String, dynamic>> shoesJson = [];
    for (final shoe in shoes) {
      final shoeMap = shoe.toJson();

      String? imageBase64;
      if (shoe.imagePath != null) {
        final imageFile = File(shoe.imagePath!);
        if (await imageFile.exists()) {
          final bytes = await imageFile.readAsBytes();
          final ext = shoe.imagePath!.split('.').last.toLowerCase();
          imageBase64 = 'data:image/$ext;base64,${base64Encode(bytes)}';
        }
      }
      shoeMap['imageBase64'] = imageBase64;
      shoeMap.remove('imagePath');
      shoesJson.add(shoeMap);
    }

    final exportData = {
      'version': 1,
      'exportDate': DateTime.now().toIso8601String(),
      'shoes': shoesJson,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/shoe_data_$timestamp.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'ランニングシューズデータ',
    );
  }

  Future<int> importData({required bool replaceExisting}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return 0;
    }

    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();
    final data = json.decode(jsonString) as Map<String, dynamic>;

    if (data['version'] == null || data['shoes'] == null) {
      throw const FormatException('無効なデータ形式です');
    }

    final shoesList = data['shoes'] as List;
    final List<Shoe> importedShoes = [];

    for (final shoeData in shoesList) {
      final shoeMap = Map<String, dynamic>.from(shoeData);
      final imageBase64 = shoeMap['imageBase64'] as String?;
      shoeMap.remove('imageBase64');

      String? imagePath;
      if (imageBase64 != null && imageBase64.contains('base64,')) {
        final base64Data = imageBase64.split('base64,').last;
        final bytes = base64Decode(base64Data);
        final ext = imageBase64.contains('image/png') ? 'png' : 'jpg';

        final appDir = await getApplicationDocumentsDirectory();
        final imageDir = Directory('${appDir.path}/shoe_images');
        if (!await imageDir.exists()) {
          await imageDir.create(recursive: true);
        }
        final imageFile = File('${imageDir.path}/${shoeMap['id']}.$ext');
        await imageFile.writeAsBytes(bytes);
        imagePath = imageFile.path;
      }

      shoeMap['imagePath'] = imagePath;
      importedShoes.add(Shoe.fromJson(shoeMap));
    }

    if (replaceExisting) {
      await _storageService.saveShoes(importedShoes);
    } else {
      final existingShoes = await _storageService.loadShoes();
      final existingIds = existingShoes.map((s) => s.id).toSet();
      for (final shoe in importedShoes) {
        if (!existingIds.contains(shoe.id)) {
          existingShoes.add(shoe);
        }
      }
      await _storageService.saveShoes(existingShoes);
    }

    return importedShoes.length;
  }
}
