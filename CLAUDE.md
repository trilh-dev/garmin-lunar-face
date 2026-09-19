# Lunar Calendar Face (Forerunner 955 Solar)

Fork of github.com/chienbinhso13/garmin-fr55-watch-face-with-lunar-calendar, retargeted from `fr55` to `fr955`.
Upstream has **no license** — personal use only; public publishing/selling needs the author's permission.

## Build
- SDK: `~/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2` (only `fr955` device installed).
- SDK Manager "Device Updates" is set to **Notify Me** — on Automatic it downloads every device.
- Simulator build: `"$SDK/bin/monkeyc" -d fr955 -f monkey.jungle -o bin/LunarFace.prg -y developer_key.der`
- Run: `"$SDK/bin/connectiq" &` then `"$SDK/bin/monkeydo" bin/LunarFace.prg fr955`
- Release package: `"$SDK/bin/monkeyc" -e -r -f monkey.jungle -o LunarFace.iq -y developer_key.der`
- Simulator persists settings: delete `$TMPDIR/com.garmin.connectiq/GARMIN/APPS/SETTINGS/LUNARFACE.SET` to pick up new property defaults.

## Signing
- `developer_key.der` / `.pem` in repo root (gitignored). Every beta update must be signed with this same key — keep a backup.

## Distribution (private beta, no USB — installs via Connect IQ phone app)
- App ID (manifest): `3113cf9f-e5d9-4da8-92e6-c5f3c2917e85` (replaced upstream's ID).
- Beta store page: https://apps.garmin.com/apps/b4612af5-be1b-49b7-895c-304279edec5f — developer display name `LeHuuTri`.
- Update flow: bump `version` in `manifest.xml` → export `.iq` → "Upload New Version" on the store page.
- Current version on store: 1.0.2. A beta can't become public; publishing needs a new app ID.
- Store form is React: `fill` doesn't always register in text fields — type text with real key events. Display names can't contain spaces.

## Features added on top of upstream
- Temperature (°C/°F per device setting) + humidity next to the weather icon; `--` when no weather data.
- Background photo setting (`resources/settings/`): Black or 4 bundled Unsplash photos (`resources/drawables/bg1-4.png`, pre-darkened to 50% and dithered to the 64-color MIP palette). Default = 2. Credits in `store/PHOTO_CREDITS.md`.
- Watch faces can't load photos from the phone at runtime; new photos must be bundled and re-uploaded.
- Removed upstream's decorative chevrons; heart rate now sits there (left of seconds). Top row = Bluetooth, battery, weather.
- Pulse Ox: latest reading from `SensorHistory.getOxygenSaturationHistory` (needs `SensorHistory` permission), refreshed once a minute, drawn bottom-center. Shows `SpO2 --` without readings.
- Not possible via Connect IQ on the 955: body/skin temperature (no sensor), CO2 (no Garmin sensor), HRV status (not exposed). Stress / Body Battery are available if wanted.

## Known issues
- Photo #1 (blue neon) sits behind the time; #4 makes the red lunar date hard to read.
- Seconds freeze in low-power mode (no `onPartialUpdate`).
- Weather icons cover only sun/cloud/rain.
