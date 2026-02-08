import 'package:flutter/material.dart';
import '../models/shoe.dart';
import '../services/storage_service.dart';
import '../services/shoe_model_service.dart';

class AddShoeScreen extends StatefulWidget {
  const AddShoeScreen({super.key});

  @override
  State<AddShoeScreen> createState() => _AddShoeScreenState();
}

class _AddShoeScreenState extends State<AddShoeScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();
  final ShoeModelService _shoeModelService = ShoeModelService();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _selectedBrand;
  List<String> _shoeModelSuggestions = [];
  TextEditingController? _autocompleteController;

  static const List<String> _brands = [
    'Nike',
    'adidas',
    'ASICS',
    'New Balance',
    'HOKA',
    'Brooks',
    'Mizuno',
    'Saucony',
    'On',
    'Puma',
    'Under Armour',
    'Reebok',
  ];

  @override
  void initState() {
    super.initState();
    _shoeModelService.refreshFromRemote();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('シューズ登録'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedBrand,
                decoration: const InputDecoration(
                  labelText: 'ブランド',
                  border: OutlineInputBorder(),
                ),
                items: _brands.map((brand) {
                  return DropdownMenuItem(
                    value: brand,
                    child: Text(brand),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBrand = value;
                    _autocompleteController?.clear();
                  });
                  if (value != null) {
                    _loadShoeModels(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ブランドを選択してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (_shoeModelSuggestions.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  if (textEditingValue.text.isEmpty) {
                    return _shoeModelSuggestions;
                  }
                  return _shoeModelSuggestions.where((model) {
                    return model.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        );
                  });
                },
                onSelected: (String selection) {
                  _autocompleteController?.text = selection;
                },
                fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  _autocompleteController = textEditingController;
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'シューズ名',
                      border: const OutlineInputBorder(),
                      hintText: _selectedBrand != null
                          ? 'モデル名を入力（候補から選択も可）'
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'シューズ名を入力してください';
                      }
                      return null;
                    },
                  );
                },
                optionsViewBuilder: (
                  BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options,
                ) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final option = options.elementAt(index);
                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Text(option),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
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
                        '購入日: ${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveShoe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('登録', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadShoeModels(String brand) async {
    final models = await _shoeModelService.getModelsForBrand(brand);
    if (mounted) {
      setState(() {
        _shoeModelSuggestions = models;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveShoe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final shoe = Shoe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _autocompleteController!.text.trim(),
        brand: _selectedBrand!,
        purchaseDate: _selectedDate,
        totalMileage: 0.0,
        mileageHistory: [],
      );

      await _storageService.addShoe(shoe);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('シューズを登録しました')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登録に失敗しました: $e')),
        );
      }
    }
  }
}
