using FrogControl.Input;
using FrogControl.Native;

namespace FrogControl.Features;

/// <summary>CapsLock + Z/C/X/W/S/A/D : mouse clicks and wheel scrolls by keyboard.</summary>
public static class MouseClicks
{
    // Hold-to-hold: press the button while the trigger key is held (Click Down; KeyWait; Click Up).
    public static void HoldLeft() => Hold(Win32.MOUSEEVENTF_LEFTDOWN, Win32.MOUSEEVENTF_LEFTUP, 0x5A /*Z*/);
    public static void HoldRight() => Hold(Win32.MOUSEEVENTF_RIGHTDOWN, Win32.MOUSEEVENTF_RIGHTUP, 0x43 /*C*/);
    public static void HoldMiddle() => Hold(Win32.MOUSEEVENTF_MIDDLEDOWN, Win32.MOUSEEVENTF_MIDDLEUP, 0x58 /*X*/);

    private static void Hold(uint down, uint up, int vk)
    {
        InputSimulator.MouseDown(down);
        Pacing.KeyWaitRelease(vk, 0);
        InputSimulator.MouseUp(up);
    }

    public static void WheelUp() => InputSimulator.WheelVertical(1);
    public static void WheelDown() => InputSimulator.WheelVertical(-1);
    public static void WheelLeft() => InputSimulator.WheelHorizontal(-1);
    public static void WheelRight() => InputSimulator.WheelHorizontal(1);
}
