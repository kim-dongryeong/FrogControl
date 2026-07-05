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

    private static void SendKey(ushort vk, bool up)
    {
        bool extended = IsExtendedKey(vk);
        uint flags = up ? Win32.KEYEVENTF_KEYUP : 0;
        if (extended) flags |= Win32.KEYEVENTF_EXTENDEDKEY;

        var inp = new Win32.INPUT
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
