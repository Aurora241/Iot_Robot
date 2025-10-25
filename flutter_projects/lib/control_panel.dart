import 'package:flutter/material.dart';
import 'mqtt_service.dart';

class ControlPanel extends StatelessWidget {
  final MQTTService mqtt;
  const ControlPanel({super.key, required this.mqtt});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(onPressed: () => mqtt.sendCommand("forward"), child: const Text("⬆ Forward")),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: () => mqtt.sendCommand("left"), child: const Text("⬅ Left")),
            const SizedBox(width: 20),
            ElevatedButton(onPressed: () => mqtt.sendCommand("stop"), child: const Text("⏹ Stop")),
            const SizedBox(width: 20),
            ElevatedButton(onPressed: () => mqtt.sendCommand("right"), child: const Text("➡ Right")),
          ],
        ),
        ElevatedButton(onPressed: () => mqtt.sendCommand("backward"), child: const Text("⬇ Backward")),
      ],
    );
  }
}
