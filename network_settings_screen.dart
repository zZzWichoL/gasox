import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetworkSettingsScreen extends StatefulWidget {
  const NetworkSettingsScreen({super.key});

  @override
  State<NetworkSettingsScreen> createState() => _NetworkSettingsScreenState();
}

class _NetworkSettingsScreenState extends State<NetworkSettingsScreen> {
  bool _showPortal = false;
  final TextEditingController _ipController = TextEditingController();
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No se pudo cargar el portal. ¿Estás conectado a la red GASOX?',
                ),
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse('http://192.168.4.1'));
    _loadSavedIp();
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    _ipController.text = prefs.getString('esp32_ip') ?? '';
  }

  Future<void> _saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp32_ip', ip);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('IP guardada: $ip')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración de Red')),
      body: _showPortal
          ? Column(
              children: [
                Container(
                  color: Colors.orange,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    'Portal de configuración del ESP32',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: WebViewWidget(
                    controller: controller,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver a instrucciones'),
                    onPressed: () => setState(() => _showPortal = false),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recargar portal'),
                  onPressed: () => controller.reload(),
                )
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '¿Cómo conectar tu ESP32 a tu red WiFi?',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Enciende tu ESP32. Debería aparecer una red WiFi llamada "GASOX".\n'
                  '2. Conéctate a esa red desde tu teléfono.\n'
                  '3. Presiona el botón de abajo para abrir el portal de configuración.\n'
                  '4. Desde el portal, selecciona tu red WiFi y escribe la contraseña.\n'
                  '5. El ESP32 se conectará a tu red y la red "GASOX" desaparecerá.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Abrir portal de configuración'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => setState(() => _showPortal = true),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '¿Ya conectaste el ESP32 a tu red WiFi?',
                  style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'La app intentará conectar automáticamente a gasox.local.\n'
                  'Si no funciona, pega aquí la IP que te mostró el portal:',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _ipController,
                  decoration: InputDecoration(
                    labelText: 'IP del ESP32 (opcional)',
                    hintText: 'Ejemplo: 192.168.1.123',
                    filled: true,
                    fillColor: Colors.white10,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.save, color: Colors.orange),
                      onPressed: () => _saveIp(_ipController.text),
                    ),
                  ),
                  style: const TextStyle(color: Colors.orange),
                  keyboardType: TextInputType.url,
                  onSubmitted: (value) => _saveIp(value),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Luego, la app usará gasox.local o la IP que pegaste para comunicarse con el ESP32.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
    );
  }
}
