# CylinDraw For Linux

Linux working copy of the CylinDraw control suite for a cylindrical CNC plotter.

This repo contains the Processing desktop tools and the Arduino Nano firmware needed to prepare, view, and stream CylinDraw jobs on Raspberry Pi / Linux.

## Current Working State

As of 2026-05-20, there are no known remaining functional blockers in this Raspberry Pi setup.

- `CylinDrawDePixelizer`: working.
- `CylinDrawJobCreator`: working in a fixed-size Linux window.
- `CylinDrawViewer`: working.
- `CylinDrawRunMode`: working with the attached Arduino Nano after switching serial to `38400` baud.
- Firmware: `cylindrawFirmwayeV3.1` compiles for Arduino Nano and communicates with RunMode at `38400` baud.

## Main Programs

- `CylinDrawDePixelizer/`: converts bitmap images into prep output for downstream job creation.
- `CylinDrawJobCreator/`: prepares and exports machine-ready `.JOB.svg` files.
- `CylinDrawViewer/`: views generated `.JOB.svg` paths.
- `CylinDrawRunMode/`: connects to the machine, streams jobs, and provides machine controls.
- `cylindrawFirmwayeV3.1/`: Arduino Nano firmware for the plotter controller.

## Hardware

The current tested controller is an Arduino Nano.

Firmware path:

```bash
/home/pi/IchorGAT/CylinDrawForLinux/cylindrawFirmwayeV3.1/cylindrawFirmwayeV3.1.ino
```

Important firmware details:

- Board: Arduino Nano.
- Serial baud: `38400`.
- Firmware libraries: `Servo.h`, `SpeedyStepper.h`.
- T axis uses the X stepper pins.
- H axis uses the Y stepper pins.
- Servo Z axis is on digital pin `11`.
- End stop is on digital pin `10` with `INPUT_PULLUP`.
- Stepper enable is on digital pin `8`; logic high disables motors.

## Arduino Setup On Raspberry Pi

Arduino IDE 2.x does not currently provide an official Linux ARM64 Raspberry Pi build. The workable setup used here is:

- Arduino IDE `1.8.13` from Debian/Raspberry Pi repos for the graphical editor.
- Official `arduino-cli 1.5.0` ARM64 package for reliable board/library management and compiling.

Install the classic IDE:

```bash
sudo apt update
sudo apt install arduino
```

Install required CLI libraries:

```bash
arduino-cli lib install SpeedyStepper
```

`Servo` is provided by the Arduino AVR platform/library set. In this working setup both libraries are present under:

```bash
/home/pi/Arduino/libraries
```

Linux note: the installed `SpeedyStepper` library may include `#include <arduino.h>`. On Linux this must be corrected to:

```cpp
#include <Arduino.h>
```

The patched file is:

```bash
/home/pi/Arduino/libraries/SpeedyStepper/src/SpeedyStepper.h
```

## Compile Firmware

For a standard Arduino Nano:

```bash
arduino-cli compile --fqbn arduino:avr:nano /home/pi/IchorGAT/CylinDrawForLinux/cylindrawFirmwayeV3.1
```

Known-good compile result:

```text
Sketch uses 15532 bytes (50%) of program storage space.
Global variables use 835 bytes (40%) of dynamic memory.
```

## Upload Firmware

Check connected boards/ports:

```bash
arduino-cli board list
```

Upload to the Nano, replacing the port if needed:

```bash
arduino-cli upload -p /dev/ttyUSB0 --fqbn arduino:avr:nano /home/pi/IchorGAT/CylinDrawForLinux/cylindrawFirmwayeV3.1
```

If upload fails with a bootloader sync error, try the old Nano bootloader:

```bash
arduino-cli upload -p /dev/ttyUSB0 --fqbn arduino:avr:nano:cpu=atmega328old /home/pi/IchorGAT/CylinDrawForLinux/cylindrawFirmwayeV3.1
```

If serial ports are not accessible, add the user to `dialout` and then log out/back in or reboot:

```bash
sudo usermod -aG dialout pi
```

## Serial Protocol Notes

The Linux RunMode source and firmware must agree on baud rate.

Current working source values:

- Firmware: `Serial.begin(38400)`.
- RunMode: `iSerialBaud = 38400`.

The old exported executable source copy may still show `40000`; treat exported app directories as build output and re-export after changing source `.pde` files.

RunMode buffers firmware responses until `;`. The firmware startup message includes:

```text
~Machine Connected! FW Revision = V3.1
```

The previous connection blocker was caused by serial/handshake mismatch behavior rather than a gross USB detection failure. Switching to a standard baud rate fixed communication with the attached Nano.

## Linux Processing Notes

The Processing apps run on Linux, but JOGL/X11 window behavior can be fragile in `P3D`.

Practical lessons:

- Avoid runtime window-manager calls in `P3D` unless tested in the target environment.
- Calls such as `surface.setLocation(...)`, some uses of `surface.setResizable(true)`, and draw-time resize/maximize logic can destabilize rendering on this Pi.
- Keep edits in source `.pde` files, then re-export apps as needed.
- Treat `ExecutableCylinDrawForLinux64/` as generated build output.

## Repo Notes

The project source lives at:

```bash
/home/pi/IchorGAT/CylinDrawForLinux
```

Original public repository:

```text
https://github.com/mechengineermike/CylindrawForLinux.git
```

Large exported app payloads should not be committed. The exported app directory is ignored by `.gitignore`.

