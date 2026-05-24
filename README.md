# SmartList10 for BlackBerry 10

Native checklist/task manager for BB10, built with Cascades (QML + C++). The main draw is the **Active Frame** — browse and tick items straight from the cover without opening the app.

---

## List Management

- Multiple lists organised into **custom categories** — each category gets its own sidebar tab.
- Add, rename, delete lists and categories freely.
- Check/uncheck items from the app or directly from the Active Frame.
- **Alphabetical group headers** (optional) — auto-inserts A/B/C... or `#` separators when a list exceeds 8 items.
- **Item scaling** — adjust text size for readability.

---

## SmartFrame (Active Cover)

The core of the app. While minimised:

- Shows the list name, item count, a scrollable item view, and done/total progress.
- The selected item is highlighted and can be toggled without opening the app.
- Navigate with **hardware buttons** or **device tilt** (accelerometer), depending on scroll mode:

| Mode | Up/Down | Toggle |
|------|---------|--------|
| 0 – Tilt (default) | Tilt device | Long-press Volume Up |
| 1 – Volume Keys | Vol Up / Vol Down | Mute or Play/Pause |

---

## Tilt Scrolling (Accelerometer)

- Tilt the phone forward/backward to scroll the cover list.
- Built-in **cooldown** prevents accidental double-scrolls when setting the device down.
- Scroll speed is configurable (0.1× – 5×).
- Sensor starts/stops automatically when the app is thumbnailed or restored.

---

## Settings

Everything persisted in SQLite (`appdata` table):

| Setting | Description |
|---------|-------------|
| Dark / Bright theme | Applied before the UI loads |
| Use SmartFrame | Enable/disable the Active Frame cover |
| Show SmartFrame info | Extra debug info on the cover |
| Use headers in lists | Alphabetical group headers for long lists |
| Scroll mode | Tilt (0) or Volume keys (1) |
| Scroll speed | Multiplier for tilt scroll cooldown |
| Item scale | Cover item text size multiplier |
| Large items | Bigger row height in the main list |

---

## Sharing

- **Share text** via the BB10 invocation framework — opens a picker of all installed share targets (BBM, SMS, email, Remember, Bluetooth, NFC, third-party apps).
- Sort order: BBM → BBM Groups → BBM Channels → SMS → Email → Calendar → Connectivity → Remember → Other native → Third-party.
- **Send feedback** from the app menu directly to the developer via email.
