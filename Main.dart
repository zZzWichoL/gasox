import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/esp32_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Verificar sensores en segundo plano
    final esp32Service = ESP32Service();
    await esp32Service.checkAlarmBackground();
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar base de datos
  await DatabaseService.instance.database;

  // Configurar notificaciones
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Solicitar permisos
  await _requestPermissions();

  // Inicializar worker para background tasks
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  runApp(const GasoxApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.location,
    Permission.nearbyWifiDevices,
  ].request();
}

class GasoxApp extends StatelessWidget {
  const GasoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GASOX',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.orange,
        colorScheme: ColorScheme.dark(
          primary: Colors.orange,
          secondary: Colors.orangeAccent,
          background: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.orange,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFD32F2F),
          foregroundColor: Colors.white,
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Colors.orange,
          thumbColor: Colors.orangeAccent,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
