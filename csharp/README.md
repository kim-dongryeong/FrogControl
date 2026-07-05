# FrogControl — C# (.NET) native port

A faithful, dependency-light C# rewrite of the AutoHotkey FrogControl script as a **native
Windows tray application** (.NET 8, WinForms). Every hotkey in the AHK build is reproduced
here through global low-level hooks and the Win32 window-management API — no AutoHotkey runtime
required.

> This is a parallel implementation living under `csharp/`. The original `FrogControl.ahk` at
> the repo root is untouched and still authoritative for behaviour; this port mirrors it.

---

## Quick start

**Requirements to build:** [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
(the `net8.0-windows` desktop workload). Verify with `dotnet --version` (>= 8.0).

```powershell
cd csharp
./build.ps1            # build Release and launch it
./build.ps1 -NoRun     # build only
```

A frog icon appears in the tray. Right-click it for **About (English/Korean)** help windows,
**Enable/Disable**, **Reload**, and **Exit**. Double-click opens help.

### Make a standalone .exe (no .NET needed on the target machine)

```powershell
cd csharp
./publish.ps1             # self-contained single-file exe (zero-dependency, ~70-150 MB)
./publish.ps1 -Framework  # small single-file exe; needs the .NET 8 Desktop Runtime installed
./publish.ps1 -Folder     # offline-safe folder publish; needs the .NET 8 Desktop Runtime
```

The single-file variants download the `win-x64` runtime packs from NuGet **the first time**
(needs internet once). The `-Folder` variant is fully offline. Output lands under
`FrogControl/bin/Release/...`. Keep `frog face icon 3.ico`, `shortcut list-en.txt`, and
`shortcut list-ko.txt` next to the exe (the publish step copies them automatically).

---

## Why low-level hooks (the one real technology decision)

FrogControl uses **CapsLock as a prefix key** (CapsLock + almost everything) and taps modifiers
"N times" to change speeds. That is only possible with a global **`WH_KEYBOARD_LL` / `WH_MOUSE_LL`**
hook that can *suppress* CapsLock and observe physical key state — exactly what AutoHotkey does
internally, and exactly what `RegisterHotKey` **cannot** do. So the hook layer is raw Win32
P/Invoke; there was no viable "option B" here. Everything else (tray, help window, tooltips) is
WinForms because that is the natural fit for a tray app.

Where there *were* genuine behavioural forks, they are exposed as settings you can flip and
re-test without recompiling (see below).

---

## Settings — the A/B/C options to test

On first run the app writes **`frogcontrol.settings.json`** next to the exe. Edit it and pick
**Reload** from the tray menu to apply. The interesting switches:

| Setting | Options | Meaning |
|---|---|---|
| `MouseMoveBackend` | `SetCursorPos` \| `SendInputRelative` | How the mouse-control mode moves the cursor. AHK experimented with both. |
| `ActivationBackend` | `AttachThreadInput` \| `Plain` | Window activation. `AttachThreadInput` is the robust trick that defeats foreground-stealing limits; `Plain` is a bare `SetForegroundWindow` (try it if activation feels off). |
| `SuppressCapsLock` | `true` \| `false` | Whether CapsLock is a pure prefix (AHK behaviour) or left as a normal CapsLock. |
| `CapsLockTapToggles` | `true` \| `false` | Tapping CapsLock alone still toggles the real CapsLock LED. |
| `EnableUnstableRotation` | `true` \| `false` | The Win+Ctrl+Alt+Wheel "popup peek" rotation was marked unstable in AHK; disable to turn it off. |

The rest of the JSON mirrors the AHK `SETTING_CONSTANT_*` block (step sizes, snap-zone widths,
tooltip durations, wheel speed-up base) — tune freely.

---

## Feature parity

All hotkeys from `shortcut list-en.txt` are implemented:

- **Move window by mouse** — CapsLock + drag (Aero-snap zones, Shift = axis-lock, Alt = free, Ctrl = focus, Esc = cancel).
- **Resize window by mouse** — CapsLock + right-drag (3×3 grab regions, live resize cursor).
- **Wheel scroll speed up / slow** — CapsLock + wheel (tap CapsLock to raise the level), CapsLock + \` slow mode.
- **Volume** — Win + wheel / `[` `]` (± Ctrl for fine steps) via Core Audio.
- **Move window by keyboard** — CapsLock + Win/Shift/Ctrl + arrows (pixel move, edge snap, N×N grid).
- **Resize window by keyboard** — Win+Alt + arrows (X to shrink), Win+Alt+Shift to a screen edge.
- **Operate window** — Ctrl+Shift+RClick (close tab), +Alt (close window), Alt+RClick (minimise), Alt+Shift+RClick (send to bottom), Ctrl+Shift+wheel (Ctrl+PgUp/Dn).
- **Arrange windows** — Shift+F1..F4 (spread / grid, Explorer or the active window's type). Full port of the `Show_Windows` layout engine, including the 3/4/5+-window cases.
- **Transparency & always-on-top** — Win+A, Win+Click, Win+Alt+wheel/`[` `]`.
- **Window navigation** — Ctrl+Alt+wheel (rotate stacking), Win+Ctrl+Alt+wheel (popup peek), Shift+Alt+Win+wheel / Alt+\` (same-app), Win+Ctrl+Alt+arrows (directional seek).
- **Date & Time input mode** — CapsLock + O.
- **Mouse control mode** — CapsLock + M (number+arrow jumps, arrow-hold move, constrained, ruler, centre, coords).
- **Mouse clicks / wheel by keyboard** — CapsLock + Z/C/X/W/S/A/D.
- **Mouse bookmarks** — CapsLock + Ctrl/Shift/Alt + 1..0.
- **Window bookmarks** — CapsLock + [Ctrl +] F1..F9, list at F10.
- **Coordinates / constrained mouse** — CapsLock + `+` (twice = constrained).
- **Advanced** — Win+Shift+F1..F3 (TransColor / strip title bar / strip border), Win+Ctrl+L (Alt-Tab window list).

### Notes & known differences
- To move/resize **elevated** (admin) windows, run FrogControl as admin (change `app.manifest`
  `requestedExecutionLevel` to `requireAdministrator` and rebuild). Same limitation as AHK.
- Excel/Word horizontal fast-scroll uses running-object COM automation; if unavailable it falls
  back to plain wheel clicks.
- **Escape always exits** the Date/Time and Mouse-control modes (the modes release the keyboard
  hook in a `finally`, so a mode can never leave the keyboard captured).
- Geometry in the multi-window arrange cases can differ by a pixel or two from AHK's integer
  rounding; layout intent is identical.

---

## Project layout

```
csharp/FrogControl/
  Program.cs            entry point, single-instance mutex, tray/ApplicationContext, Reload
  App.cs               shared state + worker/detached-thread dispatch
  AppInfo.cs           name/version/paths
  Config/Settings.cs   the JSON settings (A/B/C options)
  Native/              Win32 P/Invoke, DPI, beep/wheel params, caret, COM helper
  Input/               keyboard + mouse LL hooks, InputSimulator, KeyState, tap tracking,
                       modal input channel, HotkeyEngine (the dispatch table)
  Windows/             WindowManager, WindowEnumerator, MonitorInfo, DwmHelper, WindowInfo
  Features/            one file per feature (mover, resizer, drag-move/resize, rotator, seeker,
                       arrange, wheel, ops, volume, clicks, bookmarks, date & mouse modes)
  UI/                  tray host, help window, tooltips, tray balloons, cursor swap, markers
```

The dispatch table lives in `Input/HotkeyEngine.cs` — start there to trace any hotkey.

---

Free software under the **GNU GPL v3** (same licence as the rest of FrogControl).
Created by Kim Dongryeong &lt;kdr@namouli.com&gt;.
