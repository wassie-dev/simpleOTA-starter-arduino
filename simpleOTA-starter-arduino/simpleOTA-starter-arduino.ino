#include <WiFi.h>
#include <simpleota.h>
#include "secrets.h"

#define FIRMWARE_VERSION "1.0.0"

#if !(defined(CONFIG_IDF_TARGET_ESP32) || defined(CONFIG_IDF_TARGET_ESP32S2) || \
      defined(CONFIG_IDF_TARGET_ESP32S3) || defined(CONFIG_IDF_TARGET_ESP32C3) || \
      defined(CONFIG_IDF_TARGET_ESP32C6) || defined(CONFIG_IDF_TARGET_ESP32H2))
#error "This chip is not supported. This starter supports esp32, esp32s2, esp32s3, esp32c3, esp32c6, and esp32h2."
#endif

static void connectWiFi() {
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASS);
    Serial.print("[app] Wi-Fi connecting");
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print('.');
    }
    Serial.printf("\n[app] Wi-Fi connected: %s\n", WiFi.localIP().toString().c_str());
}

void setup() {
    Serial.begin(115200);
    Serial.println(FIRMWARE_VERSION);
    delay(200);
    connectWiFi();

    simpleota_config_t cfg = {};
    cfg.token = SOTA_TOKEN;
    cfg.version_label = FIRMWARE_VERSION;
    if (simpleota_init(&cfg) != ESP_OK) {
        Serial.println("[app] SimpleOTA did not start; see the log above");
    }
}

void loop() {
    if (WiFi.status() != WL_CONNECTED) {
        connectWiFi();
    }

    simpleota_confirm();

    bool update = false;
    if (simpleota_check(&update) == ESP_OK && update) {
        simpleota_result_t r = simpleota_apply();
        if (r != SIMPLEOTA_OK) {
            Serial.println("[app] OTA failed, continuing");
        }
    }

    delay(3600UL * 1000UL);
}
