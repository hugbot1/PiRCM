# PiRCM

A Raspberry Pi 5 RCM payload injector with automatic APX detection, a systemd service, payload selection, and a one-command installer.

**Status: early MVP (0.1.0).** The installer and service are provided; test on your Pi 5 before relying on it. The project uses the independently maintained [`fusee-nano`](https://github.com/DavidBuchanan314/fusee-nano) injector rather than reimplementing the USB protocol.

## Hardware

- Raspberry Pi 5 running Raspberry Pi OS Lite (64-bit).
- A reliable USB-A to USB-C **data** cable.
- A Switch that supports the RCM exploit (patched consoles are not supported by Fusée Gelée).
- A legally obtained `.bin` payload, such as Hekate, copied into `/opt/pircm/payloads/`.

Connect the Switch to one of the Pi 5's blue USB-A host ports. The Pi's USB-A ports are host ports; do not connect the Switch to the Pi's USB-C power input.

## Install

```bash
git clone https://github.com/YOUR-USERNAME/PiRCM.git
cd PiRCM
sudo ./install.sh
```

The installer installs build tools and `usbutils`, clones and builds `fusee-nano`, installs the PiRCM service, and enables it at boot.

## Add a payload

Copy your payload to the Pi:

```bash
scp hekate_ctcaer_x.x.x.bin YOUR_PI_USER@YOUR_PI_IP:/tmp/hekate.bin
sudo install -m 0644 /tmp/hekate.bin /opt/pircm/payloads/hekate.bin
sudo chown -R root:root /opt/pircm/payloads
```

Set it as the selected payload:

```bash
sudo pircm-select hekate.bin
```

The selected filename is stored in `/etc/pircm/pircm.conf`.

## Use

1. Put the Switch into RCM mode.
2. Connect it to a Pi 5 USB-A port with the data cable.
3. PiRCM detects USB VID:PID `0955:7321` and invokes `fusee-nano` with the selected payload.
4. Check the log:

```bash
sudo journalctl -u pircm -f
```

Useful commands:

```bash
sudo systemctl status pircm
sudo systemctl restart pircm
sudo pircm-select --list
sudo pircm-doctor
```

## Configuration

Edit `/etc/pircm/pircm.conf`:

```ini
PAYLOAD=hekate.bin
POLL_INTERVAL=1
RETRY_DELAY=3
```

Then restart:

```bash
sudo systemctl restart pircm
```

## Uninstall

```bash
sudo ./uninstall.sh
```

The uninstall script leaves `/opt/pircm/payloads` in place unless you explicitly pass `--purge`.

## Notes and limitations

- This is software for a Linux USB **host**. The Pi 5's USB-A ports provide host connectivity; a Pi Zero or other board may require different OTG/power arrangements.
- The project does not include copyrighted or third-party payload binaries. Supply your own payload.
- Fusée Gelée is a bootROM vulnerability and only works on vulnerable, unpatched original Switch units. It does not bypass patched hardware.
- The current MVP automatically injects when APX is detected. A GPIO trigger, web dashboard, LED indicators, and multi-payload menu are planned follow-ups, not implemented in 0.1.0.
- `fusee-nano` is a third-party project. Review its source and license before use. PiRCM downloads it from its upstream repository during installation.
- This has not been physically tested on every Pi 5 / Raspberry Pi OS release. The doctor command checks prerequisites and USB visibility, but cannot guarantee a successful injection.

## Project layout

```text
PiRCM/
├── install.sh
├── uninstall.sh
├── src/
│   ├── pircm-watch
│   ├── pircm-select
│   └── pircm-doctor
├── systemd/pircm.service
├── config/pircm.conf
└── payloads/.gitkeep
```

## License

PiRCM's original scripts are MIT licensed. `fusee-nano` remains under its own upstream license.
