import 'package:flutter/material.dart';
import 'dart:async';
import '../services/esp32_service.dart';
import '../services/database_service.dart';
import '../models/sensor_reading.dart';
import 'network_settings_screen.dart';
import 'notifications_screen.dart';
import 'info_screen.dart';
import 'database_screen.dart';

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

  late AnimationController _alarmAnimationController;
  late Animation<double> _alarmAnimation;

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

    _startPeriodicCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _alarmAnimationController.dispose();
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

      setState(() {
        mq4Value = values['mq4'] ?? 0;
        mq7Value = values['mq7'] ?? 0;
        isAlarmActive = alarmState;
        isConnected = true;
      });

      if (isAlarmActive) {
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

  Future<void> _saveCurrentReading() async {
    try {
      final reading = SensorReading(
        timestamp: DateTime.now(),
        mq4Value: mq4Value,
        mq7Value: mq7Value,
        isHighReading: isAlarmActive,
      );

      await DatabaseService.instance.insertReading(reading);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lectura guardada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar lectura: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                    child: const Column(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.red,
                          size: 48,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '¡ALARMA ACTIVADA!',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Se han detectado niveles peligrosos de gas',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
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
                    Text('MQ4 (Metano): ${mq4Threshold.toInt()} ppm'),
                    Slider(
                      value: mq4Threshold,
                      min: 1000,
                      max: 5000,
                      divisions: 40,
                      label: mq4Threshold.toInt().toString(),
                      onChanged: (value) {
                        setState(() {
                          mq4Threshold = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // MQ7 Threshold
                    Text('MQ7 (CO): ${mq7Threshold.toInt()} ppm'),
                    Slider(
                      value: mq7Threshold,
                      min: 1000,
                      max: 5000,
                      divisions: 40,
                      label: mq7Threshold.toInt().toString(),
                      onChanged: (value) {
                        setState(() {
                          mq7Threshold = value;
                        });
                      },
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
