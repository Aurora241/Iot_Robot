import mqtt from "mqtt";

const broker = "mqtt://broker.emqx.io";
const client = mqtt.connect(broker);

const stateTopic = "/iot/robot/state";

client.on("connect", () => {
  console.log("✅ Connected to MQTT broker");
  setInterval(() => {
    const state = {
      motor_status: ["forward","backward","left","right","stop"][Math.floor(Math.random()*5)],
      led_status: Math.random() > 0.5 ? "on" : "off",
      battery_voltage: (7 + Math.random()).toFixed(2),
      timestamp: new Date().toISOString()
    };
    client.publish(stateTopic, JSON.stringify(state));
    console.log("📤 Sent:", state);
  }, 2000);
});
