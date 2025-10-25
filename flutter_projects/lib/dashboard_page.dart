import 'package:flutter/material.dart';
import 'mqtt_service.dart';

class DashboardPage extends StatefulWidget {
  final MQTTService mqtt;
  const DashboardPage({super.key, required this.mqtt});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isMqttConnected = false;
  bool isDeviceOnline = false;
  String voltage = "--";
  String ledStatus = "--";
  String direction = "--";
  Map<String, bool> motors = {"M1": false, "M2": false, "M3": false, "M4": false};

  @override
  void initState() {
    super.initState();
    _listenToMqttStatus();
  }

  void _listenToMqttStatus() {
    // Lắng nghe trạng thái kết nối MQTT
    widget.mqtt.onConnectionChange = (isConnected) {
      setState(() {
        isMqttConnected = isConnected;
      });
    };

    // Lắng nghe dữ liệu từ robot
    widget.mqtt.onStateUpdate = (data) {
      setState(() {
        isDeviceOnline = true;
        voltage = data['voltage']?.toString() ?? '--';
        ledStatus = (data['led'] == true) ? 'ON' : 'OFF';
        direction = data['direction']?.toString() ?? '--';
        motors['M1'] = data['m1'] == true;
        motors['M2'] = data['m2'] == true;
        motors['M3'] = data['m3'] == true;
        motors['M4'] = data['m4'] == true;
      });
    };

    // Kiểm tra trạng thái kết nối ban đầu
    setState(() {
      isMqttConnected = widget.mqtt.isConnected;
    });
  }

  void _sendCommand(String cmd) {
    widget.mqtt.sendCommand(cmd);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0a0e27), Color(0xFF1a1f3a)],
          ),
        ),
        child: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.landscape) {
                return _buildLandscapeLayout();
              }
              return _buildPortraitLayout();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Left side - Control Panel
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 10),
                  _buildControlPanel(),
                ],
              ),
            ),
          ),
        ),
        // Right side - Status Panel
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusCards(),
                  const SizedBox(height: 12),
                  _buildRobotStatus(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildStatusCards(),
        const SizedBox(height: 20),
        Expanded(child: _buildControlPanel()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ).createShader(bounds),
        child: const Text(
          '🚗 Robot Controller',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            icon: '📡',
            title: 'MQTT',
            status: isMqttConnected ? 'Connected' : 'Disconnected',
            isConnected: isMqttConnected,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatusCard(
            icon: '🤖',
            title: 'Device',
            status: isDeviceOnline ? 'Online' : 'Offline',
            isConnected: isDeviceOnline,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String icon,
    required String title,
    required String status,
    required bool isConnected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isConnected
              ? [
            const Color(0xFF10b981).withOpacity(0.1),
            const Color(0xFF059669).withOpacity(0.1),
          ]
              : [
            const Color(0xFFef4444).withOpacity(0.1),
            const Color(0xFFdc2626).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? const Color(0xFF10b981).withOpacity(0.3)
              : const Color(0xFFef4444).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isConnected ? const Color(0xFF10b981) : const Color(0xFFef4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Forward button
          _buildControlButton(
            icon: '▲',
            onPressed: () => _sendCommand('forward'),
            size: 100,
          ),
          const SizedBox(height: 20),
          // Left, Stop, Right buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: '◄',
                onPressed: () => _sendCommand('left'),
                size: 100,
              ),
              const SizedBox(width: 20),
              _buildControlButton(
                icon: '■',
                onPressed: () => _sendCommand('stop'),
                size: 100,
                isStop: true,
              ),
              const SizedBox(width: 20),
              _buildControlButton(
                icon: '►',
                onPressed: () => _sendCommand('right'),
                size: 100,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Backward button
          _buildControlButton(
            icon: '▼',
            onPressed: () => _sendCommand('backward'),
            size: 100,
          ),
          const SizedBox(height: 40),
          // LED Toggle button
          _buildLedButton(),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required String icon,
    required VoidCallback onPressed,
    required double size,
    bool isStop = false,
  }) {
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) => setState(() {}),
      onTapCancel: () => setState(() {}),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          splashColor: isStop
              ? const Color(0xFFef4444).withOpacity(0.3)
              : const Color(0xFF6366f1).withOpacity(0.3),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isStop
                    ? [
                  const Color(0xFFef4444).withOpacity(0.1),
                  const Color(0xFFdc2626).withOpacity(0.1),
                ]
                    : [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isStop
                    ? const Color(0xFFef4444).withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isStop
                      ? const Color(0xFFef4444).withOpacity(0.2)
                      : const Color(0xFF6366f1).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                icon,
                style: TextStyle(
                  fontSize: size * 0.4,
                  color: isStop ? const Color(0xFFef4444) : const Color(0xFF60a5fa),
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLedButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8b5cf6), Color(0xFF6366f1)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8b5cf6).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _sendCommand('toggle_led'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
            child: const Text(
              '💡 Toggle LED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRobotStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF60a5fa), Color(0xFF3b82f6)],
            ).createShader(bounds),
            child: const Text(
              '📊 Robot Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildStatusRow('Điện áp pin', voltage),
          _buildStatusRow('LED', ledStatus),
          _buildStatusRow('Hướng xe', direction),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            '⚙️ Động cơ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...motors.entries.map((e) => _buildStatusRow(e.key, e.value ? 'ON' : 'OFF')),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF60a5fa),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}