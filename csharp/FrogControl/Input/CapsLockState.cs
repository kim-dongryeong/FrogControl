using FrogControl.Native;

namespace FrogControl.Input;

/// <summary>
/// Reads and sets the real CapsLock toggle state (AHK GetKeyState("CapsLock","T") / SetCapsLockState).
/// Because we suppress physical CapsLock, changing the LED is done by synthesising an (injected)
/// CapsLock tap, which passes through our hook and flips the OS toggle.
/// </summary>
public static class CapsLockState
{
    public static bool IsOn => (Win32.GetKeyState(Win32.VK_CAPITAL) & 1) != 0;

    public static void Set(bool on)
    {
        if (IsOn != on)
            InputSimulator.KeyPress((ushort)Win32.VK_CAPITAL);
    }
}
