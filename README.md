# SimpleOTA Starter Arduino

This is an ESP32 sketch that joins your Wi-Fi, checks in to [SimpleOTA](https://simpleota.com), and installs later firmware over the air. You flash it once from your computer. After that, a version tag on this repository builds the next firmware and starts the rollout.

The workflow installs SimpleOTAClient 0.5.0. The upload is unsigned: no signing key is passed, and the release is stored as `basic`.

## What you need

Before you start, have these ready:

- An ESP32 board with 4 MB of flash. The partition scheme below is the 4 MB layout, with two app slots.
- A USB cable that carries data, so the computer can see the board.
- A SimpleOTA account. The [getting started](https://wiki.simpleota.com/getting-started/) guide has the sign-up link.
- Either the Arduino IDE, or the Arduino CLI. The GitHub workflow uses Arduino CLI 1.5.1. Locally, a current Arduino CLI is enough, because `scripts/build.sh` installs the ESP32 core and the library itself.

You will also collect a project id, a device token, and an API token. The next section says where each one appears in the dashboard.

## Create your repository

1. On GitHub, open this template repository and click **Use this template**, then **Create a new repository**.
2. Choose a name and create the repository.
3. Clone the repository you just created and move into it:

```bash
git clone https://github.com/YOU/YOUR-REPO.git
cd YOUR-REPO
```

The rest of this guide assumes you are in that clone.

## Create the SimpleOTA project

A project is the bucket for your devices, firmware, and tokens. Create one before you flash.

1. Open the SimpleOTA dashboard and click **Projects**, then **New project**.
2. Give the project a name. The slug is filled in from the name. Use **Edit** next to the slug if you want a different one. Lowercase with hyphens works well, for example `office-thermostat`.
3. Click **Save**. The name and the slug are fixed after this. Deleting the project is the way to change them, and that deletes its devices and firmware too.

### Project ID

Open the project. Under its name is **Project ID**, a UUID, with a copy button. That UUID is what GitHub needs as the `SIMPLEOTA_PROJECT_ID` variable. The slug is a label for people. It is not the id.

An example shape is `123e4567-e89b-12d3-a456-426614174000`. Copy yours. You will paste it into GitHub later, on the Variables tab.

### Device token

The sketch authenticates with a device token. The [device tokens](https://wiki.simpleota.com/guides/device-tokens/) guide describes that credential. That token belongs to one device id, and the raw value is shown once.

This sketch does not pass its own device id. SimpleOTAClient 0.5.0 then sends the board's Wi-Fi station MAC, lowercase, with colons, in the form `aa:bb:cc:dd:ee:ff`. The device id you enter has to be that same string. With [esptool](https://docs.espressif.com/projects/esptool/en/latest/esp32/esptool/basic-commands.html#read-mac-read-mac) installed, read it before the first flash:

```bash
esptool --port /dev/ttyUSB0 read-mac
```

Use the serial port the board shows up on. Type the MAC in lowercase with colons. If the command is missing, install it with `pip install esptool` and run it again.

Create the device and copy the token:

1. Open the project.
2. In the **Devices** card, click **Add device**.
3. Enter that MAC as the device id. The dashboard hardware fields can be left blank. This sketch reports its framework and chip family when it checks in, and it leaves board and partition out. OTA still matches, because the CI manifest leaves them out too.
4. Submit the form. Copy the raw token from the yellow alert box immediately. SimpleOTA stores only a hash, so the page will not show it again.

Device tokens start with `soto_dev_`. Paste this value into `secrets.h` and, later, into the `SIMPLEOTA_DEVICE_TOKEN` secret. Both copies need to be the same token, because a tagged build rewrites `secrets.h` from the GitHub secrets.

### API token

The GitHub workflow uploads firmware with a project API token, which is a different credential from the device token.

1. Open the project.
2. On the **Project API tokens** card, click **Issue token**.
3. Give it a name you will recognize later, such as `ci-upload`.
4. Tick the `api` scope. Scopes are checkboxes. A new token defaults to `device` only, and a `device` scope token cannot upload firmware. The `api` scope is the one that can upload and start a rollout.
5. Copy the token immediately. It is shown once.

Project tokens start with `soto_proj_`. This value is the `SIMPLEOTA_API_TOKEN` secret. Keep it in GitHub. It does not go in the sketch.

## Choose the chip

`scripts/build.sh` accepts one of these values for `SIMPLEOTA_CHIP`. When the variable is unset or empty, the script builds `esp32`.

| Value | Board in the Arduino IDE | USB CDC On Boot |
| --- | --- | --- |
| `esp32` | ESP32 Dev Module | This board has no such menu |
| `esp32s2` | ESP32S2 Dev Module | Enabled |
| `esp32s3` | ESP32S3 Dev Module | Enabled |
| `esp32c3` | ESP32C3 Dev Module | Enabled |
| `esp32c6` | ESP32C6 Dev Module | Enabled |
| `esp32h2` | ESP32H2 Dev Module | Enabled |

The boards are under **Tools > Board > ESP32 Arduino**. Pick the Dev Module row that matches the chip you will put in `SIMPLEOTA_CHIP`. The build script compiles `esp32:esp32:<chip>`, which is that Dev Module. A different board entry, even for the same chip, can compile a different binary than GitHub will ship.

Every chip in the table uses the same partition scheme: **Tools > Partition Scheme > Default 4MB with spiffs (1.2MB APP/1.5MB SPIFFS)**. If **Tools > Flash Size** is available, set it to **4MB (32Mb)**.

Open the serial monitor at 115200 baud, which is the speed of `Serial.begin` in the sketch. On the S2, S3, C3, C6, and H2, set **Tools > USB CDC On Boot** to **Enabled**. The build script passes `CDCOnBoot=cdc` for those chips, which is that Enabled option. Serial output from the sketch then uses the native USB port. If the board has two USB sockets, open the serial monitor on the native USB one. The original ESP32 Dev Module has no USB CDC On Boot menu, and you leave that menu alone.

The sketch itself selects the chip family from the board you compile for. GitHub sends that same family when it uploads. If the IDE board and `SIMPLEOTA_CHIP` disagree, the device will not be offered the CI build.

## Add your local secrets

The sketch reads Wi-Fi and the device token from a header that git does not track.

1. From the repository root, copy the example:

```bash
cp simpleOTA-starter-arduino/secrets.example.h simpleOTA-starter-arduino/secrets.h
```

2. Open `simpleOTA-starter-arduino/secrets.h` and replace the three placeholders:

| Field | Replace the placeholder with |
| --- | --- |
| `WIFI_SSID` | The Wi-Fi network name. The example value is `your-ssid`. |
| `WIFI_PASS` | The Wi-Fi password. The example value is `your-password`. |
| `SOTA_TOKEN` | The device token from the yellow alert box (`soto_dev_...`). The example value is `your-device-token`. |

`.gitignore` lists `secrets.h`, so git does not commit that file. It also ignores `build/`. Leave the example header as it is and edit only `secrets.h`.

Use the real network name, password, and token before you flash, and store the same three strings in GitHub before you tag.

## Flash over USB the first time

The first USB flash is the one that writes the bootloader, the partition table, and the application. An over-the-air update replaces the application only, in the other app slot (`app0` and `app1` in the default table). It cannot change the partition table. The scheme you pick now is the scheme the board keeps until you flash over USB again. That default 4 MB scheme is the one with two app slots, which SimpleOTA needs in order to install an update and roll back.

Install SimpleOTAClient 0.5.0 for a local IDE build. The CLI path below installs that same version for you.

### Arduino IDE

1. Install the ESP32 boards. In **File > Preferences**, add this Additional boards manager URL:

```text
https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
```

2. Open **Tools > Board > Boards Manager**, search for `esp32`, and install **esp32 by Espressif Systems** version **3.3.12**. That is the core the GitHub workflow installs.
3. Open **Sketch > Include Library > Manage Libraries**, search for `SimpleOTAClient`, and install version **0.5.0**.
4. Open `simpleOTA-starter-arduino/simpleOTA-starter-arduino.ino`.
5. Under **Tools**, select the Dev Module from the table above, the partition scheme **Default 4MB with spiffs (1.2MB APP/1.5MB SPIFFS)**, and Flash Size **4MB (32Mb)** when that menu exists. Set **USB CDC On Boot** as described in Choose the chip.
6. Under **Tools > Port**, select the board. If the board has two USB sockets, use the native USB port described in Choose the chip.
7. Click Upload.
8. Open **Tools > Serial Monitor** at 115200 baud, as described in Choose the chip.

### Arduino CLI

From the repository root, with `secrets.h` already filled in:

```bash
# Omit this line to build the default, esp32.
# Use esp32s2, esp32s3, esp32c3, esp32c6, or esp32h2 to match your board.
export SIMPLEOTA_CHIP=esp32

./scripts/build.sh
arduino-cli board list
```

`scripts/build.sh` installs ESP32 core 3.3.12 and SimpleOTAClient 0.5.0, then compiles into `build/`. Upload that build with the same fully qualified board name the script used.

For `esp32`:

```bash
arduino-cli upload -p /dev/ttyUSB0 --input-dir build \
  --fqbn "esp32:esp32:esp32:PartitionScheme=default" \
  simpleOTA-starter-arduino
```

For any other supported chip, add `CDCOnBoot=cdc` and change the chip name. This is the S3 line:

```bash
arduino-cli upload -p /dev/ttyUSB0 --input-dir build \
  --fqbn "esp32:esp32:esp32s3:PartitionScheme=default,CDCOnBoot=cdc" \
  simpleOTA-starter-arduino
```

Replace `/dev/ttyUSB0` with the port from `arduino-cli board list`. If the board has two USB sockets, use the native USB port described in Choose the chip. On Windows the port is a `COM` port. Then open the monitor at 115200 baud, as described in Choose the chip:

```bash
arduino-cli monitor -p /dev/ttyUSB0 -c baudrate=115200
```

Press the reset button if the monitor was opened after the board had already booted. That prints the startup lines again.

### A healthy serial log

With the library debug log left off, a healthy boot from the sketch looks like this:

```text
1.0.0
[app] Wi-Fi connecting....
[app] Wi-Fi connected: 192.168.1.50
```

`1.0.0` is the `FIRMWARE_VERSION` string. The dots after `Wi-Fi connecting` keep printing, twice a second, until the board joins the network. The address on the last line is whatever DHCP gave the board. `setup()` prints that line when it connects Wi-Fi. The first update check runs on the first `loop()` pass, right after `setup()` returns, and then the sketch waits.

## GitHub secrets and variables

Pull requests, and pushes to `main`, only compile. On those runs the workflow does not read your tokens. If `secrets.h` is missing, `scripts/build.sh` copies the example header and compiles that. The run stays green.

A tag `v*` is the run that can upload. It writes `secrets.h` from repository secrets, compiles, and uploads only when both the API token and the project id are present. Tag builds take their Wi-Fi settings from the GitHub secrets `SIMPLEOTA_WIFI_SSID` and `SIMPLEOTA_WIFI_PASSWORD`. Those must match the network the board uses, or the OTA image will not reconnect.

Add the values on the repository, not in an environment: **Settings**, then **Secrets and variables**, then **Actions**. The **Secrets** tab has **New repository secret**. The **Variables** tab has **New repository variable**.

`SIMPLEOTA_PROJECT_ID` and `SIMPLEOTA_CHIP` go on the **Variables** tab. The workflow reads them with `vars`. A value saved on the **Secrets** tab is invisible to that lookup, so the workflow receives an empty string.

| Name | Kind | Required | What it does | Where you get it | Example |
| --- | --- | --- | --- | --- | --- |
| `SIMPLEOTA_WIFI_SSID` | Secret | Required on a version tag. The tag build fails if it is missing, still a placeholder, or contains a newline. | Written into `secrets.h` as `WIFI_SSID`. | Your Wi-Fi network name. | `lab-wifi` |
| `SIMPLEOTA_WIFI_PASSWORD` | Secret | Required on a version tag. The tag build fails if it is missing, still a placeholder, or contains a newline. | Written into `secrets.h` as `WIFI_PASS`. | Your Wi-Fi password. | `correct-horse` |
| `SIMPLEOTA_DEVICE_TOKEN` | Secret | Required on a version tag. The tag build fails if it is missing, still a placeholder, or contains a newline. | Written into `secrets.h` as `SOTA_TOKEN`. | The device token from **Add device**. | `soto_dev_...` |
| `SIMPLEOTA_API_TOKEN` | Secret | Required only if this tag should upload. If it is empty the build stays green and the upload is skipped. | Authorizes the release action to upload the binary and start the rollout. | **Project API tokens**, **Issue token**, with the `api` scope. | `soto_proj_...` |
| `SIMPLEOTA_PROJECT_ID` | Variable | Required only if this tag should upload. If it is empty while the API token is set, the build stays green and the upload is skipped. | Tells the release action which project to upload to. | **Project ID** under the project name. | `123e4567-e89b-12d3-a456-426614174000` |
| `SIMPLEOTA_CHIP` | Variable | Optional. Empty means `esp32`. An unsupported value fails the build. | Selects the chip for the CI compile, and the chip family sent with the upload. | One of `esp32`, `esp32s2`, `esp32s3`, `esp32c3`, `esp32c6`, `esp32h2`. | `esp32s3` |

Troubleshooting quotes the message when a tag build fails one of these checks or skips the upload, and it explains how to start that tag again.

## Cut a release

The sketch ships as version `1.0.0`. Bump `FIRMWARE_VERSION` in `simpleOTA-starter-arduino/simpleOTA-starter-arduino.ino` when you want devices to move to a new build. Leave the line in this form, with the version in quotes and nothing after it on the line:

```cpp
#define FIRMWARE_VERSION "1.0.1"
```

Commit that change, tag `v` plus the same version string, and push both the commit and the tag:

```bash
git add simpleOTA-starter-arduino/simpleOTA-starter-arduino.ino
git commit -m "Bump firmware to 1.0.1"
git tag v1.0.1
git push origin HEAD
git push origin v1.0.1
```

The tag has to match the string in the sketch exactly. `v1.0.1` matches `1.0.1`. A mismatch fails the build before compile, with a message like:

```text
Tag v1.0.1 does not match FIRMWARE_VERSION 1.0.0.
```

Watch the run on GitHub under the **Actions** tab. Open the **Firmware** workflow, then the run for the tag you pushed. The job is named **Build**. When the API token and the project id are both set, the job summary heading is `SimpleOTA release`. The table under it lists Build, Version, Security (`basic` when unsigned), and Channel (`stable` at 100%).

The file that gets uploaded is `build/simpleOTA-starter-arduino.ino.bin`, the application binary. You do not upload a file yourself.

## The over-the-air update

Open the project in SimpleOTA and switch the toggle at the top right to **Advanced**. Simple mode hides the artifact and deployment lists.

- The **Firmware artifacts** card, and the page behind it, list the build. You will see the build number SimpleOTA assigned and the version label from the sketch (`1.0.1` in the example above). The version label is for you. Update order follows the build number.
- The **Deployments** card, and the page behind it, list the rollout. This workflow starts it, on the `stable` channel, at 100%, so the state is `active`. The progress cards count check-ins. **Confirmed** counts check-ins that confirmed the new build.

The first update check runs on the first `loop()` pass, right after `setup()` connects Wi-Fi. Later passes wait `SIMPLEOTA_CHECK_INTERVAL_S` seconds. In SimpleOTAClient 0.5.0 that constant is 3600, so the gap is about an hour. Press reset after the release finishes to check right away, instead of waiting up to an hour.

The image from that tag build takes its Wi-Fi settings from `SIMPLEOTA_WIFI_SSID` and `SIMPLEOTA_WIFI_PASSWORD`. Those secrets have to match the network the board uses, or the image will not reconnect.

On the serial monitor, a successful update is quiet and then familiar. The library downloads the binary, checks its SHA-256, writes the spare app slot, and reboots. This sketch does not call `SimpleOTAClient::setDebug`, so those stages do not print their own lines. After the reboot you see the new version and the Wi-Fi lines again:

```text
1.0.1
[app] Wi-Fi connecting....
[app] Wi-Fi connected: 192.168.1.50
```

`loop()` then calls `confirmRunning()`. That call prints nothing. It marks the running image as good, and the `check()` later in that same loop reports `confirmed` to SimpleOTA. On the deployment page, open a checked-in device row and use **Timeline** to see the stages the device reported.

If the download or the SHA-256 check fails, the sketch prints this line and keeps running the firmware that was already on the board:

```text
[app] OTA failed, continuing
```

Automatic rollback: after a successful flash the new image still has to confirm. This sketch confirms at the start of `loop()`, once Wi-Fi is up. If a new image never confirms within the library's window (300 seconds from the first `check()` or `confirmRunning()` call), the board reboots into the previous firmware. The serial monitor then prints the old version string again, for example `1.0.0`, followed by the Wi-Fi lines. SimpleOTA records a `rolled_back` event. By default the deployment pauses on the first one of those, so later devices are not offered that build while you look at it.

## Troubleshooting

These are the messages the scripts and the workflow actually print.

**`Missing secret SIMPLEOTA_WIFI_SSID.`** The **Write release secrets** step prints this when that secret is empty. The same line is printed for `SIMPLEOTA_WIFI_PASSWORD` and `SIMPLEOTA_DEVICE_TOKEN`. The table above says the secret is required on a version tag. Add it on the Secrets tab. A tag that has already been pushed does not start Actions again. Delete that tag locally and on the remote, then push the same tag, or push a new tag:

```bash
git tag -d v1.0.1
git push origin --delete v1.0.1
git tag v1.0.1
git push origin v1.0.1
```

A new tag has to match `FIRMWARE_VERSION`, and the Cut a release section shows how to bump the sketch and push that tag.

**`Secret SIMPLEOTA_DEVICE_TOKEN is still a placeholder.`** The same line is printed for the Wi-Fi secrets. Replace the placeholder, as described in Add your local secrets, and then delete and push the tag with the commands above.

**`Secret SIMPLEOTA_WIFI_PASSWORD contains a newline.`** The same line is printed for the other two secrets. The table says a newline fails the tag build. Enter the secret as a single line, and then delete and push the tag with the commands above.

**`secrets.h uses a placeholder value.`** A release compile found a placeholder from `secrets.example.h` still in `secrets.h`. Replace it as described in Add your local secrets. On GitHub, that file is written from the repository secrets, so correct those and push the tag again with the commands above.

**`Release build is missing secrets.h.`** A release compile ran without that header. Copy `secrets.example.h` to `secrets.h`, as described in Add your local secrets. On GitHub the write step creates the file. Locally, you can also export the three `SIMPLEOTA_*` values and run `./scripts/secrets.sh write`.

**`FIRMWARE_VERSION was not found in the sketch.`** The version line is missing, or it is no longer a single line of the form `#define FIRMWARE_VERSION "1.0.1"`.

**`Tag v1.0.1 does not match FIRMWARE_VERSION 1.0.0.`** The tag and the sketch disagree. The common case is that you meant the new version. Set `FIRMWARE_VERSION` to match the tag, commit, and push that commit. Then delete the old tag locally and on the remote, and tag the new commit again:

```bash
git add simpleOTA-starter-arduino/simpleOTA-starter-arduino.ino
git commit -m "Bump firmware to 1.0.1"
git push origin HEAD
git tag -d v1.0.1
git push origin --delete v1.0.1
git tag v1.0.1
git push origin v1.0.1
```

If you tagged too high by mistake, delete that tag locally and on the remote, then push a tag that matches the version already in the sketch.

**`Unsupported SIMPLEOTA_CHIP 'esp32s4'. Supported chips: esp32, esp32s2, esp32s3, esp32c3, esp32c6, esp32h2.`** Set `SIMPLEOTA_CHIP` to one of the values in the table above. An empty variable means `esp32`.

**The Build job is green, and the summary says the upload was skipped.** The table rows for `SIMPLEOTA_API_TOKEN` and `SIMPLEOTA_PROJECT_ID` describe the two cases. The summaries are:

- `The SIMPLEOTA_API_TOKEN secret is not set. This tag built the firmware and did not upload it or start a rollout.`
- `SIMPLEOTA_API_TOKEN is set, but the SIMPLEOTA_PROJECT_ID repository variable is empty. The release action requires both, so nothing was uploaded.` A project id saved as a secret produces this result.

Add the missing value. A tag that has already been pushed does not start Actions again. Delete it locally and on the remote, then push the same tag, using the commands in the missing-secret note above, or push a new tag.

A successful tag run shows the job summary heading `SimpleOTA release`. The table under it lists Build, Version, Security (`basic` when unsigned), and Channel (`stable` at 100%).

**`[app] OTA failed, continuing`** The board reached `apply()` and it did not succeed. The current firmware keeps running. The usual causes are a download that stopped or a SHA-256 mismatch. The deployment timeline for that device has the reason the library reported.

**`[SimpleOTAClient] WARNING: server rejected the token (HTTP 401/403). Check your project token.`** The board did check in, and SimpleOTA refused `SOTA_TOKEN`. The wording "project token" is generic. The firmware always uses the device token (`soto_dev_`), never a `soto_proj_` API token. Check that `secrets.h` holds the `soto_dev_...` token for this board's MAC, and that a later tag was built with the same `SIMPLEOTA_DEVICE_TOKEN`.

**The serial monitor stays blank.** Set the baud rate, USB CDC On Boot, and the USB port as described in Choose the chip. Press reset after you open the monitor.

**Wi-Fi never gets past the dots.** `WIFI_SSID` or `WIFI_PASS` does not match the network. The board will not check in until that line connects. A USB flash uses `secrets.h`. A tag build uses `SIMPLEOTA_WIFI_SSID` and `SIMPLEOTA_WIFI_PASSWORD`. Fix `secrets.h`, flash over USB again, and update those GitHub secrets before the next tag.

## Help

See the [SimpleOTA documentation](https://wiki.simpleota.com/).

## License

MIT. See [LICENSE](LICENSE).
