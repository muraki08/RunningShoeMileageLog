import 'package:flutter/material.dart';
import '../models/shoe.dart';
import '../services/storage_service.dart';
import 'add_mileage_screen.dart';

class ShoeDetailScreen extends StatefulWidget {
  final Shoe shoe;

  const ShoeDetailScreen({super.key, required this.shoe});

  @override
  State<ShoeDetailScreen> createState() => _ShoeDetailScreenState();
}

class _ShoeDetailScreenState extends State<ShoeDetailScreen> {
  final StorageService _storageService = StorageService();
  late Shoe _shoe;
  bool _isLoading = false;
  final Set<String> _selectedEntryIds = {};

  @override
  void initState() {
    super.initState();
    _shoe = widget.shoe;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_shoe.name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'シューズ情報',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('ブランド', _shoe.brand),
                          _buildInfoRow(
                            '購入日',
                            '${_shoe.purchaseDate.year}/${_shoe.purchaseDate.month}/${_shoe.purchaseDate.day}',
                          ),
                          _buildInfoRow(
                            '総走行距離',
                            '${_shoe.totalMileage.toStringAsFixed(1)} km',
                            valueColor: _shoe.totalMileage > 500
                                ? Colors.red
                                : _shoe.totalMileage > 300
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                          _buildInfoRow(
                            '使用日数',
                            '${DateTime.now().difference(_shoe.purchaseDate).inDays} 日',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '走行履歴',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Row(
                        children: [
                          if (_selectedEntryIds.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ElevatedButton.icon(
                                onPressed: () => _showDeleteSelectedDialog(),
                                icon: const Icon(Icons.delete, size: 18),
                                label: Text('削除(${_selectedEntryIds.length})'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ElevatedButton.icon(
                            onPressed: () => _navigateToAddMileage(),
                            icon: const Icon(Icons.add),
                            label: const Text('記録追加'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _shoe.mileageHistory.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                '走行履歴がありません\n「記録追加」から追加してください',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: _shoe.mileageHistory
                              .reversed
                              .map((entry) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      onTap: () => _navigateToEditMileage(entry),
                                      leading: Checkbox(
                                        value: _selectedEntryIds.contains(entry.id),
                                        onChanged: (checked) {
                                          setState(() {
                                            if (checked == true) {
                                              _selectedEntryIds.add(entry.id);
                                            } else {
                                              _selectedEntryIds.remove(entry.id);
                                            }
                                          });
                                        },
                                      ),
                                      title: Text(
                                        '${entry.date.year}/${entry.date.month}/${entry.date.day}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: entry.notes?.isNotEmpty == true
                                          ? Text(entry.notes!)
                                          : null,
                                      trailing: Text(
                                        '${entry.distance.toStringAsFixed(1)} km',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddMileage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMileageScreen(shoe: _shoe),
      ),
    ).then((updatedShoe) {
      if (updatedShoe != null) {
        setState(() {
          _shoe = updatedShoe;
        });
      }
    });
  }

  void _navigateToEditMileage(MileageEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddMileageScreen(shoe: _shoe, editEntry: entry),
      ),
    ).then((updatedShoe) {
      if (updatedShoe != null) {
        setState(() {
          _shoe = updatedShoe;
        });
      }
    });
  }

  void _showDeleteSelectedDialog() {
    final count = _selectedEntryIds.length;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('走行記録を削除'),
          content: Text('選択した$count件の記録を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSelectedEntries();
              },
              child: const Text('削除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSelectedEntries() async {
    setState(() => _isLoading = true);
    try {
      final updatedHistory = _shoe.mileageHistory
          .where((e) => !_selectedEntryIds.contains(e.id))
          .toList();
      final totalMileage = updatedHistory.fold<double>(
        0.0,
        (sum, e) => sum + e.distance,
      );
      final updatedShoe = _shoe.copyWith(
        totalMileage: totalMileage,
        mileageHistory: updatedHistory,
      );
      await _storageService.updateShoe(updatedShoe);
      if (mounted) {
        setState(() {
          _shoe = updatedShoe;
          _selectedEntryIds.clear();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('走行記録を削除しました')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('シューズを削除'),
          content: Text('「${_shoe.name}」を削除しますか？\nこの操作は元に戻せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteShoe();
              },
              child: const Text('削除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteShoe() async {
    setState(() => _isLoading = true);
    try {
      await _storageService.deleteShoe(_shoe.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('シューズを削除しました')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }
}