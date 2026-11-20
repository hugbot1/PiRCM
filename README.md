# PiRCM

PiRCM turns a Raspberry Pi 5 into a small, automatic payload injector for a Nintendo Switch.

The idea is simple: install PiRCM once, choose a payload, and leave the Pi running. When you connect a Switch in RCM mode, PiRCM notices the NVIDIA APX USB device and runs the selected payload for you.

PiRCM uses [fusee-nano](https://github.com/DavidBuchanan314/fusee-nano) to perform the injection. It does not implement the USB exploit itself.

## What you need

- A Raspberry Pi 5 running Raspberry Pi OS (64-bit is recommended).
- An internet connection for installation and Hekate downloads.
- A USB-A to USB-C **data** cable.
- A Nintendo Switch that is vulnerable to the RCM exploit used by Fusée Gelée. Patched consoles are not supported.
- A way to put the Switch into RCM mode, such as an appropriate jig.

Connect the Switch to one of the Pi 5's USB-A ports. Those are the Pi's USB host ports. **Do not connect the Switch to the Pi's USB-C power input.**

PiRCM detects a Switch that is already in RCM mode. It does not put the console into RCM mode for you.

## Install

On the Raspberry Pi, run:

```bash
git clone https://github.com/hugbot1/PiRCM.git
cd PiRCM
sudo ./install.sh
```

The installer prepares the PiRCM service and its dependencies, downloads and builds `fusee-nano`, then downloads the latest standard Hekate `.bin` payload from the official [Hekate releases](https://github.com/CTCaer/hekate/releases) and selects it.

The installer also includes the build fixes needed on a fresh setup: it installs `xxd` and regenerates `fusee-nano`'s generated `intermezzo.h` before compiling.

When installation finishes, PiRCM is enabled as a system service and starts automatically. You do not need to leave a terminal window open.

## Use it

1. Put the Switch into RCM mode.
2. Connect it to a USB-A port on the Raspberry Pi.
3. PiRCM watches for the APX USB device (`0955:7321`) and runs the currently selected payload.
4. Hekate should appear on the Switch if injection succeeds.

To watch what PiRCM is doing:

```bash
sudo journalctl -u pircm -f
```

The service waits for the Switch to disconnect before attempting another injection. This helps prevent it from repeatedly trying to inject while the same APX device remains connected.

## Hekate updates

Hekate is installed automatically during setup. To download the latest release and select it again later, run:

```bash
sudo pircm-update-hekate
```

The updater checks the official Hekate GitHub Releases page each time, downloads the standard `.bin` payload asset from the latest release, saves it as:

```text
/opt/pircm/payloads/hekate.bin
```

It then selects `hekate.bin` in PiRCM. You do not need to edit the configuration manually.

## Using a different payload

PiRCM can use other compatible `.bin` payloads too.

Copy a payload into the payload folder. For example, from another computer:

```bash
scp my-payload.bin YOUR_PI_USER@YOUR_PI_IP:/tmp/my-payload.bin
```

Then, on the Raspberry Pi:

```bash
sudo install -m 0644 /tmp/my-payload.bin /opt/pircm/payloads/my-payload.bin
sudo pircm-select my-payload.bin
```

To see the payloads currently in the folder:

```bash
sudo pircm-select --list
```

To switch back to Hekate:

```bash
sudo pircm-select hekate.bin
```

The selector updates the configuration and restarts the PiRCM service so the new selection takes effect.

## Useful commands

| Command | What it does |
|---|---|
| `sudo systemctl status pircm` | Shows whether the PiRCM service is running |
| `sudo journalctl -u pircm -f` | Follows the live service log |
| `sudo systemctl restart pircm` | Restarts the service |
| `sudo pircm-select --list` | Lists available `.bin` payloads |
| `sudo pircm-select filename.bin` | Selects a payload |
| `sudo pircm-update-hekate` | Downloads and selects the latest Hekate |
| `sudo pircm-doctor` | Checks the installation and current USB visibility |

## Configuration

The configuration file is:

```text
/etc/pircm/pircm.conf
```

It contains the selected payload and the service's polling/retry intervals. The default settings are:

```ini
PAYLOAD=hekate.bin
POLL_INTERVAL=1
RETRY_DELAY=3
```

- `PAYLOAD` is the filename of the selected payload inside `/opt/pircm/payloads/`.
- `POLL_INTERVAL` is how often PiRCM checks whether the APX device is connected, in seconds.
- `RETRY_DELAY` is the delay before trying again when a required payload or configuration is missing, in seconds.

After editing the file manually, restart the service:

```bash
sudo systemctl restart pircm
```

Normally, use `pircm-select` to change payloads instead of editing `PAYLOAD` yourself.

## Updating PiRCM

To get the latest project files, update your local repository and rerun the installer:

```bash
cd ~/PiRCM
git pull
sudo ./install.sh
```

The installer updates the PiRCM commands and service and rebuilds `fusee-nano`. It also checks for and selects the latest Hekate release.

## Uninstall

From the PiRCM repository directory, run:

```bash
sudo ./uninstall.sh
```

This removes the PiRCM service and installed commands while keeping your payloads and configuration.

To remove PiRCM **and** its payloads and configuration:

```bash
sudo ./uninstall.sh --purge
```

The purge option deletes `/opt/pircm` and `/etc/pircm`, including the downloaded Hekate payload.

## Troubleshooting

**The Switch is connected, but nothing happens**

- Make sure the console is actually in RCM mode.
- Check that you are using a USB-A port on the Pi 5 and a data-capable cable.
- Check whether Linux sees the APX device:

  ```bash
  lsusb -d 0955:7321
  ```

- Check the PiRCM log:

  ```bash
  sudo journalctl -u pircm -f
  ```

**Hekate or another payload is not selected**

List the payloads and select the file by its exact filename:

```bash
sudo pircm-select --list
sudo pircm-select hekate.bin
```

**The injector or a dependency is missing**

Run the diagnostic command:

```bash
sudo pircm-doctor
```

If the `fusee-nano` build or installation is incomplete, update the repository and rerun the installer:

```bash
cd ~/PiRCM
git pull
sudo ./install.sh
```

A successful `fusee-nano` process exit is useful diagnostic information, but it is not by itself proof that the Switch booted successfully. Check the console display as well as the service log.

## Current limitations

PiRCM currently runs as a background service and injects the selected payload when it detects the APX device. It does not currently include a web interface, on-device graphical menu, physical GPIO button, or status LEDs.

Fusée Gelée is a hardware bootROM vulnerability. PiRCM does not bypass patched Switch hardware, and it cannot make an unsupported console compatible.

## Project files

```text
PiRCM/
├── install.sh
├── uninstall.sh
├── config/
│   └── pircm.conf
├── payloads/
│   └── .gitkeep
├── src/
│   ├── pircm-watch
│   ├── pircm-select
│   ├── pircm-doctor
│   └── pircm-update-hekate
└── systemd/
    └── pircm.service
```

## Credits and licensing

PiRCM's original scripts are released under the MIT License. PiRCM relies on the separate [fusee-nano project](https://github.com/DavidBuchanan314/fusee-nano), which retains its own license.

Hekate is maintained by [CTCaer](https://github.com/CTCaer/hekate). PiRCM downloads the Hekate payload from its official release page; the payload is not stored in this repository.