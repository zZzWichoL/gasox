import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import '../models/sensor_reading.dart';
import '../main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ESP32Service {
  static const String defaultIP = '192.168.4.1';
  static const int port = 8080;
  static const Duration timeout = Duration(seconds: 5);
  
  DateTime? _lastAlarmSave;
  static const Duration minSaveInterval = Duration(minutes: 5);

  Future<String> _getESP32IP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('esp32_ip') ?? defaultIP;
  }

  Future<void> setESP32IP(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp32_ip', ip);
  }

  Future<Socket> _connectToESP32() async {
    final ip = await _getESP32IP();
    return await Socket.connect(ip, port).timeout(timeout);
  }

  Future<String> _sendCommand(String command) async {
    Socket? socket;
    try {
      socket = await _connectToESP32();
      socket.write('$command\n');
      
      final response = await socket.first.timeout(timeout);
      return String.fromCharCodes(response).trim();
    } finally {
      socket?.destroy();
    }
  }

  Future<Map<String, int>> getSensorValues() async {
    try {
      final response = await _sendCommand('GET_VALUES');
      final values = {'mq4': 0, 'mq7': 0};
      
      for (final line in response.split('\n')) {
        if (line.startsWith('MQ4:')) {
          values['mq4'] = int.tryParse(line.substring(4)) ?? 0;
        } else if (line.startsWith('MQ7:')) {
          values['mq7'] = int.tryParse(line.substring(4)) ?? 0;
        }
      }
      
      return values;
    } catch (e) {
      throw Exception('Error al obtener valores de sensores: $e');
    }
  }

  Future<bool> getAlarmState() async {
    try {
      final response = await _sendCommand('GET_ALARM_STATE');
      return response.contains('ALARMA_ACTIVA');
    } catch (e) {
      return false;
    }
  }

  Future<void> setMQ4Threshold(int threshold) async {
    try {
      await _sendCommand('SET_THRESHOLD_MQ4:$threshold');
    } catch (e) {
      throw Exception('Error al configurar umbral MQ4: $e');
    }
  }

  Future<void> setMQ7Threshold(int threshold) async {
    try {
      await _sendCommand('SET_THRESHOLD_MQ7:$threshold');
    } catch (e) {
      throw Exception('Error al configurar umbral MQ7: $e');
    }
  }

  Future<void> forgetWiFi() async {
    try {
      await _sendCommand('FORGET_WIFI');
    } catch (e) {
      throw Exception('Error al olvidar WiFi: $e');
    }
  }

  Future<void> checkAlarmBackground() async {
    try {
      final values = await getSensorValues();
      final isAlarm = await getAlarmState();
      
      if (isAlarm) {
        // Verificar si han pasado 5 minutos desde la última alarma guardada
        final now = DateTime.now();
        if (_lastAlarmSave == null || 
            now.difference(_lastAlarmSave!) >= minSaveInterval) {
          
          // Guardar la lectura de alarma
          final reading = SensorReading(
            timestamp: now,
            mq4Value: values['mq4'] ?? 0,
            mq7Value: values['mq7'] ?? 0,
            isHighReading: true,
          );
          
          await DatabaseService.instance.insertReading(reading);
          _lastAlarmSave = now;
          
          // Mostrar notificación
          await _showAlarmNotification(values['mq4'] ?? 0, values['mq7'] ?? 0);
        }
      }
    } catch (e) {
      // Error silencioso para background task
    }
  }

  Future<void> _showAlarmNotification(int mq4Value, int mq7Value) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'gasox_alarm',
      'Alarmas GASOX',
      channelDescription: 'Notificaciones de alarma del detector GASOX',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      '¡ALARMA GASOX!',
      'Niveles peligrosos detectados - MQ4: ${mq4Value}ppm, MQ7: ${mq7Value}ppm',
      notificationDetails,
    );
  }
}
