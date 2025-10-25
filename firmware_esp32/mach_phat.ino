#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// ===================== WIFI + MQTT =====================
const char* WIFI_SSID = "Long";
const char* WIFI_PASS = "ductai123";
const char* MQTT_HOST = "broker.emqx.io";
const int   MQTT_PORT = 1883;
const char* TOPIC_CMD = "/iot/robot/command";
const char* DEVICE_ID = "esp32_gesture_final";

// ===================== PIN =====================
#define X_PIN 34
#define Y_PIN 35
#define Z_PIN 32
#define LED_PIN 2

WiFiClient espClient;
PubSubClient mqttClient(espClient);

// ===================== OFFSET + BIẾN TRẠNG THÁI =====================
float offsetX = 0, offsetY = 0, offsetZ = 0;
String lastCmd = "";

// ===================== WIFI =====================
void setupWiFi() {
  Serial.print("Connecting WiFi ");
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✅ WiFi Connected!");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());
}

// ===================== MQTT =====================
void reconnectMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("Connecting MQTT...");
    if (mqttClient.connect(DEVICE_ID)) {
      Serial.println("✅ Connected to MQTT broker");
    } else {
      Serial.print("❌ Failed, rc=");
      Serial.println(mqttClient.state());
      delay(2000);
    }
  }
}

// ===================== GỬI LỆNH MQTT =====================
void sendCmd(const String& cmd, float x, float y, float z) {
  StaticJsonDocument<64> doc;
  doc["cmd"] = cmd;
  char payload[64];
  serializeJson(doc, payload);
  mqttClient.publish(TOPIC_CMD, payload);

  Serial.printf("📤 Sent gesture: %s\n", cmd.c_str());
  Serial.printf("  → X: %.2f, Y: %.2f, Z: %.2f\n", x, y, z);

  digitalWrite(LED_PIN, HIGH);
  delay(60);
  digitalWrite(LED_PIN, LOW);
}

// ===================== PHÁT HIỆN CỬ CHỈ =====================
void detectGesture(float x, float y, float z) {
  String cmd = "";
  float threshold = 0.10;  // ngưỡng nghiêng rõ

  if (x > threshold) cmd = "forward";
  else if (x < -threshold) cmd = "backward";
  else if (y > threshold) cmd = "right";
  else if (y < -threshold) cmd = "left";
  else cmd = "stop";

  if (cmd != lastCmd) {
    lastCmd = cmd;
    sendCmd(cmd, x, y, z);
  }
}

// ===================== ĐO OFFSET TỰ ĐỘNG =====================
void calibrateSensor() {
  Serial.println("🔧 Calibrating ADXL335 (giữ tay cố định 2s)...");
  long sumX = 0, sumY = 0, sumZ = 0;
  const int samples = 200;
  for (int i = 0; i < samples; i++) {
    sumX += analogRead(X_PIN);
    sumY += analogRead(Y_PIN);
    sumZ += analogRead(Z_PIN);
    delay(10);
  }
  offsetX = sumX / (float)samples;
  offsetY = sumY / (float)samples;
  offsetZ = sumZ / (float)samples;
  Serial.printf("✅ Offset: X=%.1f  Y=%.1f  Z=%.1f\n", offsetX, offsetY, offsetZ);
}

// ===================== SETUP =====================
void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  setupWiFi();
  mqttClient.setServer(MQTT_HOST, MQTT_PORT);
  mqttClient.setKeepAlive(45);

  calibrateSensor();
  Serial.println("✅ ADXL335 Gesture Controller Ready");
}

// ===================== LOOP =====================
void loop() {
  if (!mqttClient.connected()) reconnectMQTT();
  mqttClient.loop();

  int rawX = analogRead(X_PIN);
  int rawY = analogRead(Y_PIN);
  int rawZ = analogRead(Z_PIN);

  float x = (rawX - offsetX) / 2048.0;
  float y = -(rawY - offsetY) / 2048.0;
  float z = (rawZ - offsetZ) / 2048.0;

  detectGesture(x, y, z);
  delay(120);
}
