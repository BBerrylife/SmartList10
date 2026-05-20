# SmartList10 for BlackBerry 10
 
A native checklist / task-list manager built with the BlackBerry 10 Cascades framework (QML + C++). SmartList10 is designed around the BB10 Active Frame experience, letting you browse and check off items without ever fully opening the app.
 
---
 
## Features
 
### Core List Management
- Create and organise **multiple lists** across **custom categories**, each displayed as its own sidebar tab.
- Add, rename, and delete lists and categories.
- Check/uncheck items directly from either the full app or the Active Frame cover.
- **Alphabetical grouping headers** (optional) for long lists — auto-inserts letter/`#` separators when a list exceeds 8 items.
- **Item scaling** — adjust item size for readability.
### SmartFrame (Active Cover)
SmartList10 is built around a rich Active Frame that stays useful while the app is minimised:
 
- Displays the active list name, item count, and a scrollable item view with done/total progress.
- Highlighted **selected item** that can be toggled (checked/unchecked) without opening the app.
- Scroll the item list and toggle items using **physical hardware buttons** or **tilt gestures** (accelerometer), configured via three scroll modes:
  | Mode | Up/Down | Toggle |
  |------|---------|--------|
  | 0 – Tilt (default) | Tilt device | Volume Up long-press |
  | 1 – Volume Keys | Vol Up / Vol Down short-press | Mute/Play-Pause short-press |
### Accelerometer Tilt Scrolling
- Uses the device accelerometer to scroll the cover list by tilting the phone forward/backward.
- Includes a **cooldown** mechanism to prevent accidental double-scrolls when setting the device down.
- **Configurable scroll speed** (0.1 – 5×).
- Automatically starts/stops the sensor when the app is thumbnailed or restored.
### Settings
All settings are persisted in an SQLite database (`appdata` table):
 
| Setting | Description |
|---------|-------------|
| Dark / Bright theme | Applied at launch before the UI loads |
| Use SmartFrame | Enable/disable the Active Frame cover |
| Show SmartFrame info | Show extra debug info on the cover |
| Use headers in lists | Alphabetical group headers in long lists |
| Scroll mode | Tilt (0) or Volume keys (1) |
| Scroll speed | Multiplier for tilt scroll cooldown |
| Item scale | Cover item text size multiplier |
| Large items | Bigger row height in the main list |
 
### Sharing
- **Share text** via the BB10 invocation framework — opens a picker of all installed share targets (BBM, SMS, email, Remember, Bluetooth, NFC, third-party apps).
- Targets are sorted: BBM → BBM Groups → BBM Channels → SMS → Email → Calendar → Connectivity → Remember → Other native → Third-party.
- **Send feedback** directly from the app menu via email to the developer.
