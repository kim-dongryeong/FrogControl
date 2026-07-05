<div align="center">

<img src="frog-icon.png" width="96" height="96" alt="FrogControl frog icon">

# FrogControl

### Turn **CapsLock** into a window-management superpower for Windows.

Move, resize, snap, arrange, and navigate windows — plus control your mouse, volume, and clipboard-free date input — all without leaving the home row.

[![Version](https://img.shields.io/badge/version-2.1.0-4c9a4c)](history.txt)
[![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v1.1-334455)](https://www.autohotkey.com/)
[![Platform](https://img.shields.io/badge/platform-Windows-0078d6)](#requirements)
[![License](https://img.shields.io/badge/license-Free%20%26%20Open%20Source-brightgreen)](#license)

> [ GIF: CapsLock + drag a window into a corner → it snaps to a quarter of the screen ]

</div>

---

## Why FrogControl?

Windows already lets you drag windows around. FrogControl makes it *effortless*: grab **any** window from **anywhere inside it** while holding CapsLock, and it moves. Flick it to an edge and it snaps. Right-drag to resize from whichever corner you grabbed. Tap CapsLock a few extra times and your mouse wheel scrolls faster. Press `Shift+F3` and every window of the current app fans out across the screen so you can see them all at once.

It's a single AutoHotkey script — tiny, free, open source, no installer, no background bloat. It just sits in your tray and gives your keyboard and mouse new powers.

**The core idea:** CapsLock stops being a near-useless key and becomes a **modifier hub**. Hold it, and the whole keyboard turns into window/mouse controls. Let go, and everything is normal. (A quick tap still toggles CapsLock the usual way.)

---

## Highlights

### 🪟 Move & snap any window with the mouse
Hold **CapsLock** and left-drag anywhere inside a window to move it — no need to aim for the title bar. Drag toward an edge or corner to snap it to a half or quarter of the screen (Aero-Snap style, but from any grab point). Right-drag to **resize** from the nearest corner or edge.

> [ GIF: CapsLock + left-drag moving a window from its center; then snapping to the left half ]

### 🧲 Pixel-perfect snapping (no gaps)
On Windows 10/11, windows have invisible borders that leave ugly 7–14 px gaps when you snap them side by side. FrogControl measures each window's *visible* frame and compensates, so snapped and gridded windows sit **flush**.

> [ GIF: two windows snapped side by side with no gap between them ]

### 🗂️ Arrange all windows of an app at once
`Shift+F1`/`F2` fan out or grid **all File Explorer** windows. `Shift+F3`/`F4` do the same for **every window of whatever app is active** — great for comparing a dozen browser or editor windows in one keystroke.

> [ GIF: pressing Shift+F4 and watching many windows arrange into a grid ]

### 🖱️ Faster mouse wheel — by tapping CapsLock
`CapsLock + Wheel` scrolls faster. Tap CapsLock **twice** before scrolling for level 2, three times for level 3, and so on. `CapsLock + \`` gives you ultra-precise one-line-at-a-time scrolling.

> [ GIF: scroll speeding up as CapsLock is tapped more times ]

### ⌨️ Keyboard-driven window & mouse control
Move windows with `CapsLock + Win + Arrows`, resize with `Win + Alt + Arrows`, or drop a window into an *n×n* grid with `CapsLock + Ctrl + Arrows` (tap Ctrl more times for a finer grid). Enter **Mouse Control Mode** (`CapsLock + M`) to drive the cursor entirely from the keyboard, including a pixel ruler and a constrain-to-axis mode.

> [ GIF: CapsLock+Ctrl+Arrows dropping a window into a 3×3 grid ]

### 🔊 Volume, transparency, always-on-top, window rotation
- `Win + Wheel` — adjust volume (`Win + Ctrl + Wheel` for fine steps)
- `Win + Alt + Wheel` — window transparency
- `Win + A` (or `Win + Click`) — toggle always-on-top
- `Ctrl + Alt + Wheel` — flip through your windows like a card deck

### 📌 Mouse & window bookmarks · 📅 date input mode
Bookmark cursor positions (`CapsLock + Ctrl + 1…0`) and jump/click them later. Bookmark windows to function keys (`CapsLock + Ctrl + F1…F9`). Type today's date in any format without touching the number row (`CapsLock + O`).

*(Every shortcut is listed in the [full reference](#full-shortcut-reference) below.)*

---

## Requirements

- **Windows** (10 / 11 recommended; works on older versions too)
- **[AutoHotkey v1.1](https://www.autohotkey.com/)** — FrogControl uses AutoHotkey **v1** syntax and does **not** run on AutoHotkey v2.

## Install & run

1. Install [AutoHotkey v1.1](https://www.autohotkey.com/).
2. Download this repository (green **Code → Download ZIP**, or `git clone`).
3. Keep these together in one folder:
   ```
   FrogControl.ahk
   lib\                     (all the helper modules)
   shortcut list-en.txt
   shortcut list-ko.txt
   frog face icon 3.ico
   ```
4. Double-click **`FrogControl.ahk`**. A frog icon appears in your system tray. That's it.

**Run at startup:** press `Win + R`, type `shell:startup`, and drop a shortcut to `FrogControl.ahk` into that folder.

**Tray menu:** right-click the frog icon for **Disable/Enable**, **About** (English/한국어), **Reload** (re-apply after editing the script), and **Exit**. Running `FrogControl.ahk` again also just replaces the running instance.

> [ Screenshot: the tray icon and its right-click menu ]

---

## Full shortcut reference

The complete, always-up-to-date list ships with the app and is shown in the in-app help (`CapsLock + ?` or tray → About): [`shortcut list-en.txt`](shortcut%20list-en.txt) · [한국어: `shortcut list-ko.txt`](shortcut%20list-ko.txt).

<details>
<summary><b>Move &amp; resize windows with the mouse</b></summary>

| Shortcut | Action |
| --- | --- |
| `CapsLock + Click-drag` | Move window (drag to a corner/edge to snap to half/quarter). `Ctrl` to also focus it, `Esc` to cancel |
| `CapsLock + Shift + Click-drag` | Move window strictly horizontally or vertically |
| `CapsLock + Ctrl + Click` | Activate the window under the cursor without moving it |
| `CapsLock + Right-click-drag` | Resize window from the nearest corner/edge (`Ctrl` to focus, `Esc` to cancel) |

</details>

<details>
<summary><b>Move &amp; resize windows with the keyboard</b></summary>

| Shortcut | Action |
| --- | --- |
| `CapsLock + Win + Arrows` | Move window |
| `CapsLock + Shift + Arrows` | Move window to the screen edge |
| `CapsLock + Ctrl + Arrows` | Resize to ½ and move in a 2×2 grid |
| `CapsLock + Ctrl + Ctrl + Arrows` | Resize to ⅓ and move in a 3×3 grid (tap Ctrl *n* times → *n×n*) |
| `Win + Alt + Arrows` | Resize window outward (bigger) |
| `Win + Alt + X + Arrows` | Resize window inward (smaller) |
| `Win + Alt + Shift + Arrows` | Resize a window side to the screen edge |

</details>

<details>
<summary><b>Arrange windows</b></summary>

| Shortcut | Action |
| --- | --- |
| `Shift + F1` | Fan out all File Explorer windows |
| `Shift + F2` | Arrange all File Explorer windows in a grid |
| `Shift + F3` | Fan out all windows of the same type as the active one |
| `Shift + F4` | Arrange all windows of the same type in a grid |

</details>

<details>
<summary><b>Mouse wheel &amp; volume</b></summary>

| Shortcut | Action |
| --- | --- |
| `CapsLock + Wheel` | Scroll faster (tap CapsLock *n* times first → level *n*) |
| `CapsLock + \` + Wheel` | Ultra-slow, one line at a time |
| `Win + Wheel` | Adjust volume |
| `Win + Ctrl + Wheel` | Adjust volume in fine steps |
| `Win + [` / `]` | Adjust volume |

</details>

<details>
<summary><b>Operate windows</b></summary>

| Shortcut | Action |
| --- | --- |
| `Ctrl + Shift + Right-click` | Close a tab (like `Ctrl + W`) |
| `Ctrl + Shift + Alt + Right-click` | Close a window (like `Alt + F4`) |
| `Win + Ctrl + Shift + Alt + Right-click` | Close the window under the mouse |
| `Alt + Right-click` | Minimize a window |
| `Alt + Shift + Right-click` | Send a window to the bottom of the stack |
| `Ctrl + Shift + Wheel` | Move to the next/previous tab (Page Up/Down) |

</details>

<details>
<summary><b>Transparency &amp; always-on-top</b></summary>

| Shortcut | Action |
| --- | --- |
| `Win + A` | Toggle always-on-top |
| `Win + Click` | Toggle always-on-top for the window under the cursor |
| `Win + Alt + Wheel` | Adjust window transparency |
| `Win + Alt + [` / `]` | Adjust window transparency |

</details>

<details>
<summary><b>Window navigation</b></summary>

| Shortcut | Action |
| --- | --- |
| `Ctrl + Alt + Wheel` (or `[` / `]`) | Rotate through windows (while stacking) |
| `Ctrl + Alt + Win + Wheel` (or `[` / `]`) | Rotate through windows (without stacking) |
| `Shift + Alt + Win + Wheel` (or `[` / `]`) | Rotate through windows of the same application |
| `Alt (+ Shift) + \`` | Rotate through windows of the same application |
| `Ctrl + Alt + Win + Arrows` | Navigate to the nearest window in that direction |

</details>

<details>
<summary><b>Mouse Control Mode &amp; clicks</b> — <code>CapsLock + M</code></summary>

Inside Mouse Control Mode:

| Key | Action |
| --- | --- |
| *number* + Arrow | Move the cursor that many pixels in that direction |
| `CapsLock + Arrow` | Drive the cursor (hold Alt/Shift/Ctrl to change speed) |
| `+` | Constrain movement to one axis |
| `R` | Ruler mode (SpaceBar sets the reference point) |
| `W` | Move cursor to the center of the current window |
| `C` | Show current coordinates · `?` help · `Esc` quit |

Direct mouse actions (any time):

| Shortcut | Action |
| --- | --- |
| `CapsLock + Z` / `C` / `X` | Left / Right / Middle click |
| `CapsLock + W` / `S` / `A` / `D` | Wheel up / down / left / right |
| `CapsLock + R` | Move cursor to the center of the active window |
| `CapsLock + E` | Move the active window to the cursor |

</details>

<details>
<summary><b>Bookmarks &amp; date input</b></summary>

| Shortcut | Action |
| --- | --- |
| `CapsLock + Ctrl + 1…0` | Bookmark the current cursor position |
| `CapsLock + 1…0` | Click at that mouse bookmark |
| `CapsLock + Shift + 1…0` | Move cursor to that bookmark (no click) |
| `CapsLock + Ctrl + F1…F9` | Save the current window to a bookmark |
| `CapsLock + F1…F9` | Activate that window bookmark |
| `CapsLock + F10` | List all window bookmarks |
| `CapsLock + O` | Date & time input mode (type any date format without the number row) |

</details>

<details>
<summary><b>Menu &amp; advanced</b></summary>

| Shortcut | Action |
| --- | --- |
| `CapsLock + ?` | Open the FrogControl help |
| `CapsLock + F12` | Disable / enable FrogControl |
| `Win + Ctrl + L` | Show the list of Alt-Tab-able programs |
| `Win + Shift + F1` | Make the pixel color under the cursor transparent in the window |
| `Win + Shift + F2` / `F3` | Remove the title bar and borders |

</details>

---

## Good to know

- **Multi-monitor aware.** Snapping, grids, and edge moves all respect the monitor a window is actually on, including secondary monitors at negative coordinates and mixed resolutions.
- **CapsLock still works normally.** A plain tap toggles CapsLock as usual; it only becomes a modifier while held together with another key.
- **Nothing is installed.** It's a portable script. Delete the folder and it's gone.
- **Under the hood (v2.1.0):** the code was fully audited, de-duplicated, and split into `lib/` modules, with performance passes on the hot paths (wheel scroll, drag loops) and DWM-aware snapping throughout. See [`history.txt`](history.txt) for the changelog.

## Project status & roadmap

FrogControl has been evolving since 2015. The current focus is polishing the AutoHotkey edition and growing the community around it. Longer term, the accumulated window-management logic is intended as the blueprint for a native Windows app.

Ideas, bug reports, and feedback are very welcome — please [open an issue](https://github.com/kim-dongryeong/FrogControl/issues).

## Contributing

1. Fork and clone the repo.
2. Edit `FrogControl.ahk` (hotkeys) or the modules in `lib/` (functions).
3. Test with AutoHotkey v1.1 — the tray **Reload** item re-applies your changes instantly.
4. Open a pull request describing what changed and why.

## License

FrogControl is **free and open source**. You may use and distribute it on any computer, including in a commercial organization — no registration, no payment required.

> [ Optional: add a formal LICENSE file (e.g. MIT) to make reuse terms unambiguous. ]

## Author

Created by **Kim Dongryeong** · [github.com/kim-dongryeong/FrogControl](https://github.com/kim-dongryeong/FrogControl)

If FrogControl makes your day a little smoother, a ⭐ on the repo helps others find it.
