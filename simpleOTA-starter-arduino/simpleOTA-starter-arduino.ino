#include <WiFi.h>
#include <SimpleOTAClient.h>
#include "secrets.h"

#define FIRMWARE_VERSION "1.0.0"

#if defined(CONFIG_IDF_TARGET_ESP32)
static const char* chipFamily = SimpleOTAClient::CHIP_ESP32;
#elif defined(CONFIG_IDF_TARGET_ESP32S2)
static const char* chipFamily = SimpleOTAClient::CHIP_ESP32S2;
#elif defined(CONFIG_IDF_TARGET_ESP32S3)
static const char* chipFamily = SimpleOTAClient::CHIP_ESP32S3;
#elif defined(CONFIG_IDF_TARGET_ESP32C3)
static const char* chipFamily = SimpleOTAClient::CHIP_ESP32C3;
#elif defined(CONFIG_IDF_TARGET_ESP32C6)
static const char* chipFamily = SimpleOTAClient::CHIP_ESP32C6;
#elif defined(CONFIG_IDF_TARGET_ESP32H2)
static const char* chipFamily = SimpleOTAClient::CHIP_ESP32H2;
#else
#error "This chip is not supported. SimpleOTAClient supports esp32, esp32s2, esp32s3, esp32c3, esp32c6, and esp32h2."
#endif

SimpleOTAClient ota(SOTA_TOKEN, chipFamily);

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
