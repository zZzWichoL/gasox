import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/sensor_reading.dart';

class DatabaseScreen extends StatefulWidget {
  const DatabaseScreen({super.key});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  List<SensorReading> _readings = [];
  bool _isLoading = true;
  bool _showOnlyHighReadings = false;

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<SensorReading> readings;
      if (_showOnlyHighReadings) {
        readings = await DatabaseService.instance.getHighReadings();
      } else {
        readings = await DatabaseService.instance.getAllReadings();
      }
      
      setState(() {
        _readings = readings;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReading(int id) async {
    try {
      await DatabaseService.instance.deleteReading(id);
      await _loadReadings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lectura eliminada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAllReadings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar todas las lecturas? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseService.instance.deleteAllReadings();
        await _loadReadings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las lecturas han sido eliminadas'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getFormattedDate(DateTime timestamp) {
    return DateFormat('dd/MM/yyyy').format(timestamp);
  }

  String _getFormattedTime(DateTime timestamp) {
    return DateFormat('HH:mm:ss').format(timestamp);
  }

  Color _getReadingColor(SensorReading reading) {
    if (reading.isHighReading) {
      return Colors.red;
    }
    final maxValue = reading.mq4Value > reading.mq7Value 
        ? reading.mq4Value 
        : reading.mq7Value;
    
    if (maxValue > 2000) return Colors.orange;
    if (maxValue > 1000) return Colors.yellow.shade700;
    return Colors.green;
  }

  String _getReadingStatus(SensorReading reading) {
    if (reading.isHighReading) {
      return 'MEDICIÓN ALTA';
    }
    final maxValue = reading.mq4Value > reading.mq7Value 
        ? reading.mq4Value 
        : reading.mq7Value;
    
    if (maxValue > 2000) return 'PRECAUCIÓN';
    if (maxValue > 1000) return 'ELEVADO';
    return 'NORMAL';
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Base de Datos'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReadings,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'filter':
                  setState(() {
                    _showOnlyHighReadings = !_showOnlyHighReadings;
                  });
                  _loadReadings();
                  break;
                case 'delete_all':
                  _deleteAllReadings();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(
                      _showOnlyHighReadings ? Icons.filter_alt_off : Icons.filter_alt,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(_showOnlyHighReadings ? 'Mostrar todas' : 'Solo alarmas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Eliminar todo', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Estadísticas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade700, Colors.indigo.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.storage,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Estadísticas de Lecturas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'Total',
                      '${_readings.length}',
                      Icons.analytics,
                    ),
                    _buildStatCard(
                      'Alarmas',
                      '${_readings.where((r) => r.isHighReading).length}',
                      Icons.warning,
                    ),
                    _buildStatCard(
                      'Normales',
                      '${_readings.where((r) => !r.isHighReading).length}',
                      Icons.check_circle,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Filtro actual
          if (_showOnlyHighReadings)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_alt, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Mostrando solo mediciones altas',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Lista de lecturas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _readings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showOnlyHighReadings 
                                  ? Icons.notifications_off 
                                  : Icons.folder_open,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _showOnlyHighReadings
                                  ? 'No hay mediciones altas registradas'
                                  : 'No hay lecturas guardadas',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _showOnlyHighReadings
                                  ? 'Las mediciones aparecerán aquí cuando se superen los umbrales'
                                  : 'Las lecturas aparecerán aquí cuando las guardes desde la pantalla principal',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _readings.length,
                        itemBuilder: (context, index) {
                          final reading = _readings[index];
                          final color = _getReadingColor(reading);
                          final status = _getReadingStatus(reading);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: reading.isHighReading 
                                      ? Colors.red 
                                      : color.withOpacity(0.5),
                                  width: reading.isHighReading ? 2 : 1,
                                ),
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
                                            color: reading.isHighReading 
                                                ? Colors.red 
                                                : color,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            status,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteReading(reading.id!),
                                          tooltip: 'Eliminar lectura',
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
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
                                                  size: 24,
                                                ),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  'MQ4 (Metano)',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${reading.mq4Value} ppm',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(width: 12),
                                        
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(
                                                  Icons.cloud,
                                                  color: Colors.grey,
                                                  size: 24,
                                                ),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  'MQ7 (CO)',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${reading.mq7Value} ppm',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Fecha: ${_getFormattedDate(reading.timestamp)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                'Hora: ${_getFormattedTime(reading.timestamp)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
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
