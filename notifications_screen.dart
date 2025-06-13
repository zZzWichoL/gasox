import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _showNotifications = true;
  double _alarmVolume = 0.8;
  List<Map<String, dynamic>> _recentNotifications = [];

  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<Map<String, String>> _availableSounds = [
    {'name': 'Alarma 1', 'value': 'assets/sounds/alarm1.mp3'},
    {'name': 'Alarma 2', 'value': 'assets/sounds/alarm2.mp3'},
    {'name': 'Alarma 3', 'value': 'assets/sounds/alarm3.mp3'},
  ];

  String? _customAlarmPath; // Puede ser asset o archivo

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadRecentNotifications();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('notifications_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notifications_vibration') ?? true;
      _showNotifications = prefs.getBool('show_notifications') ?? true;
      _alarmVolume = prefs.getDouble('alarm_volume') ?? 0.8;
      _customAlarmPath = prefs.getString('custom_alarm_path');
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_sound', _soundEnabled);
    await prefs.setBool('notifications_vibration', _vibrationEnabled);
    await prefs.setBool('show_notifications', _showNotifications);
    await prefs.setDouble('alarm_volume', _alarmVolume);
    if (_customAlarmPath != null) {
      await prefs.setString('custom_alarm_path', _customAlarmPath!);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración guardada')),
    );
  }

  Future<void> _loadRecentNotifications() async {
    // Simulación de notificaciones recientes - en la app real vendrían de una base de datos
    setState(() {
      _recentNotifications = [
        {
          'title': 'Alerta de Gas',
          'message': 'Nivel de gas detectado: Alto',
          'time': DateTime.now().subtract(const Duration(minutes: 15)),
          'type': 'critical',
        },
        {
          'title': 'Sistema Conectado',
          'message': 'ESP32 conectado exitosamente',
          'time': DateTime.now().subtract(const Duration(hours: 2)),
          'type': 'info',
        },
        {
          'title': 'Batería Baja',
          'message': 'Nivel de batería del sensor: 15%',
          'time': DateTime.now().subtract(const Duration(hours: 5)),
          'type': 'warning',
        },
      ];
    });
  }

  Future<void> _pickCustomAlarm() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _customAlarmPath = result.files.single.path!;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_alarm_path', _customAlarmPath!);
    }
  }

  Future<void> _selectAssetAlarm(String assetPath) async {
    setState(() {
      _customAlarmPath = assetPath;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_alarm_path', assetPath);
  }

  Future<void> _testAlarmSound() async {
    try {
      await _audioPlayer.setVolume(_alarmVolume);
      if (_customAlarmPath != null && _customAlarmPath!.startsWith('assets/')) {
        await _audioPlayer
            .play(AssetSource(_customAlarmPath!.replaceFirst('assets/', '')));
      } else if (_customAlarmPath != null) {
        await _audioPlayer.play(DeviceFileSource(_customAlarmPath!));
      } else {
        await _audioPlayer.play(AssetSource('sounds/alarm1.mp3'));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reproduciendo sonido de prueba...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reproducir sonido: $e')),
      );
    }
  }

  void _clearNotifications() {
    setState(() {
      _recentNotifications.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificaciones eliminadas')),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'critical':
        return Icons.warning;
      case 'warning':
        return Icons.error_outline;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Configuración general
          Card(
            color: Colors.blue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Configuración General',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Mostrar notificaciones'),
                    subtitle: const Text('Habilitar todas las notificaciones'),
                    value: _showNotifications,
                    onChanged: (value) {
                      setState(() {
                        _showNotifications = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Sonido'),
                    subtitle: const Text('Reproducir sonido de alarma'),
                    value: _soundEnabled,
                    onChanged: _showNotifications
                        ? (value) {
                            setState(() {
                              _soundEnabled = value;
                            });
                          }
                        : null,
                  ),
                  SwitchListTile(
                    title: const Text('Vibración'),
                    subtitle: const Text('Vibrar al recibir notificaciones'),
                    value: _vibrationEnabled,
                    onChanged: _showNotifications
                        ? (value) {
                            setState(() {
                              _vibrationEnabled = value;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Configuración de sonido
          if (_showNotifications && _soundEnabled)
            Card(
              color: Colors.orange.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.volume_up, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Configuración de Audio',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sonido de alarma:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.music_note),
                          label: const Text('Archivo MP3'),
                          onPressed: _pickCustomAlarm,
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _availableSounds
                                  .any((s) => s['value'] == _customAlarmPath)
                              ? _customAlarmPath
                              : null,
                          hint: const Text('Predeterminada'),
                          items: _availableSounds
                              .map((sound) => DropdownMenuItem<String>(
                                    value: sound['value'],
                                    child: Text(sound['name']!),
                                  ))
                              .toList(),
                          onChanged: (value) async {
                            await _selectAssetAlarm(value!);
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _customAlarmPath != null
                                ? (_availableSounds.firstWhere(
                                        (s) => s['value'] == _customAlarmPath,
                                        orElse: () => {
                                              'name': _customAlarmPath!
                                                  .split('/')
                                                  .last
                                            })['name'] ??
                                    _customAlarmPath!.split('/').last)
                                : 'No hay archivo seleccionado',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Volumen: '),
                        Expanded(
                          child: Slider(
                            value: _alarmVolume,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            label: '${(_alarmVolume * 100).round()}%',
                            onChanged: (value) {
                              setState(() {
                                _alarmVolume = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Probar sonido'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _testAlarmSound,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Notificaciones recientes
          Card(
            color: Colors.green.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Notificaciones Recientes',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      if (_recentNotifications.isNotEmpty)
                        TextButton(
                          onPressed: _clearNotifications,
                          child: const Text('Limpiar'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_recentNotifications.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No hay notificaciones recientes',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _recentNotifications.map((notification) {
                        return Card(
                          color: Colors.white10,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              _getNotificationIcon(notification['type']),
                              color:
                                  _getNotificationColor(notification['type']),
                            ),
                            title: Text(
                              notification['title'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notification['message']),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(notification['time']),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Botón de prueba
          Card(
            color: Colors.purple.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active,
                          color: Colors.purple),
                      const SizedBox(width: 8),
                      Text(
                        'Prueba de Notificación',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Envía una notificación de prueba para verificar tu configuración',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar notificación de prueba'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notificación de prueba enviada'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
