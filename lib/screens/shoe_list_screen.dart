import 'dart:io';
import 'package:flutter/material.dart';
import '../models/shoe.dart';
import '../services/storage_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../services/data_migration_service.dart';
import 'add_shoe_screen.dart';
import 'settings_screen.dart';
import 'shoe_detail_screen.dart';

class ShoeListScreen extends StatefulWidget {
  const ShoeListScreen({super.key});

  @override
  State<ShoeListScreen> createState() => _ShoeListScreenState();
}

class _ShoeListScreenState extends State<ShoeListScreen> {
  final StorageService _storageService = StorageService();
  final DataMigrationService _migrationService = DataMigrationService();
  List<Shoe> _shoes = [];
  bool _isLoading = true;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadShoes();
    _bannerAd = AdService.createBannerAd(
      onLoaded: () => setState(() => _isBannerAdLoaded = true),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadShoes() async {
    setState(() => _isLoading = true);
    try {
      final shoes = await _storageService.loadShoes();
      setState(() {
        _shoes = shoes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('データの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ランニングシューズ記録'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                _exportData();
              } else if (value == 'import') {
                _showImportDialog();
              } else if (value == 'settings') {
                _navigateToSettings();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('データをエクスポート'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('データをインポート'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('設定'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _shoes.isEmpty
                    ? const Center(
                        child: Text(
                          'シューズを登録してください',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _shoes.length,
                        itemBuilder: (context, index) {
                          final shoe = _shoes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: shoe.imagePath != null && File(shoe.imagePath!).existsSync()
                                      ? Image.file(
                                          File(shoe.imagePath!),
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.directions_run, color: Colors.grey),
                                        ),
                                ),
                              ),
                              title: Text(
                                shoe.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ブランド: ${shoe.brand}'),
                                  const SizedBox(height: 4),
                                  Text(
                                    '走行距離: ${shoe.totalMileage.toStringAsFixed(1)} km',
                                    style: TextStyle(
                                      color: shoe.totalMileage > 500
                                          ? Colors.red
                                          : shoe.totalMileage > 300
                                              ? Colors.orange
                                              : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () => _navigateToShoeDetail(shoe),
                            ),
                          );
                        },
                      ),
          ),
          if (_isBannerAdLoaded && _bannerAd != null)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddShoe(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToShoeDetail(Shoe shoe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShoeDetailScreen(shoe: shoe),
      ),
    ).then((_) => _loadShoes());
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _navigateToAddShoe() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddShoeScreen()),
    ).then((_) => _loadShoes());
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    try {
      await _migrationService.exportData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エクスポートに失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データをインポート'),
        content: const Text('インポート方法を選択してください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _importData(replaceExisting: false);
            },
            child: const Text('既存データに追加'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _importData(replaceExisting: true);
            },
            child: const Text('既存データを上書き', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _importData({required bool replaceExisting}) async {
    setState(() => _isLoading = true);
    try {
      final count = await _migrationService.importData(replaceExisting: replaceExisting);
      if (count > 0) {
        await _loadShoes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count件のシューズをインポートしました')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('インポートに失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}