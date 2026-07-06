using FrogControl.Native;

namespace FrogControl.Input;

/// <summary>
/// SendInput / SetCursorPos wrappers. Every synthetic event is tagged with
/// <see cref="FrogTag"/> in dwExtraInfo so our own hooks can recognise and ignore it.
/// This replaces AHK's Send / Click / MouseMove / SetCursorPos / SoundSet(no) usage.
/// </summary>
public static class InputSimulator
{
    /// <summary>Marker placed in dwExtraInfo of every event we synthesise ("FROG").</summary>
    public static readonly IntPtr FrogTag = new IntPtr(0x46524F47);

    // ---------------- Keyboard ----------------
    public static void KeyDown(ushort vk) => SendKey(vk, false);
    public static void KeyUp(ushort vk) => SendKey(vk, true);

    public static void KeyPress(ushort vk)
    {
        KeyDown(vk);
        KeyUp(vk);
    }

    /// <summary>Press a chord: modifiers down, key, modifiers up (in reverse).</summary>
    public static void KeyCombo(ushort key, params ushort[] modifiers)
    {
        foreach (var m in modifiers) KeyDown(m);
        KeyPress(key);
        for (int i = modifiers.Length - 1; i >= 0; i--) KeyUp(modifiers[i]);
    }

    private static readonly ushort[] AllModVks =
    {
        Win32.VK_LSHIFT, Win32.VK_RSHIFT, Win32.VK_LCONTROL, Win32.VK_RCONTROL,
        Win32.VK_LMENU, Win32.VK_RMENU, Win32.VK_LWIN, Win32.VK_RWIN,
    };

    // ---- Guard against typematic re-assertion during an isolated send -------------------
    // While the user physically holds a modifier, the keyboard auto-repeats its key-down
    // every ~33 ms. If such a repeat lands between our synthetic "Shift up" and "W down",
    // the target app sees Ctrl+Shift+W instead of Ctrl+W (Chrome: close WINDOW, not tab).
    // The keyboard hook consults ShouldSuppressPhysicalRepeat() and swallows exactly those
    // re-assertions for a short window around the send.
    private static volatile ushort[] _guardedVks = Array.Empty<ushort>();
    private static int _guardUntilTick;

    public static bool ShouldSuppressPhysicalRepeat(int vk)
    {
        if (Environment.TickCount - Volatile.Read(ref _guardUntilTick) >= 0)
            return false;   // guard expired
        foreach (var g in _guardedVks)
            if (g == vk) return true;
        return false;
    }

    /// <summary>Fold L/R modifier VKs onto one identity so "chord needs Ctrl" matches a held LCtrl.</summary>
    private static ushort ToGenericMod(ushort vk) => vk switch
    {
        Win32.VK_LSHIFT or Win32.VK_RSHIFT => (ushort)Win32.VK_SHIFT,
        Win32.VK_LCONTROL or Win32.VK_RCONTROL => (ushort)Win32.VK_CONTROL,
        Win32.VK_LMENU or Win32.VK_RMENU => (ushort)Win32.VK_MENU,
        Win32.VK_LWIN or Win32.VK_RWIN => (ushort)Win32.VK_LWIN,   // treat both Win keys as one
        _ => vk,
    };

    private static readonly object IsolatedSync = new();

    /// <summary>
    /// Send a clean chord (only <paramref name="modifiers"/> active) even while the user is
    /// physically holding other modifiers. Like AHK's Send:
    ///  - modifiers the chord NEEDS that are already physically down are left alone,
    ///  - contaminating ones are lifted, so the batch is minimal (e.g. Shift-up, W-down, W-up).
    /// The batch goes out in ONE SendInput call (atomic against physical input), and the lifted
    /// modifiers are restored in a SECOND batch after a short delay: apps that drain the message
    /// queue before handling (Chrome's pump) read GetKeyState as of the last RETRIEVED message,
    /// so an in-batch restore could still contaminate the key they were about to handle.
    /// The hook guard swallows the lifted keys' typematic re-assertions for the whole window,
    /// and the lock serialises overlapping sends (rapid clicks) so one send's restore cannot
    /// land inside another's lift-to-key gap.
    /// </summary>
    public static void KeyComboIsolated(ushort key, params ushort[] modifiers)
    {
        lock (IsolatedSync)
        {
            // Physically-held modifiers the chord does NOT need -> lift them.
            var lift = new List<ushort>();
            foreach (var m in AllModVks)
            {
                if ((Win32.GetAsyncKeyState(m) & 0x8000) == 0) continue;
                bool neededByChord = false;
                foreach (var cm in modifiers)
                    if (ToGenericMod(m) == ToGenericMod(cm)) { neededByChord = true; break; }
                if (!neededByChord) lift.Add(m);
            }
            // Chord modifiers not already physically down -> we must press (and release) them.
            var press = new List<ushort>();
            foreach (var cm in modifiers)
                if ((Win32.GetAsyncKeyState(cm) & 0x8000) == 0) press.Add(cm);

            int delayMs = Math.Clamp(FrogControl.App.Settings.IsolatedSendRestoreDelayMs, 0, 500);

            // Arm the hook guard through batch + delay + margin (downs of lifted keys are
            // swallowed; ups always pass, so nothing can get stuck).
            _guardedVks = lift.ToArray();
            Volatile.Write(ref _guardUntilTick, Environment.TickCount + delayMs + 150);

            // Batch 1: lift, press missing chord modifiers, tap the key, release what we pressed.
            var seq = new List<Win32.INPUT>(lift.Count + press.Count * 2 + 2);
            foreach (var m in lift) seq.Add(MakeKeyInput(m, up: true));
            foreach (var m in press) seq.Add(MakeKeyInput(m, up: false));
            seq.Add(MakeKeyInput(key, up: false));
            seq.Add(MakeKeyInput(key, up: true));
            for (int i = press.Count - 1; i >= 0; i--) seq.Add(MakeKeyInput(press[i], up: true));
            Win32.SendInput((uint)seq.Count, seq.ToArray(), System.Runtime.InteropServices.Marshal.SizeOf<Win32.INPUT>());

            if (lift.Count == 0)
                return;

            // Batch 2 (deferred): restore the lifted modifiers the user is STILL holding.
            // (KeyState tracks physical state via the hook; if the user released the key during
            //  the delay, the physical up passed through and cleared it -> no restore, no stick.)
            Thread.Sleep(delayMs);
            var restore = new List<Win32.INPUT>(lift.Count);
            foreach (var m in lift)
                if (KeyState.IsDown(m))
                    restore.Add(MakeKeyInput(m, up: false));
            if (restore.Count > 0)
                Win32.SendInput((uint)restore.Count, restore.ToArray(), System.Runtime.InteropServices.Marshal.SizeOf<Win32.INPUT>());
        }
    }

    private static Win32.INPUT MakeKeyInput(ushort vk, bool up)
    {
        bool extended = IsExtendedKey(vk);
        uint flags = up ? Win32.KEYEVENTF_KEYUP : 0;
        if (extended) flags |= Win32.KEYEVENTF_EXTENDEDKEY;
        return new Win32.INPUT
        {
            type = Win32.INPUT_KEYBOARD,
            U = new Win32.InputUnion
            {
                ki = new Win32.KEYBDINPUT
                {
                    wVk = vk,
                    wScan = 0,
                    dwFlags = flags,
                    time = 0,
                    dwExtraInfo = FrogTag,
                }
            }
        };
    }

    private static void SendKey(ushort vk, bool up)
    {
        var inp = MakeKeyInput(vk, up);
        Win32.SendInput(1, new[] { inp }, System.Runtime.InteropServices.Marshal.SizeOf<Win32.INPUT>());
    }

    private static bool IsExtendedKey(ushort vk) => vk switch
    {
        Win32.VK_LEFT or Win32.VK_UP or Win32.VK_RIGHT or Win32.VK_DOWN
            or Win32.VK_RCONTROL or Win32.VK_RMENU
            or Win32.VK_LWIN or Win32.VK_RWIN
            or 0x2D /*INSERT*/ or 0x2E /*DELETE*/ or 0x24 /*HOME*/ or 0x23 /*END*/
            or 0x21 /*PGUP*/ or 0x22 /*PGDN*/ => true,
        _ => false,
    };

    /// <summary>Type a literal string (like SendRaw) — used by the date/time input mode.</summary>
    public static void SendUnicodeString(string text)
    {
        var list = new List<Win32.INPUT>(text.Length * 2);
        foreach (char c in text)
        {
            list.Add(MakeUnicode(c, false));
            list.Add(MakeUnicode(c, true));
        }
        if (list.Count > 0)
            Win32.SendInput((uint)list.Count, list.ToArray(), System.Runtime.InteropServices.Marshal.SizeOf<Win32.INPUT>());
    }

    private static Win32.INPUT MakeUnicode(char c, bool up)
    {
        const uint KEYEVENTF_UNICODE = 0x0004;
        return new Win32.INPUT
        {
            type = Win32.INPUT_KEYBOARD,
            U = new Win32.InputUnion
            {
                ki = new Win32.KEYBDINPUT
                {
                    wVk = 0,
                    wScan = c,
                    dwFlags = KEYEVENTF_UNICODE | (up ? Win32.KEYEVENTF_KEYUP : 0),
                    time = 0,
                    dwExtraInfo = FrogTag,
                }
            }
        };
    }

    // ---------------- Mouse buttons ----------------
    public static void MouseDown(uint downFlag) => SendMouse(downFlag, 0);
    public static void MouseUp(uint upFlag) => SendMouse(upFlag, 0);

    public static void LeftClick() { SendMouse(Win32.MOUSEEVENTF_LEFTDOWN, 0); SendMouse(Win32.MOUSEEVENTF_LEFTUP, 0); }
    public static void RightClick() { SendMouse(Win32.MOUSEEVENTF_RIGHTDOWN, 0); SendMouse(Win32.MOUSEEVENTF_RIGHTUP, 0); }
    public static void MiddleClick() { SendMouse(Win32.MOUSEEVENTF_MIDDLEDOWN, 0); SendMouse(Win32.MOUSEEVENTF_MIDDLEUP, 0); }

    // ---------------- Wheel ----------------
    /// <summary>Positive clicks scroll up, negative down (like Click WheelUp/Down N).</summary>
    public static void WheelVertical(int clicks) => SendMouse(Win32.MOUSEEVENTF_WHEEL, clicks * Win32.WHEEL_DELTA);
    /// <summary>Positive clicks scroll right, negative left.</summary>
    public static void WheelHorizontal(int clicks) => SendMouse(Win32.MOUSEEVENTF_HWHEEL, clicks * Win32.WHEEL_DELTA);

    private static void SendMouse(uint flags, int data)
    {
        var inp = new Win32.INPUT
        {
            type = Win32.INPUT_MOUSE,
            U = new Win32.InputUnion
            {
                mi = new Win32.MOUSEINPUT
                {
                    dx = 0,
                    dy = 0,
                    mouseData = unchecked((uint)data),
                    dwFlags = flags,
                    time = 0,
                    dwExtraInfo = FrogTag,
                }
            }
        };
        Win32.SendInput(1, new[] { inp }, System.Runtime.InteropServices.Marshal.SizeOf<Win32.INPUT>());
    }

    // ---------------- Cursor movement ----------------
    public static void GetCursor(out int x, out int y)
    {
        Win32.GetCursorPos(out var p);
        x = p.X; y = p.Y;
    }

    /// <summary>Absolute move via SetCursorPos (matches DllCall("SetCursorPos") in the AHK).</summary>
    public static void MoveCursor(int x, int y) => Win32.SetCursorPos(x, y);
}
