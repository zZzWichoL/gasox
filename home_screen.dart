import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/esp32_service.dart';
import '../services/database_service.dart';
import '../models/sensor_reading.dart';
import 'network_settings_screen.dart';
import 'notifications_screen.dart';
import 'info_screen.dart';
import 'database_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ESP32Service _esp32Service = ESP32Service();
  Timer? _timer;

  int mq4Value = 0;
  int mq7Value = 0;
  double mq4Threshold = 3000;
  double mq7Threshold = 3000;
  bool isAlarmActive = false;
  bool isConnected = false;

  bool _wasAlarmActive = false;

  late AnimationController _alarmAnimationController;
  late Animation<double> _alarmAnimation;

  late TextEditingController _mq4Controller;
  late TextEditingController _mq7Controller;

  DateTime? _lastAutoSave;

  @override
  void initState() {
    super.initState();
    _alarmAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _alarmAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _alarmAnimationController,
      curve: Curves.easeInOut,
    ));

    _mq4Controller =
        TextEditingController(text: mq4Threshold.toInt().toString());
    _mq7Controller =
        TextEditingController(text: mq7Threshold.toInt().toString());

    _loadSavedConnection().then((_) {
      _startPeriodicCheck();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _alarmAnimationController.dispose();
    _mq4Controller.dispose();
    _mq7Controller.dispose();
    super.dispose();
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkSensors();
    });
  }

  Future<void> _checkSensors() async {
    try {
      final values = await _esp32Service.getSensorValues();
      final alarmState = await _esp32Service.getAlarmState();

      // Si la alarma se activa y antes no estaba activa, reproduce sonido y muestra notificación
      if (alarmState && !_wasAlarmActive) {
        await _playAlarmSound();
        await _showAlarmNotification();
      }
      _wasAlarmActive = alarmState;

      setState(() {
        mq4Value = values['mq4'] ?? 0;
        mq7Value = values['mq7'] ?? 0;
        isAlarmActive = alarmState;
        isConnected = true;
      });

      // Guardado automático cada 10 minutos si la alarma está activa
      if (isAlarmActive) {
        if (_lastAutoSave == null ||
            DateTime.now().difference(_lastAutoSave!) >
                const Duration(minutes: 10)) {
          await _saveCurrentReading(auto: true);
          _lastAutoSave = DateTime.now();
        }
        _alarmAnimationController.repeat(reverse: true);
      } else {
        _alarmAnimationController.stop();
        _alarmAnimationController.reset();
      }
    } catch (e) {
      setState(() {
        isConnected = false;
      });
      _alarmAnimationController.stop();
      _alarmAnimationController.reset();
    }
  }

  Future<void> _updateThresholds() async {
    try {
      await _esp32Service.setMQ4Threshold(mq4Threshold.toInt());
      await _esp32Service.setMQ7Threshold(mq7Threshold.toInt());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Umbrales actualizados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar umbrales: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveCurrentReading({bool auto = false}) async {
    try {
      final reading = SensorReading(
        timestamp: DateTime.now(),
        mq4Value: mq4Value,
        mq7Value: mq7Value,
        isHighReading: isAlarmActive,
      );

      await DatabaseService.instance.insertReading(reading);

      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lectura guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar lectura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadSavedConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('esp32_ip');
    final port = prefs.getInt('esp32_port') ?? 8080;
    if (ip != null && ip.isNotEmpty) {
      await _esp32Service.connect(ip, port);
      setState(() {
        isConnected = true;
      });
    }
  }

  Future<void> _playAlarmSound() async {
    final prefs = await SharedPreferences.getInstance();
    final customAlarmPath = prefs.getString('custom_alarm_path');
    final soundEnabled = prefs.getBool('notifications_sound') ?? true;
    final vibrationEnabled = prefs.getBool('notifications_vibration') ?? true;
    final alarmVolume = prefs.getDouble('alarm_volume') ?? 0.8;
    final player = AudioPlayer();

    if (soundEnabled) {
      await player.setVolume(alarmVolume);
      if (customAlarmPath != null && customAlarmPath.startsWith('assets/')) {
        await player
            .play(AssetSource(customAlarmPath.replaceFirst('assets/', '')));
      } else if (customAlarmPath != null && customAlarmPath.isNotEmpty) {
        await player.play(DeviceFileSource(customAlarmPath));
      } else {
        await player.play(AssetSource('sounds/alarm1.mp3'));
      }
    }
    final hasVibrator = await Vibration.hasVibrator();
    if (vibrationEnabled && (hasVibrator ?? false)) {
      Vibration.vibrate(duration: 1000);
    }
  }

  Future<void> _showAlarmNotification() async {
    await flutterLocalNotificationsPlugin.show(
      0,
      '¡PELIGRO!',
      'Se detectaron niveles peligrosos de gas',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Alarmas',
          channelDescription: 'Notificaciones de alarma de gas',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: 'alarm',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GASOX - Detector de Humo'),
        actions: [
          IconButton(
            icon: Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: isConnected ? Colors.green : Colors.red,
            ),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFFD32F2F),
              ),
              child: Text(
                'GASOX',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.wifi),
              title: const Text('Configuración WiFi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NetworkSettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notificaciones'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Información'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InfoScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('Base de Datos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DatabaseScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Estado de conexión
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      isConnected ? Icons.check_circle : Icons.error,
                      color: isConnected ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      isConnected ? 'ESP32 Conectado' : 'ESP32 Desconectado',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Alarma
            if (isAlarmActive)
              AnimatedBuilder(
                animation: _alarmAnimation,
                builder: (context, child) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red
                          .withOpacity(0.1 + _alarmAnimation.value * 0.3),
                      border: Border.all(
                        color: Colors.red,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.red
                              .withOpacity(0.5 + 0.5 * _alarmAnimation.value),
                          size: 48 + 16 * _alarmAnimation.value,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '¡ALARMA ACTIVADA!',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Se han detectado niveles peligrosos de gas',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Opacity(
                            opacity: 0.5 + 0.5 * _alarmAnimation.value,
                            child: Icon(
                              Icons.change_history,
                              color: Colors.red,
                              size: 64 + 16 * _alarmAnimation.value,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 20),

            // Valores de sensores
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.gas_meter,
                            size: 48,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'MQ4 (Metano)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$mq4Value ppm',
                            style: TextStyle(
                              fontSize: 24,
                              color: mq4Value > mq4Threshold
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cloud,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'MQ7 (CO)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$mq7Value ppm',
                            style: TextStyle(
                              fontSize: 24,
                              color: mq7Value > mq7Threshold
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Configuración de umbrales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuración de Umbrales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // MQ4 Threshold
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Slider(
                            value: mq4Threshold,
                            min: 0,
                            max: 5000,
                            divisions: 100,
                            label: mq4Threshold.toInt().toString(),
                            onChanged: (value) {
                              setState(() {
                                mq4Threshold = value;
                                _mq4Controller.text =
                                    mq4Threshold.toInt().toString();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: _mq4Controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'ppm',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (value) {
                              final v = double.tryParse(value) ?? mq4Threshold;
                              setState(() {
                                mq4Threshold = v.clamp(0, 5000);
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // MQ7 Threshold
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Slider(
                            value: mq7Threshold,
                            min: 0,
                            max: 5000,
                            divisions: 100,
                            label: mq7Threshold.toInt().toString(),
                            onChanged: (value) {
                              setState(() {
                                mq7Threshold = value;
                                _mq7Controller.text =
                                    mq7Threshold.toInt().toString();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: _mq7Controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'ppm',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (value) {
                              final v = double.tryParse(value) ?? mq7Threshold;
                              setState(() {
                                mq7Threshold = v.clamp(0, 5000);
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isConnected ? _updateThresholds : null,
                        child: const Text('Actualizar Umbrales'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botón para guardar lectura
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveCurrentReading,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Lectura Actual'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
