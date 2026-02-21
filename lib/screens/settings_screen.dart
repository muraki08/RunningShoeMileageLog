import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifEnabled = false;
  int _hour = 21;
  int _minute = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await NotificationService.isEnabled();
    final hour = await NotificationService.getHour();
    final minute = await NotificationService.getMinute();
    setState(() {
      _notifEnabled = enabled;
      _hour = hour;
      _minute = minute;
      _isLoading = false;
    });
  }

  Future<void> _onToggleChanged(bool value) async {
    if (value) {
      await NotificationService.requestPermission();
    }
    setState(() => _notifEnabled = value);
    await NotificationService.saveSettings(
      enabled: value,
      hour: _hour,
      minute: _minute,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'リマインド通知をONにしました' : 'リマインド通知をOFFにしました'),
        ),
      );
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
      await NotificationService.saveSettings(
        enabled: _notifEnabled,
        hour: _hour,
        minute: _minute,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '通知時刻を ${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} に設定しました',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'リマインド通知',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('毎日のリマインド'),
                  subtitle: const Text('走行記録の入力を促す通知を送信します'),
                  value: _notifEnabled,
                  onChanged: _onToggleChanged,
                ),
                if (_notifEnabled)
                  ListTile(
                    title: const Text('通知時刻'),
                    subtitle: Text(
                      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: _selectTime,
                  ),
              ],
            ),
    );
  }
}
