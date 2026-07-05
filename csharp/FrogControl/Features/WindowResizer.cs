using FrogControl.Input;
using FrogControl.Native;
using FrogControl.Windows;

namespace FrogControl.Features;

/// <summary>
/// Win+Alt+Arrow window resizing (ported from the #!Arrow loop and the #!+Arrow edge-resize).
///   Win+Alt+Arrow          -> grow the window on that side by 20 px
///   Win+Alt+X+Arrow        -> shrink the window on that side by 20 px
///   Win+Alt+Shift+Arrow    -> grow that visible edge out to the screen edge (DWM-compensated)
/// The system "menu select" beep is suppressed for the duration (Alt keychords otherwise beep).
/// </summary>
public static class WindowResizer
{
    private const int Step = 20;

    public static void ResizeLoop()
    {
        if (!FrogControl.App.TryEnter("windowResize")) return;
        uint savedBeep = SystemParams.GetBeep();
        SystemParams.SetBeep(0);
        try
        {
            var s = FrogControl.App.Settings;
            double rep = s.WinMovePxSRepSec;
            while (true)
            {
                IntPtr hwnd = WindowManager.Active;
                bool isUp = KeyState.Up, isDown = KeyState.Down_, isLeft = KeyState.Left, isRight = KeyState.Right;
                bool isX = KeyState.IsDown(0x58); // 'X'

                if (isRight)
                {
                    WindowManager.GetPos(hwnd, out int X, out int Y, out int W, out int H);
                    if (isX) { WindowManager.Move(hwnd, X + Step, null, W - Step, null); }
                    else
                    {
                        WindowManager.Move(hwnd, null, null, W + Step, null);
                        WindowManager.GetPos(hwnd, out _, out _, out int W2, out _);
                        if (W == W2) WindowManager.Move(hwnd, X + Step, null);
                    }
                    Pacing.KeyWaitRelease(Win32.VK_RIGHT, rep);
                }
                if (isLeft)
                {
                    WindowManager.GetPos(hwnd, out int X, out int Y, out int W, out int H);
                    if (isX)
                    {
                        WindowManager.Move(hwnd, null, null, W - Step, null);
                        WindowManager.GetPos(hwnd, out _, out _, out int W2, out _);
                        if (W == W2) WindowManager.Move(hwnd, X - Step, null);
                    }
                    else { WindowManager.Move(hwnd, X - Step, null, W + Step, null); }
                    Pacing.KeyWaitRelease(Win32.VK_LEFT, rep);
                }
                if (isDown)
                {
                    WindowManager.GetPos(hwnd, out int X, out int Y, out int W, out int H);
                    if (isX) { WindowManager.Move(hwnd, null, Y + Step, null, H - Step); }
                    else
                    {
                        WindowManager.Move(hwnd, null, null, null, H + Step);
                        WindowManager.GetPos(hwnd, out _, out _, out _, out int H2);
                        if (H == H2) WindowManager.Move(hwnd, null, Y + Step);
                    }
                    Pacing.KeyWaitRelease(Win32.VK_DOWN, rep);
                }
                if (isUp)
                {
                    WindowManager.GetPos(hwnd, out int X, out int Y, out int W, out int H);
                    if (isX)
                    {
                        WindowManager.Move(hwnd, null, null, null, H - Step);
                        WindowManager.GetPos(hwnd, out _, out _, out _, out int H2);
                        if (H == H2) WindowManager.Move(hwnd, null, Y - Step);
                    }
                    else { WindowManager.Move(hwnd, null, Y - Step, null, H + Step); }
                    Pacing.KeyWaitRelease(Win32.VK_UP, rep);
                }

                if (!KeyState.Alt) break;
                if (!isUp && !isDown && !isLeft && !isRight) Thread.Sleep(10);
            }
        }
        finally
        {
            SystemParams.SetBeep(savedBeep);
            FrogControl.App.Exit("windowResize");
        }
    }

    /// <summary>Win+Alt+Shift+Arrow — grow the window's visible edge out to the nearest screen edge.</summary>
    public static void ResizeToEdge(char direction)
    {
        IntPtr hwnd = WindowManager.Active;
        if (hwnd == IntPtr.Zero) return;
        WindowManager.GetPos(hwnd, out int X, out int Y, out int W, out int H);
        var mon = MonitorInfo.Collect();
        DwmHelper.GetBorders(hwnd, out int bL, out int bT, out int bR, out int bB);

        switch (direction)
        {
            case 'R':
            {
                var edge = mon.EdgeScan("right_edge", X, Y, W, H);
                if (edge != null) WindowManager.Move(hwnd, null, null, edge.Value - X + bR, null);
                break;
            }
            case 'L':
            {
                var edge = mon.EdgeScan("left_edge", X, Y, W, H);
                if (edge != null) WindowManager.Move(hwnd, edge.Value - bL, null, X + W - edge.Value + bL, null);
                break;
            }
            case 'U':
            {
                var edge = mon.EdgeScan("up_edge", X, Y, W, H);
                if (edge != null) WindowManager.Move(hwnd, null, edge.Value - bT, null, Y + H - edge.Value + bT);
                break;
            }
            case 'D':
            {
                var edge = mon.EdgeScan("down_edge", X, Y, W, H);
                if (edge != null) WindowManager.Move(hwnd, null, null, null, edge.Value - Y + bB);
                break;
            }
        }
    }
}
