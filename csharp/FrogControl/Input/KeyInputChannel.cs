using System.Collections.Concurrent;

namespace FrogControl.Input;

/// <summary>One captured key press while a modal input mode is active.</summary>
public readonly struct KeyPress
{
    public readonly int Vk;
    public readonly char Ch;      // translated character ('\0' if none)
    public readonly bool Shift;
    public KeyPress(int vk, char ch, bool shift) { Vk = vk; Ch = ch; Shift = shift; }
}

/// <summary>
/// Thread-safe keystroke channel used by the interactive modes (date/time input, mouse control).
/// The engine pushes suppressed key-downs here; the mode loop reads them (like AHK's Input).
/// </summary>
public sealed class KeyInputChannel
{
    private readonly BlockingCollection<KeyPress> _q = new(new ConcurrentQueue<KeyPress>());

    public void Push(KeyPress kp)
    {
        try { _q.Add(kp); } catch { }
    }

    /// <summary>Blocking read with timeout (ms). Returns null on timeout. -1 = wait forever.</summary>
    public KeyPress? Read(int timeoutMs = -1)
    {
        try
        {
            if (timeoutMs < 0)
                return _q.Take();
            return _q.TryTake(out var kp, timeoutMs) ? kp : null;
        }
        catch { return null; }
    }

    public void Clear()
    {
        while (_q.TryTake(out _)) { }
    }
}

/// <summary>
/// The bridge between the hook/engine and a currently-active modal input mode.
/// When a channel is set, the engine routes (and suppresses) every physical key-down to it.
/// </summary>
public static class ModeHost
{
    public static volatile KeyInputChannel? ActiveChannel;

    public static KeyInputChannel Begin()
    {
        var ch = new KeyInputChannel();
        ActiveChannel = ch;
        return ch;
    }

    public static void End(KeyInputChannel ch)
    {
        if (ActiveChannel == ch) ActiveChannel = null;
    }
}
