import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MQTTService {
  late final MqttServerClient client;

  // Callbacks để cập nhật UI
  Function(bool)? onConnectionChange;
  Function(Map<String, dynamic>)? onStateUpdate;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  MQTTService() {
    final clientId = 'flutter_robot_${DateTime.now().millisecondsSinceEpoch}';

    if (kIsWeb) {
      // Flutter Web → dùng WebSocket với EMQX
      client = MqttServerClient.withPort('broker.emqx.io', clientId, 8084);
      client.useWebSocket = true;
      client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
    } else {
      // Android / iOS → dùng TCP với EMQX
      client = MqttServerClient.withPort('broker.emqx.io', clientId, 1883);
    }

    client.logging(on: false); // Tắt log để clean hơn
    client.keepAlivePeriod = 60;
    client.autoReconnect = true;
    client.onAutoReconnect = _onAutoReconnect;
    client.onAutoReconnected = _onAutoReconnected;
  }

  void _onAutoReconnect() {
    print('🔄 Auto reconnecting...');
    _isConnected = false;
    onConnectionChange?.call(false);
  }

  void _onAutoReconnected() {
    print('✅ Auto reconnected!');
    _isConnected = true;
    onConnectionChange?.call(true);
    _subscribeToTopics();
  }

  Future<void> connect() async {
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(client.clientIdentifier)
        .withWillTopic('will')
        .withWillMessage('disconnect')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    client.connectionMessage = connMessage;

    try {
      print('🔌 Connecting to ${client.server}:${client.port}...');
      await client.connect();
    } catch (e) {
      print('⚠️ Connection error: $e');
      client.disconnect();
      _isConnected = false;
      onConnectionChange?.call(false);
    }
  }

  void _onConnected() {
    print('✅ Connected to MQTT broker');
    _isConnected = true;
    onConnectionChange?.call(true);
    _subscribeToTopics();
  }

  void _onDisconnected() {
    print('❌ Disconnected from MQTT broker');
    _isConnected = false;
    onConnectionChange?.call(false);
  }

  void _onSubscribed(String topic) {
    print('📡 Subscribed to $topic');
  }

  void _subscribeToTopics() {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.subscribe('/iot/robot/state', MqttQos.atMostOnce);

      client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        final recMess = messages[0].payload as MqttPublishMessage;
        final msg = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        try {
          final data = jsonDecode(msg) as Map<String, dynamic>;
          print('📩 State received: $data');
          onStateUpdate?.call(data);
        } catch (e) {
          print('⚠️ Error parsing message: $e');
        }
      });
    }
  }

  void sendCommand(String cmd) {
    if (!_isConnected) {
      print('⚠️ Not connected to MQTT broker');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    final payload = jsonEncode({'cmd': cmd});
    builder.addString(payload);

    print('📤 Sending $payload to /iot/robot/command');
    client.publishMessage(
      '/iot/robot/command',
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }

  void disconnect() {
    client.disconnect();
  }
}