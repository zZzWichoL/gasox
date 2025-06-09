import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del Sistema'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con logo/título
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.security,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'GASOX',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Sistema de Detección de Gases',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // ¿Qué es GASOX?
            _buildSectionCard(
              title: '¿Qué es GASOX?',
              icon: Icons.info_outline,
              color: Colors.blue,
              child: const Text(
                'GASOX es un sistema inteligente de detección de gases peligrosos que utiliza tecnología ESP32 y sensores especializados para monitorear la calidad del aire en tiempo real. El sistema está diseñado para proteger tu hogar y familia mediante la detección temprana de gases tóxicos y combustibles.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Sensores del sistema
            _buildSectionCard(
              title: 'Sensores del Sistema',
              icon: Icons.sensors,
              color: Colors.orange,
              child: Column(
                children: [
                  _buildSensorInfo(
                    name: 'Sensor MQ4',
                    description: 'Detector de Metano (CH₄)',
                    details: 'Detecta gases combustibles como metano, gas natural y GLP. Ideal para cocinas y áreas con instalaciones de gas.',
                    icon: Icons.gas_meter,
                    color: Colors.orange,
                    ranges: 'Rango: 200-10,000 ppm',
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSensorInfo(
                    name: 'Sensor MQ7',
                    description: 'Detector de Monóxido de Carbono (CO)',
                    details: 'Detecta monóxido de carbono, un gas inodoro e incoloro extremadamente peligroso. Esencial para prevenir intoxicaciones.',
                    icon: Icons.cloud,
                    color: Colors.grey,
                    ranges: 'Rango: 20-2,000 ppm',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Cómo funciona el circuito
            _buildSectionCard(
              title: 'Cómo Funciona el Circuito',
              icon: Icons.memory,
              color: Colors.green,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepItem(
                    step: '1',
                    title: 'Detección',
                    description: 'Los sensores MQ4 y MQ7 detectan continuamente la concentración de gases en el ambiente.',
                  ),
                  _buildStepItem(
                    step: '2',
                    title: 'Procesamiento',
                    description: 'El ESP32 procesa las señales de los sensores y las convierte en valores PPM (partes por millón).',
                  ),
                  _buildStepItem(
                    step: '3',
                    title: 'Comparación',
                    description: 'Los valores se comparan con los umbrales establecidos por el usuario en la aplicación.',
                  ),
                  _buildStepItem(
                    step: '4',
                    title: 'Alerta',
                    description: 'Si se superan los límites, se activa la alarma sonora y se envía notificación a la app.',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Cómo funciona la app
            _buildSectionCard(
              title: 'Cómo Funciona la App',
              icon: Icons.smartphone,
              color: Colors.purple,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureItem(
                    icon: Icons.wifi_settings,
                    title: 'Configuración WiFi',
                    description: 'Conecta tu ESP32 a la red WiFi de tu hogar para comunicación en tiempo real.',
                  ),
                  _buildFeatureItem(
                    icon: Icons.tune,
                    title: 'Ajuste de Umbrales',
                    description: 'Personaliza los límites de detección para cada sensor según tus necesidades.',
                  ),
                  _buildFeatureItem(
                    icon: Icons.notifications_active,
                    title: 'Notificaciones',
                    description: 'Recibe alertas instantáneas cuando se detecten niveles peligrosos de gas.',
                  ),
                  _buildFeatureItem(
                    icon: Icons.storage,
                    title: 'Base de Datos',
                    description: 'Guarda y visualiza el historial completo de mediciones y alarmas.',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Niveles de peligro
            _buildSectionCard(
              title: 'Niveles de Peligro',
              icon: Icons.warning,
              color: Colors.red,
              child: Column(
                children: [
                  _buildDangerLevel(
                    level: 'SEGURO',
                    range: '< 1000 ppm',
                    color: Colors.green,
                    description: 'Niveles normales, sin riesgo.',
                  ),
                  _buildDangerLevel(
                    level: 'PRECAUCIÓN',
                    range: '1000 - 2500 ppm',
                    color: Colors.orange,
                    description: 'Niveles elevados, mantente alerta.',
                  ),
                  _buildDangerLevel(
                    level: 'PELIGRO',
                    range: '> 2500 ppm',
                    color: Colors.red,
                    description: 'Niveles críticos, evacúa inmediatamente.',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Consejos de seguridad
            _buildSectionCard(
              title: 'Consejos de Seguridad',
              icon: Icons.health_and_safety,
              color: Colors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSafetyTip('Mantén los sensores limpios y libres de polvo'),
                  _buildSafetyTip('Calibra los sensores regularmente'),
                  _buildSafetyTip('No ignores las alertas del sistema'),
                  _buildSafetyTip('Ventila inmediatamente si hay alarma'),
                  _buildSafetyTip('Revisa las instalaciones de gas periódicamente'),
                  _buildSafetyTip('Mantén detectores de humo adicionales'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSensorInfo({
    required String name,
    required String description,
    required String details,
    required IconData icon,
    required Color color,
    required String ranges,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: color.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            details,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ranges,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String step,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.purple, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerLevel({
    required String level,
    required String range,
    required Color color,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      level,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      range,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.teal,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
