import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/shoe_models_data.dart';

class ShoeModelService {
  static const String _cacheKey = 'shoe_models_cache';
  static const String _cacheTimestampKey = 'shoe_models_cache_timestamp';
  static const Duration _cacheMaxAge = Duration(days: 7);

  // TODO: ホスティング後に実際のURLに置き換える
  static const String _remoteUrl = '';

  /// ブランドに対応するシューズモデル一覧を返す（ハードコード + キャッシュをマージ）
  Future<List<String>> getModelsForBrand(String brand) async {
    final Set<String> models = {};

    final hardcoded = defaultShoeModels[brand];
    if (hardcoded != null) {
      models.addAll(hardcoded);
    }

    final cachedData = await _loadCachedData();
    if (cachedData != null && cachedData.containsKey(brand)) {
      models.addAll(cachedData[brand]!);
    }

    final result = models.toList()..sort();
    return result;
  }

  /// リモートからシューズモデルデータを取得しキャッシュを更新する
  Future<bool> refreshFromRemote() async {
    if (_remoteUrl.isEmpty) return false;

    try {
      if (await _isCacheFresh()) return false;

      final response = await http
          .get(Uri.parse(_remoteUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        final Map<String, List<String>> parsed = {};
        for (final entry in jsonData.entries) {
          if (entry.value is List) {
            parsed[entry.key] = List<String>.from(entry.value);
          }
        }

        await _saveCachedData(parsed);
        return true;
      }
    } catch (e) {
      // ネットワークエラー等は無視（オフラインファースト）
    }
    return false;
  }

  Future<Map<String, List<String>>?> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString == null) return null;

      final Map<String, dynamic> raw = json.decode(jsonString);
      final Map<String, List<String>> result = {};
      for (final entry in raw.entries) {
        result[entry.key] = List<String>.from(entry.value);
      }
      return result;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveCachedData(Map<String, List<String>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(data));
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // キャッシュ保存失敗は無視
    }
  }

  Future<bool> _isCacheFresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);
      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now().difference(cacheTime) < _cacheMaxAge;
    } catch (e) {
      return false;
    }
  }
}
