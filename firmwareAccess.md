# Firmware Access Context (To Be Filled)

Purpose: capture firmware-side details needed to debug RunMode connection handshake.

## Required Inputs Next Session
- Firmware source location/path(s):
  - TODO
- Board/controller type:
  - TODO
- Serial baud rate expected by firmware:
  - Current RunMode uses `40000`.
- Expected startup handshake string/token(s):
  - TODO
- Expected terminator/delimiter for messages:
  - RunMode currently buffers until `';'`.
- Any required wake/init command from host before firmware replies:
  - TODO

## Why This Matters
Current evidence shows USB port probing works and the machine beeps, but RunMode does not transition to connected state. That usually means handshake proof parsing mismatch, not physical transport failure.

## Attach Here
Paste or link:
- Firmware serial receive/transmit functions
- Startup/ready message strings
- Command parser delimiters and ack format

/home/pi/IchorGAT/CylinDrawForLinux/cylindrawFirmwayeV2.01