# CylinDraw Cross-Program Update Tracker

Purpose: Track fixes proven in one program before applying to all others.

## 2026-05-14 - Proven in `CylinDrawDePixelizer`

1. Safe image-load handoff to draw thread (OpenGL/controlP5 stability)
- Issue seen: OpenGL thread violation + `ConcurrentModificationException` when selecting a new image.
- Root cause: `fileSelected(...)` callback performed `reloadImage(...)` and UI/slider updates directly (off animation thread).
- Proven fix:
  - Add a pending flag (`pendingImageLoadFromPicker`).
  - In `fileSelected(...)`, only validate/copy/set state + set pending flag.
  - In `draw()`, consume flag and run:
    - `reloadImage(filePath)`
    - threshold reset + slider updates
    - `setButtons()`
- Result: Error resolved in live test.
- Rollout status: Apply to other programs only when we reach each one.

2. Start window maximized-sized automatically
- Request: Remove need to click maximize on every launch.
- Proven fix in DePixelizer `setup()`:
  - `surface.setResizable(true);`
  - `xWindow = displayWidth;`
  - `yWindow = displayHeight;`
  - `surface.setSize(xWindow, yWindow);`
  - `surface.setLocation(0, 0);`
- Result: Opens maximized-sized on startup.
- Rollout status: Apply to other programs only after per-program verification.
