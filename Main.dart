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
    Permission.notification,
    Permission.accessWifiState,
    Permission.changeWifiState,
  ].request();
}

class GasoxApp extends StatelessWidget {
  const GasoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GASOX',
      theme: ThemeData(
        primarySwatch: Colors.red,
        primaryColor: const Color(0xFFD32F2F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD32F2F),
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFD32F2F),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
