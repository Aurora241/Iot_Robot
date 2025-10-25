import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mqtt_service.dart';
import 'dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Cho phép xoay màn hình ngang
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);
  runApp(const RobotControllerApp());
}

class RobotControllerApp extends StatefulWidget {
  const RobotControllerApp({super.key});

  @override
  State<RobotControllerApp> createState() => _RobotControllerAppState();
}

class _RobotControllerAppState extends State<RobotControllerApp> {
  final mqtt = MQTTService();

  @override
  void initState() {
    super.initState();
    mqtt.connect();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0a0e27),
        fontFamily: 'Inter',
      ),
      home: DashboardPage(mqtt: mqtt),
    );
  }
}