import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/sensor_reading.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<SensorReading> _alarmReadings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarmReadings();
  }

  Future<void> _loadAlarmReadings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final readings = await DatabaseService.instance.getHighReadings();
      setState(() {
        _alarmReadings = readings;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar alarmas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getAlarmDescription(SensorReading reading) {
    List<String> triggers = [];
    
    if (reading.mq4Value > 3000) {
      triggers.add('Metano elevado (${reading.mq4Value} ppm)');
    }
    if (reading.mq7Value > 3000) {
      triggers.add('Monóxido de carbono elevado (${reading.mq7Value} ppm)');
    }
    
    return triggers.isNotEmpty 
        ? triggers.join(', ') 
        : 'Niveles de gas elevados';
  }

  Color _getAlarmSeverity(SensorReading reading) {
    final maxValue = reading.mq4Value > reading.mq7Value 
        ? reading.mq4Value 
        : reading.mq7Value;
    
    if (maxValue > 4000) return Colors.red.shade900;
    if (maxValue > 3500) return Colors.red.shade700;
    return Colors.red.shade500;
  }

  String _getTimeDifference(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'hace unos segundos';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones de Alarma'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlarmReadings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alarmReadings.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay alarmas registradas',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Las alarmas aparecerán aquí cuando se detecten\nniveles peligrosos de gas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Resumen de alarmas
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.red.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Resumen de Alarmas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total de alarmas',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                  Text(
                                    '${_alarmReadings.length}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              if (_alarmReadings.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Última alarma',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.red.shade600,
                                      ),
                                    ),
                                    Text(
                                      _getTimeDifference(_alarmReadings.first.timestamp),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Lista de alarmas
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _alarmReadings.length,
                        itemBuilder: (context, index) {
                          final reading = _alarmReadings[index];
                          final severity = _getAlarmSeverity(reading);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: severity, width: 2),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: severity,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'ALARMA',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _getTimeDifference(reading.timestamp),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    Text(
                                      _getAlarmDescription(reading),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.orange.shade200),
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(
                                                  Icons.gas_meter,
                                                  color: Colors.orange,
                                                  size: 20,
                                                ),
                                                const SizedBox(height: 4),
                                                const Text(
                                                  'MQ4',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '${reading.mq4Value} ppm',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(width: 12),
                                        
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(
                                                  Icons.cloud,
                                                  color: Colors.grey,
                                                  size: 20,
                                                ),
                                                const SizedBox(height: 4),
                                                const Text(
                                                  'MQ7',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '${reading.mq7Value} ppm',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Fecha y hora exacta
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat('dd/MM/yyyy - HH:mm:ss').format(reading.timestamp),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
