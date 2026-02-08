import 'dart:convert';
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
    shoes.removeWhere((shoe) => shoe.id == shoeId);
    await saveShoes(shoes);
  }
}