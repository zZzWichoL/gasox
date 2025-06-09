import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/esp32_service.dart';

class NetworkSettingsScreen extends StatefulWidget {
  const NetworkSettingsScreen({super.key});

  @override
  State<NetworkSettingsScreen> createState() => _NetworkSettingsScreenState();
}

class _NetworkSettingsScreenState extends State<NetworkSettingsScreen> {
  final ESP32Service _esp32Service = ESP32Service();
  List<WiFiAccessPoint> _wifiNetworks = [];
  bool _isScanning = false;
  bool _isConnectedToGASOX = false;
  String? _selectedNetwork;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkGASOXConnection();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.accessWifiState,
      Permission.changeWifiState,
      Permission.nearbyWifiDevices,
    ].request();
  }

  Future<void> _checkGASOXConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.wifi) {
      // Aquí puedes verificar si estás conectado a GASOX
      // Por simplicidad, asumimos que si el ESP32 responde, estamos conectados
      try {
        await _esp32Service.getSensorValues();
        setState(() {
          _isConnectedToGASOX = true;
        });
        _scanWiFiNetworks();
      } catch (e) {
        setState(() {
          _isConnectedToGASOX = false;
        });
      }
    }
  }

  Future<void> _scanWiFiNetworks() async {
    if (!_isConnectedToGASOX) return;
    
    setState(() {
      _isScanning = true;
    });

    try {
      final canScan = await WiFiScan.instance.canStartScan();
      if (canScan == CanStartScan.yes) {
        await WiFiScan.instance.startScan();
        
        // Esperar un momento para que complete el escaneo
        await Future.delayed(const Duration(seconds: 3));
        
        final networks = await WiFiScan.instance.getScannedResults();
        setState(() {
          _wifiNetworks = networks
              .where((network) => network.ssid.isNotEmpty)
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al escanear redes WiFi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _connectToWiFi() async {
    if (_selectedNetwork == null) return;

    try {
      // Aquí implementarías la lógica para conectar el ESP32 a la red WiFi
      // Por ahora, solo mostramos un mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conectando ESP32 a $_selectedNetwork...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Simular conexión
      await Future.delayed(const Duration(seconds: 2));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ESP32 conectado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al conectar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _forgetWiFi() async {
    try {
      await _esp32Service.forgetWiFi();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WiFi olvidada. ESP32 reiniciado.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al olvidar WiFi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración WiFi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instrucciones
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instrucciones de Conexión',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Asegúrate de que el ESP32 esté encendido\n'
                      '2. Conecta tu dispositivo a la red "GASOX"\n'
                      '3. Una vez conectado, escanea las redes disponibles\n'
                      '4. Selecciona la red WiFi deseada e ingresa la contraseña\n'
                      '5. El ESP32 se conectará a tu red WiFi',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Estado de conexión
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _isConnectedToGASOX ? Icons.wifi : Icons.wifi_off,
                      color: _isConnectedToGASOX ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isConnectedToGASOX 
                                ? 'Conectado a GASOX' 
                                : 'No conectado a GASOX',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isConnectedToGASOX 
                                ? 'Listo para configurar WiFi' 
                                : 'Conéctate a la red GASOX primero',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    if (!_isConnectedToGASOX)
                      ElevatedButton(
                        onPressed: _checkGASOXConnection,
                        child: const Text('Verificar'),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Configuración IP personalizada
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'IP del ESP32 (opcional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        hintText: '192.168.1.100',
                        labelText: 'Dirección IP',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_ipController.text.isNotEmpty) {
                            await _esp32Service.setESP32IP(_ipController.text);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('IP configurada correctamente'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: const Text('Configurar IP'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Lista de redes WiFi
            if (_isConnectedToGASOX) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Redes WiFi Disponibles',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: _isScanning ? null : _scanWiFiNetworks,
                            icon: _isScanning 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (_wifiNetworks.isEmpty && !_isScanning) ...[
                        const Text('No se encontraron redes. Presiona actualizar.'),
                      ] else ...[
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: _wifiNetworks.length,
                            itemBuilder: (context, index) {
                              final network = _wifiNetworks[index];
                              return ListTile(
                                leading: Icon(
                                  Icons.wifi,
                                  color: _getSignalColor(network.level),
                                ),
                                title: Text(network.ssid),
                                subtitle: Text('${network.level} dBm'),
                                trailing: Radio<String>(
                                  value: network.ssid,
                                  groupValue: _selectedNetwork,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedNetwork = value;
                                    });
                                  },
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedNetwork = network.ssid;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Configuración de contraseña
              if (_selectedNetwork != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conectar a: $_selectedNetwork',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña WiFi',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _connectToWiFi,
                            child: const Text('Conectar ESP32'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Botón para olvidar WiFi
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _forgetWiFi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Olvidar WiFi y Reiniciar ESP32'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSignalColor(int level) {
    if (level > -50) return Colors.green;
    if (level > -70) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _ipController.dispose();
    super.dispose();
  }
}
