#include <Arduino.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "driver/ledc.h"

// ================== CONFIG ==================
const char* WIFI_SSID = "Long";
const char* WIFI_PASS = "ductai123";

const char* MQTT_HOST = "broker.emqx.io";
const int   MQTT_PORT = 1883;
const char* TOPIC_CMD = "/iot/robot/command";
const char* TOPIC_STATE = "/iot/robot/state";
const char* DEVICE_ID = "esp32_robot_receiver_v3";

// ================== GPIO CONFIG ==================
// ⚠️ ENA đã đổi sang GPIO33 để tránh lỗi boot
#define ENA 33
#define IN1 13
#define IN2 14
#define IN3 25
#define IN4 26
#define ENB 27
#define LED_PIN 2 
#define VOLTAGE_PIN 34

// ================== PWM CONFIG ==================
#define ENA_CH LEDC_CHANNEL_0
#define ENB_CH LEDC_CHANNEL_1
#define PWM_FREQ 1000
#define PWM_RES LEDC_TIMER_8_BIT
#define PWM_MODE LEDC_LOW_SPEED_MODE
#define PWM_TIMER LEDC_TIMER_0

WiFiClient espClient;
PubSubClient mqttClient(espClient);

int baseSpeed = 180; 
unsigned long lastStateSent = 0;

// === CONFIG CHỮA HƯỚNG ===
// Nếu bạn thấy xe chạy sai, chỉ cần đổi giá trị 0↔1 ở đây
#define SWAP_LR   0   // 1 nếu hai bên bị đấu chéo
#define LEFT_INV  0   // 1 nếu bánh trái quay ngược
#define RIGHT_INV 1   // 1 nếu bánh phải quay ngược

// ================== PWM SETUP ==================
void setupPWM() {
  ledc_timer_config_t timerConf = {
    .speed_mode = PWM_MODE,
    .duty_resolution = PWM_RES,
    .timer_num = PWM_TIMER,
    .freq_hz = PWM_FREQ,
    .clk_cfg = LEDC_AUTO_CLK
  };
  ledc_timer_config(&timerConf);

  ledc_channel_config_t enaConf = {
    .gpio_num = ENA,
    .speed_mode = PWM_MODE,
    .channel = ENA_CH,
    .intr_type = LEDC_INTR_DISABLE,
    .timer_sel = PWM_TIMER,
    .duty = 0,
    .hpoint = 0
  };
  ledc_channel_config(&enaConf);

  ledc_channel_config_t enbConf = {
    .gpio_num = ENB,
    .speed_mode = PWM_MODE,
    .channel = ENB_CH,
    .intr_type = LEDC_INTR_DISABLE,
    .timer_sel = PWM_TIMER,
    .duty = 0,
    .hpoint = 0
  };
  ledc_channel_config(&enbConf);
}

void setMotorSpeed(int left, int right) {
  ledc_set_duty(PWM_MODE, ENA_CH, left);
  ledc_update_duty(PWM_MODE, ENA_CH);
  ledc_set_duty(PWM_MODE, ENB_CH, right);
  ledc_update_duty(PWM_MODE, ENB_CH);
}

// ================== MOTOR DIRECTION HANDLER ==================
void setLR(int L, int R) {
  // L,R: -1=lùi, 0=dừng, +1=tiến
  if (SWAP_LR) { int t=L; L=R; R=t; }
  if (LEFT_INV)  L = -L;
  if (RIGHT_INV) R = -R;

  // TRÁI = IN1,IN2 | PHẢI = IN3,IN4
  if (L > 0)      { digitalWrite(IN1,HIGH); digitalWrite(IN2,LOW);  }
  else if (L<0)   { digitalWrite(IN1,LOW);  digitalWrite(IN2,HIGH); }
  else            { digitalWrite(IN1,LOW);  digitalWrite(IN2,LOW);  }

  if (R > 0)      { digitalWrite(IN3,HIGH); digitalWrite(IN4,LOW);  }
  else if (R<0)   { digitalWrite(IN3,LOW);  digitalWrite(IN4,HIGH); }
  else            { digitalWrite(IN3,LOW);  digitalWrite(IN4,LOW);  }
}

// ================== WIFI ==================
void setupWiFi() {
  Serial.print("Connecting WiFi ");
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✅ WiFi Connected!");
}

// ================== MQTT ==================
void reconnectMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("Connecting MQTT...");
    if (mqttClient.connect(DEVICE_ID)) {
      Serial.println("✅ Connected");
      mqttClient.subscribe(TOPIC_CMD);
      publishState("idle");
    } else {
      Serial.print("❌ Failed rc=");
      Serial.println(mqttClient.state());
      delay(2000);
    }
  }
}

// ================== STATE REPORT ==================
void publishState(const char* direction) {
  float adc = analogRead(VOLTAGE_PIN);
  float voltage = adc / 4095.0 * 3.3 * 2.0;

  StaticJsonDocument<128> doc;
  doc["direction"] = direction;
  doc["led"] = digitalRead(LED_PIN);
  doc["voltage"] = voltage;
  doc["m1"] = digitalRead(IN1);
  doc["m2"] = digitalRead(IN2);
  doc["m3"] = digitalRead(IN3);
  doc["m4"] = digitalRead(IN4);

  char payload[128];
  serializeJson(doc, payload);
  mqttClient.publish(TOPIC_STATE, payload);
  Serial.println(payload);
}

// ================== COMMAND HANDLERS ==================
void stopMotors()  { setLR(0,0); setMotorSpeed(0,0); }
void moveForward() { setLR(+1,+1); setMotorSpeed(baseSpeed, baseSpeed); }
void moveBackward(){ setLR(-1,-1); setMotorSpeed(baseSpeed, baseSpeed); }
void turnLeft()    { setLR(-1,+1); setMotorSpeed(baseSpeed*0.3, baseSpeed*0.3); }
void turnRight()   { setLR(+1,-1); setMotorSpeed(baseSpeed*0.3, baseSpeed*0.3); }

// ================== CALLBACK ==================
void callback(char* topic, byte* payload, unsigned int length) {
  char msg[length + 1];
  memcpy(msg, payload, length);
  msg[length] = '\0';

  StaticJsonDocument<64> doc;
  deserializeJson(doc, msg);
  String cmd = doc["cmd"].as<String>();

  Serial.print("📩 Command: ");
  Serial.println(cmd);

  if (cmd == "forward") moveForward();
  else if (cmd == "backward") moveBackward();
  else if (cmd == "left") turnLeft();
  else if (cmd == "right") turnRight();
  else if (cmd == "stop") stopMotors();
  else if (cmd == "toggle_led") digitalWrite(LED_PIN, !digitalRead(LED_PIN));

  publishState(cmd.c_str());
}

// ================== SETUP ==================
void setup() {
  Serial.begin(115200);
  setupWiFi();

  mqttClient.setServer(MQTT_HOST, MQTT_PORT);
  mqttClient.setCallback(callback);

  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  pinMode(VOLTAGE_PIN, INPUT);

  setupPWM();
  stopMotors();

  Serial.println("✅ Robot ready (hướng đã hiệu chỉnh)");
}

// ================== LOOP ==================
void loop() {
  if (!mqttClient.connected()) reconnectMQTT();
  mqttClient.loop();

  if (millis() - lastStateSent > 5000) {
    publishState("active");
    lastStateSent = millis();
  }
  delay(50);
}
