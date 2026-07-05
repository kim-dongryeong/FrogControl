using FrogControl.Native;

namespace FrogControl.Input;

/// <summary>
/// Tracks physical key state (like AHK's internal hook state behind GetKeyState "P")
/// and modifier "tap" timestamps (the timeStamp_* rings + CountRecentTaps).
///
/// Because we SUPPRESS CapsLock (and second-keys of CapsLock combos) in our hook,
/// GetAsyncKeyState no longer reflects them, so we maintain our own down-table,
/// fed by the keyboard/mouse hooks on every physical event.
/// </summary>
public static class KeyState
{
    private static readonly bool[] Down = new bool[256];
    private static readonly object Sync = new();

    // Modifier tap timestamps (Environment.TickCount), one bounded queue each.
    private static readonly Dictionary<string, Queue<int>> Taps = new()
    {
        ["Alt"] = new(), ["Control"] = new(), ["Shift"] = new(), ["Win"] = new(), ["CapsLock"] = new(),
    };
    private const int MaxTaps = 20;   // timeStamp_modfr_max

    public static void MarkDown(int vk)
    {
        if (vk is >= 0 and < 256) lock (Sync) Down[vk] = true;
    }

    public static void MarkUp(int vk)
    {
        if (vk is >= 0 and < 256) lock (Sync) Down[vk] = false;
    }

    /// <summary>Physical down state. OR of our tracked table and the async physical bit.</summary>
    public static bool IsDown(int vk)
    {
        bool tracked;
        lock (Sync) tracked = vk is >= 0 and < 256 && Down[vk];
        return tracked || (Win32.GetAsyncKeyState(vk) & 0x8000) != 0;
    }

    // High-level modifier queries (combine L/R).
    public static bool Ctrl => IsDown(Win32.VK_CONTROL) || IsDown(Win32.VK_LCONTROL) || IsDown(Win32.VK_RCONTROL);
    public static bool Alt => IsDown(Win32.VK_MENU) || IsDown(Win32.VK_LMENU) || IsDown(Win32.VK_RMENU);
    public static bool Shift => IsDown(Win32.VK_SHIFT) || IsDown(Win32.VK_LSHIFT) || IsDown(Win32.VK_RSHIFT);
    public static bool Win => IsDown(Win32.VK_LWIN) || IsDown(Win32.VK_RWIN);
    public static bool Caps => IsDown(Win32.VK_CAPITAL);

    public static bool Left => IsDown(Win32.VK_LEFT);
    public static bool Right => IsDown(Win32.VK_RIGHT);
    public static bool Up => IsDown(Win32.VK_UP);
    public static bool Down_ => IsDown(Win32.VK_DOWN);
    public static bool Space => IsDown(Win32.VK_SPACE);
    public static bool Escape => IsDown(Win32.VK_ESCAPE);

    // ---------------- Tap tracking ----------------
    /// <summary>Record a modifier tap (called by the hook on physical key-down).</summary>
    public static void RecordTap(string modifier)
    {
        if (!Taps.TryGetValue(modifier, out var q)) return;
        lock (Sync)
        {
            q.Enqueue(Environment.TickCount);
            while (q.Count > MaxTaps) q.Dequeue();
        }
    }

    /// <summary>CountRecentTaps: how many taps of this modifier happened within windowMs.</summary>
    public static int CountRecentTaps(string modifier, int windowMs = 1500)
    {
        if (!Taps.TryGetValue(modifier, out var q)) return 0;
        int now = Environment.TickCount;
        int count = 0;
        lock (Sync)
            foreach (int t in q)
                if (now - t < windowMs) count++;
        return count;
    }

    public static void ResetTaps()
    {
        lock (Sync)
            foreach (var q in Taps.Values) q.Clear();
    }
}
