#include <WiFiManager.h>
#include <ESPmDNS.h>

WiFiServer server(8080);

const int LED_PIN = 13;
const int buzzerPin = 26;
const int MQ4_PIN = 34; // ADC1_6 (GNC / Metano)
const int MQ7_PIN = 35; // ADC1_7 (CO)

int mq4Threshold = 3000;
int mq7Threshold = 3000;

unsigned long lastAlertTime = 0;
bool alarmState = false;

void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  pinMode(buzzerPin, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  digitalWrite(buzzerPin, LOW);

  WiFiManager wifiManager;

  // Cambia el color del portal a naranja
  wifiManager.setCustomHeadElement(
    "<style>"
    "body{background-color:#222;}"
    "h1,h2,h3,label,legend,span,div,td,th,p,a{color:#FFA500!important;}"
    "button,input[type='submit'],.btn{background-color:#FFA500!important;color:#222!important;font-weight:bold;}"
    "input,select{background-color:#333!important;color:#FFA500!important;border:1px solid #FFA500!important;}"
    ".msg{color:#FFA500!important;}"
    "</style>"
  );

  wifiManager.setAPCallback([](WiFiManager* wm) {
    Serial.println("Conéctate a la red GASOX y abre el portal para configurar.");
  });

  wifiManager.setSaveConfigCallback([]() {
    Serial.println("Configuración guardada, reiniciando...");
  });

  wifiManager.autoConnect("GASOX");

  // Mostrar la IP en el portal tras la conexión
  String ipMsg = "<div style='margin:24px 0;padding:16px;background:#222;border:2px solid #FFA500;border-radius:12px;'>";
  ipMsg += "<h2 style='color:#FFA500;'>¡Conexión exitosa!</h2>";
  ipMsg += "<p style='color:#FFA500;font-size:18px;'>La nueva IP de tu ESP32 es:</p>";
  ipMsg += "<div style='font-size:22px;font-weight:bold;color:#FFA500;background:#333;padding:8px 16px;border-radius:8px;display:inline-block;'>";
  ipMsg += WiFi.localIP().toString();
  ipMsg += "</div>";
  ipMsg += "<p style='color:#FFA500;'>Cópiala y pégala en la app si gasox.local no funciona.</p>";
  ipMsg += "</div>";

  wifiManager.setCustomMenuHTML(ipMsg.c_str());

  Serial.println("WiFi conectado!");
  Serial.print("Dirección IP: ");
  Serial.println(WiFi.localIP());
  
  MDNS.addService("http", "tcp", 8080);

  if (MDNS.begin("gasox")) {
    Serial.println("mDNS responder iniciado: gasox.local");
  } else {
    Serial.println("Error al iniciar mDNS");
  }

  server.begin();
  server.setNoDelay(true);
}

void activateAlarm(bool state) {
  if (state) {
    digitalWrite(LED_PIN, millis() % 1000 < 500 ? HIGH : LOW);
    digitalWrite(buzzerPin, millis() % 1000 < 500 ? HIGH : LOW);
  } else {
    digitalWrite(LED_PIN, LOW);
    digitalWrite(buzzerPin, LOW);
  }
}

void loop() {
  int mq4Value = analogRead(MQ4_PIN);
  int mq7Value = analogRead(MQ7_PIN);

  alarmState = mq4Value > mq4Threshold || mq7Value > mq7Threshold;
  activateAlarm(alarmState);

  WiFiClient client = server.available();
  if (client) {
    while (client.connected()) {
      if (client.available()) {
        String command = client.readStringUntil('\n');
        command.trim();

        if (command.startsWith("SET_THRESHOLD_MQ4:")) {
          mq4Threshold = command.substring(18).toInt();
          client.println("MQ4_UMBRAL_ACTUALIZADO");
        } else if (command.startsWith("SET_THRESHOLD_MQ7:")) {
          mq7Threshold = command.substring(18).toInt();
          client.println("MQ7_UMBRAL_ACTUALIZADO");
        } else if (command == "GET_VALUES") {
          client.printf("MQ4:%d\nMQ7:%d\n", mq4Value, mq7Value);
        } else if (command == "GET_ALARM_STATE") {
          client.println(alarmState ? "ALARMA_ACTIVA" : "SIN_ALARMA");
        } else if (command == "GET_IP") {
          client.println(WiFi.localIP());
        } else if (command == "FORGET_WIFI") {
          client.println("OLVIDANDO_WIFI");
          client.flush();
          delay(100);
          WiFi.disconnect(true, true);
          ESP.restart();
        } else {
          client.println("COMANDO_DESCONOCIDO");
        }
        client.flush();
      }
      delay(10);
    }
    client.stop();
  }
  delay(500);
}
