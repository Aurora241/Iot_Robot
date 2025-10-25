import mqtt from "mqtt";
import pkg from "pg";
import dotenv from "dotenv";
dotenv.config();

const { Pool } = pkg;

// Kết nối DB
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
});

// MQTT client
const MQTT_URL = `mqtt://${process.env.MQTT_BROKER}:${process.env.MQTT_PORT}`;
const client = mqtt.connect(MQTT_URL);

client.on("connect", () => {
  console.log("✅ Connected to MQTT broker");
  client.subscribe(process.env.MQTT_TOPIC);
  console.log(`📡 Subscribed to ${process.env.MQTT_TOPIC}`);
});

client.on("message", async (topic, message) => {
  try {
    const data = JSON.parse(message.toString());
    console.log("📩 Received:", data);

    const query = `
      INSERT INTO robot_logs (direction, led, voltage, m1, m2, m3, m4)
      VALUES ($1,$2,$3,$4,$5,$6,$7)
    `;
    const values = [
      data.direction,
      data.led,
      data.voltage,
      data.m1,
      data.m2,
      data.m3,
      data.m4,
    ];

    await pool.query(query, values);
    console.log("✅ Saved to database");
  } catch (err) {
    console.error("❌ Error:", err.message);
  }
});
