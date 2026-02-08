import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/shoe.dart';
import '../services/storage_service.dart';

class AddMileageScreen extends StatefulWidget {
  final Shoe shoe;
  final MileageEntry? editEntry;

  const AddMileageScreen({super.key, required this.shoe, this.editEntry});

  bool get isEditing => editEntry != null;

  @override
  State<AddMileageScreen> createState() => _AddMileageScreenState();
}

class _AddMileageScreenState extends State<AddMileageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController();
  final _notesController = TextEditingController();
  final StorageService _storageService = StorageService();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editEntry != null) {
      _distanceController.text = widget.editEntry!.distance.toString();
      _notesController.text = widget.editEntry!.notes ?? '';
      _selectedDate = widget.editEntry!.date;
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? '走行記録編集' : '走行記録追加'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_run, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.shoe.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '現在の走行距離: ${widget.shoe.totalMileage.toStringAsFixed(1)} km',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () => _selectDate(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Text(
                        '実施日: ${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _distanceController,
                decoration: const InputDecoration(
                  labelText: '走行距離 (km)',
                  border: OutlineInputBorder(),
                  suffixText: 'km',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '走行距離を入力してください';
                  }
                  final distance = double.tryParse(value.trim());
                  if (distance == null || distance <= 0) {
                    return '正しい走行距離を入力してください';
                  }
                  if (distance > 100) {
                    return '100km以下の値を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'メモ（任意）',
                  border: OutlineInputBorder(),
                  hintText: 'コース、体調、感想など',
                ),
                maxLines: 3,
                maxLength: 200,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMileage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.isEditing ? '更新する' : '記録する',
                          style: const TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.shoe.purchaseDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveMileage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final distance = double.parse(_distanceController.text.trim());
      final notes = _notesController.text.trim();

      List<MileageEntry> updatedHistory;

      if (widget.isEditing) {
        final editedEntry = MileageEntry(
          id: widget.editEntry!.id,
          date: _selectedDate,
          distance: distance,
          notes: notes.isNotEmpty ? notes : null,
        );
        updatedHistory = widget.shoe.mileageHistory.map((entry) {
          return entry.id == widget.editEntry!.id ? editedEntry : entry;
        }).toList();
      } else {
        final newEntry = MileageEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: _selectedDate,
          distance: distance,
          notes: notes.isNotEmpty ? notes : null,
        );
        updatedHistory = [...widget.shoe.mileageHistory, newEntry];
      }

      final totalMileage = updatedHistory.fold<double>(
        0.0,
        (sum, entry) => sum + entry.distance,
      );

      final updatedShoe = widget.shoe.copyWith(
        totalMileage: totalMileage,
        mileageHistory: updatedHistory,
      );

      await _storageService.updateShoe(updatedShoe);

      if (mounted) {
        Navigator.pop(context, updatedShoe);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? '走行記録を更新しました' : '走行記録を追加しました'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('記録の保存に失敗しました: $e')),
        );
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('走行記録を削除'),
          content: Text(
            '${widget.editEntry!.date.year}/${widget.editEntry!.date.month}/${widget.editEntry!.date.day} の記録（${widget.editEntry!.distance.toStringAsFixed(1)} km）を削除しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEntry();
              },
              child: const Text('削除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEntry() async {
    setState(() => _isLoading = true);
    try {
      final updatedHistory = widget.shoe.mileageHistory
          .where((e) => e.id != widget.editEntry!.id)
          .toList();
      final totalMileage = updatedHistory.fold<double>(
        0.0,
        (sum, e) => sum + e.distance,
      );
      final updatedShoe = widget.shoe.copyWith(
        totalMileage: totalMileage,
        mileageHistory: updatedHistory,
      );
      await _storageService.updateShoe(updatedShoe);
      if (mounted) {
        Navigator.pop(context, updatedShoe);
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
}