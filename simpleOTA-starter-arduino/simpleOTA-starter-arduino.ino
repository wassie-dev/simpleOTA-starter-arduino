#include <WiFi.h>
#include <SimpleOTAClient.h>
#include "secrets.h"

#define FIRMWARE_VERSION "1.0.0"

SimpleOTAClient ota(SOTA_TOKEN, SimpleOTAClient::CHIP_ESP32);

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
    ota.setVersionLabel(FIRMWARE_VERSION);
}

void loop() {
    if (WiFi.status() != WL_CONNECTED) {
        connectWiFi();
    }

    ota.confirmRunning();

    if (ota.check()) {
        OTAResult r = ota.apply();
        if (r != OTA_SUCCESS) {
            Serial.println("[app] OTA failed, continuing");
        }
    }

    delay((uint32_t)SIMPLEOTA_CHECK_INTERVAL_S * 1000UL);
}
