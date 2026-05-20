# CylinDraw Linux Recovery Context (Session Handoff)

Purpose: persistent context for future sessions so work can resume quickly without re-discovery.

## Project Goal
Restore full functional parity of the CylinDraw Control Suite on Linux.
Historical state: this suite worked on Windows; Linux port has mostly small platform/launch/threading issues rather than major algorithmic defects.

## Programs and Roles
- `CylinDrawDePixelizer`: bitmap image -> sliced/vector-ish prep output for downstream tooling.
- `CylinDrawJobCreator` (Creation Mode): edit/prepare/arrange `.svg` jobs and export machine-ready `.JOB.svg`.
- `CylinDrawRunMode`: machine connection, serial control, job streaming, calibration/test controls.
- `CylinDrawViewer`: view `.JOB.svg` paths/details.

## Current Status (as of 2026-05-19)
- DePixelizer: functional and stable.
- Viewer: functional and stable; Exit button issue fixed.
- RunMode: app launches and cross-app switching logic updated for Linux, but hardware connection is blocked by handshake/serial response detection issue.
- JobCreator: functional in a usable fixed-size window; resize/maximize behavior is constrained by JOGL/X11 behavior on this environment.

## High-Value Findings (Linux)
1. JOGL/X11 window operations are fragile in `P3D` apps.
- Problematic calls in this environment can deadlock or destabilize rendering:
  - `surface.setLocation(...)`
  - `surface.setResizable(true)` (in some apps)
  - draw-time `surface.setSize(...)`/maximize attempts
- Symptoms seen: black/white window, `handleDraw() called before finishing`, JOGL lock timeout stack traces.
- Practical rule: avoid runtime window-manager calls in `P3D` unless proven safe per app.

2. DePixelizer image-load crash fixed.
- Root cause: callback thread executed heavy reload/UI operations.
- Fix pattern: callback sets state only; `draw()` consumes pending flag and performs reload/UI updates on animation thread.

3. Cross-app launching from exported executables was Windows-specific and broken.
- Old behavior used `.exe` + `launch("cd ... && App.exe")`.
- Linux-safe helper added in source:
  - derives sibling app path from `sketchPath()`
  - launches via `/bin/bash -lc 'cd "<target>" && ./<AppName>'`
- Source files updated:
  - `CylinDrawDePixelizer.pde`
  - `CylinDrawJobCreator.pde`
  - `CylinDrawRunMode.pde`

4. RunMode `Serial` type ambiguity fixed.
- Explicitly uses `processing.serial.Serial` for variable, constructor, list usage, and serial callback signature.

5. Git packaging/push blocker solved.
- Exported app payloads were too large for GitHub push.
- `.gitignore` now ignores:
  - `ExecutableCylinDrawForLinux64/`
- Large-file history was rewritten to remove tracked exported binaries.

## RunMode Hardware Blocker (Current)
Observed behavior with known-good machine hardware:
- Automatic connect cycles expected Linux ports (e.g., `ttyUSB0`, `ttyACM0`, `ttyACM1`) correctly.
- CylinDraw hardware emits beep response when ports are probed.
- UI still reports `No response on port ...` and does not mark connected.

Interpretation:
- Port discovery is working.
- Connection-state proof/handshake parsing likely failing (timing, delimiter, expected token, or buffer handling), not gross USB detection.
- Most likely a small protocol/handshake logic issue.

## RunMode Serial Notes Already Applied
- Default hardcoded `/dev/ttyUSB0` removed; `portName` defaults to `null` (auto select path).
- Auto-scan loop corrected to wrap across all ports (no partial random-start tail scan).
- Auto mode now prefers Linux-style serial device names (`ttyUSB*`, `ttyACM*`) before trying open.

## JobCreator Window Findings
- Startup display dimensions initially reported portrait (`800x1280`) then settle landscape (`1280x800`) later.
- Orientation-safe sizing in `settings()` now uses:
  - width = `max(displayWidth, displayHeight)`
  - height = `min(displayWidth, displayHeight)`
- Current result is usable and intentionally fixed-size to avoid JOGL/X11 resize deadlocks.

## Next Session Suggested Starting Plan
1. Focus only on RunMode serial handshake proof path.
2. Instrument (light logging) at:
- port open success path
- initial write after open
- `serialEvent(...)` receive raw payload + delimiter behavior
- state changes for `bConnected`, `bProvenConnection`, `bOKtoSend`
3. Confirm exact expected handshake token from firmware and compare with parsed incoming text.
4. Adjust timing (`delay`/first write) and/or delimiter (`bufferUntil`) only as needed.

## Files of Interest
- `/home/pi/IchorGAT/CylinDrawForLinux/CylinDrawRunMode/CylinDrawRunMode.pde`
- `/home/pi/IchorGAT/CylinDrawForLinux/CylinDrawJobCreator/CylinDrawJobCreator.pde`
- `/home/pi/IchorGAT/CylinDrawForLinux/CylinDrawDePixelizer/CylinDrawDePixelizer.pde`
- `/home/pi/IchorGAT/CylinDrawForLinux/CylinDrawViewer/CylinDrawViewer.pde`

## Notes
- Keep edits in source `.pde` files; `ExecutableCylinDrawForLinux64` is build output only.
- Re-export apps after source changes.
