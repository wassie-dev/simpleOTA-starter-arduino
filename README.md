# SimpleOTA Starter Arduino

An ESP32 sketch that connects to Wi-Fi, checks in to [SimpleOTA](https://simpleota.com) and installs later updates over the air. You flash it once over USB, and after that each version tag builds and ships the next firmware, as long as the repository secrets and variable listed under CI are set.

## Start

1. Click **Use this template** and create your own repository.
2. Copy `simpleOTA-starter-arduino/secrets.example.h` to `simpleOTA-starter-arduino/secrets.h`.
3. Paste your device token, Wi-Fi SSID, and Wi-Fi password into `secrets.h`.
4. Install the ESP32 board package and SimpleOTAClient 0.5.0. Open the sketch, choose **ESP32 Dev Module** and **Default 4MB with spiffs (1.2MB APP/1.5MB SPIFFS)**, and flash it over USB.
5. Set `FIRMWARE_VERSION` in the sketch, then tag `v` plus that version, for example `v1.0.0`.

## CI

Pull requests and pushes to main compile the sketch with Arduino CLI 1.5.1, ESP32 core 3.3.12, and SimpleOTAClient 0.5.0. A `v*` tag uploads that application binary and starts a rollout only when the `SIMPLEOTA_API_TOKEN` secret, the `SIMPLEOTA_PROJECT_ID` and `SIMPLEOTA_CHIP` variables, and the `SIMPLEOTA_WIFI_SSID`, `SIMPLEOTA_WIFI_PASSWORD`, and `SIMPLEOTA_DEVICE_TOKEN` secrets are all set. If the API token or project ID is missing, the upload is skipped and the run stays green. If a device secret is missing, or it is still a placeholder, the tag build fails and nothing is uploaded. Set `SIMPLEOTA_CHIP` to the chip you ship, or leave it unset for `esp32`; in the Arduino IDE you pick your board, enabling USB CDC On Boot on native-USB chips. The device checks once an hour, so a new release can take up to an hour or a reset to arrive.

## Help

See the [SimpleOTA documentation](https://wiki.simpleota.com/).

## License

MIT. See [LICENSE](LICENSE).
