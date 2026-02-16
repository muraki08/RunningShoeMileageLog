import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shoe.dart';

class StorageService {
  static const String _key = 'shoes_data';

  Future<List<Shoe>> loadShoes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_key);
      if (jsonString != null) {
        final List<dynamic> jsonData = json.decode(jsonString);
        return jsonData.map((item) => Shoe.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading shoes: $e');
    }
    return [];
  }

  Future<void> saveShoes(List<Shoe> shoes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = shoes.map((shoe) => shoe.toJson()).toList();
      await prefs.setString(_key, json.encode(jsonData));
    } catch (e) {
      print('Error saving shoes: $e');
      rethrow;
    }
  }

  Future<void> addShoe(Shoe shoe) async {
    final shoes = await loadShoes();
    shoes.add(shoe);
    await saveShoes(shoes);
  }

  Future<void> updateShoe(Shoe updatedShoe) async {
    final shoes = await loadShoes();
    final index = shoes.indexWhere((shoe) => shoe.id == updatedShoe.id);
    if (index != -1) {
      shoes[index] = updatedShoe;
      await saveShoes(shoes);
    }
  }

  Future<void> deleteShoe(String shoeId) async {
    final shoes = await loadShoes();
    final shoe = shoes.firstWhere((s) => s.id == shoeId, orElse: () => shoes.first);
    if (shoe.imagePath != null) {
      await deleteShoeImage(shoe.imagePath!);
    }
    shoes.removeWhere((s) => s.id == shoeId);
    await saveShoes(shoes);
  }

  static Future<String> saveShoeImage(String shoeId, File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/shoe_images');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    final ext = imageFile.path.split('.').last;
    final savedFile = await imageFile.copy('${imageDir.path}/$shoeId.$ext');
    return savedFile.path;
  }

  static Future<void> deleteShoeImage(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}