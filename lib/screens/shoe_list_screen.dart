import 'package:flutter/material.dart';
import '../models/shoe.dart';
import '../services/storage_service.dart';
import 'add_shoe_screen.dart';
import 'shoe_detail_screen.dart';

class ShoeListScreen extends StatefulWidget {
  const ShoeListScreen({super.key});

  @override
  State<ShoeListScreen> createState() => _ShoeListScreenState();
}

class _ShoeListScreenState extends State<ShoeListScreen> {
  final StorageService _storageService = StorageService();
  List<Shoe> _shoes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShoes();
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
      ),
      body: _isLoading
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

  void _navigateToAddShoe() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddShoeScreen()),
    ).then((_) => _loadShoes());
  }
}