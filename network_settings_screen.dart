import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class NetworkSettingsScreen extends StatefulWidget {
  const NetworkSettingsScreen({super.key});

  @override
  State<NetworkSettingsScreen> createState() => _NetworkSettingsScreenState();
}

class _NetworkSettingsScreenState extends State<NetworkSettingsScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController =
      TextEditingController(text: '8080');

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    _ipController.text = prefs.getString('esp32_ip') ?? '';
    _portController.text = (prefs.getInt('esp32_port') ?? 8080).toString();
  }

  Future<void> _saveIpAndPort(String ip, String portStr) async {
    final prefs = await SharedPreferences.getInstance();
    final port = int.tryParse(portStr) ?? 8080;
    await prefs.setString('esp32_ip', ip);
    await prefs.setInt('esp32_port', port);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('IP y puerto guardados: $ip:$port')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración de Red')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.orange.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Conexión automática',
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
                    'La app intentará conectarse automáticamente a gasox.local en tu red.\n'
                    'Si tu red no soporta nombres .local, puedes guardar la IP manualmente.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Abrir portal de configuración'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                final url = Uri.parse('http://192.168.4.1');
                if (!await launchUrl(url,
                    mode: LaunchMode.externalApplication)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No se pudo abrir el navegador.')),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 32),
          Card(
            color: Colors.green.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        '¿No funciona gasox.local?',
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Si la app no logra conectar automáticamente, pega aquí la IP y puerto que te mostró el portal:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: 'IP del ESP32',
                      hintText: 'Ejemplo: 192.168.1.123',
                      filled: true,
                      fillColor: Colors.white10,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _portController,
                    decoration: InputDecoration(
                      labelText: 'Puerto',
                      hintText: '8080',
                      filled: true,
                      fillColor: Colors.white10,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save, color: Colors.orange),
                    label: const Text('Guardar IP y puerto'),
                    onPressed: () => _saveIpAndPort(
                        _ipController.text, _portController.text),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reiniciar WiFi del ESP32'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              try {
                final socket = await Socket.connect('192.168.4.1', 8080,
                    timeout: const Duration(seconds: 2));
                socket.write('FORGET_WIFI\n');
                await socket.flush();
                await socket.close();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Comando enviado. El ESP32 reiniciará su WiFi.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No se pudo enviar el comando: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
