using FrogControl.Input;
using FrogControl.Native;
using FrogControl.Windows;

namespace FrogControl.Features;

/// <summary>
/// CapsLock + Arrow window movement (ported from the big CapsLock &amp; Up/Down/Left/Right block).
///   CapsLock + Win + Arrow          -> move by 20 px
///   CapsLock + Shift + Arrow        -> move to the nearest screen edge (DWM-compensated)
///   CapsLock + Ctrl (×n) + Arrow    -> resize to 1/(n+1) screen and step through an (n+1)×(n+1) grid
///   CapsLock + Arrow (no modifier)  -> send arrow keys to the app (CapsLock ×n speeds it up)
/// Runs on a detached thread; loops while CapsLock is held.
/// </summary>
public static class WindowMover
{
    public static void Start()
    {
        if (FrogControl.App.FlagMouseControl) return;
        if (!FrogControl.App.TryEnter("windowMove")) return;
        try { Loop(); }
        finally { FrogControl.App.Exit("windowMove"); }
    }

    private static void Loop()
    {
        var s = FrogControl.App.Settings;
        bool controlTriggered = false;
        int gridNo = 1;
        int capSpeedUp = 0;

        var mon = MonitorInfo.Collect();   // hoisted out of the loop (matches AHK)

        while (true)
        {
            IntPtr hwnd = WindowManager.Active;
            if (hwnd == IntPtr.Zero) hwnd = IntPtr.Zero;
            WindowManager.GetPos(hwnd, out int X, out int Y, out int W, out int H);

            bool isCtrl = KeyState.Ctrl;
            bool isUp = KeyState.Up, isDown = KeyState.Down_, isLeft = KeyState.Left, isRight = KeyState.Right;
            bool isWin = KeyState.Win;
            bool isShift = KeyState.Shift;

            if (isWin)
            {
                // move by 20 px (WINMOV_PX_S); shift = faster repeat
                double rep = isShift ? 0.005 : s.WinMovePxSRepSec;
                if (isRight) { WindowManager.Move(hwnd, X + s.WinMovePxSmall, null); Pacing.KeyWaitRelease(Win32.VK_RIGHT, rep); }
                if (isLeft) { WindowManager.Move(hwnd, X - s.WinMovePxSmall, null); Pacing.KeyWaitRelease(Win32.VK_LEFT, rep); }
                if (isUp) { WindowManager.Move(hwnd, null, Y - s.WinMovePxSmall); Pacing.KeyWaitRelease(Win32.VK_UP, rep); }
                if (isDown) { WindowManager.Move(hwnd, null, Y + s.WinMovePxSmall); Pacing.KeyWaitRelease(Win32.VK_DOWN, rep); }
            }
            else
            {
                if (isShift)
                {
                    // move to a screen edge
                    if (isRight) EdgeMove(mon, hwnd, X, Y, W, H, "right_edge", "right_gap", Win32.VK_RIGHT, s.WinMoveStepRepSec);
                    if (isLeft) EdgeMove(mon, hwnd, X, Y, W, H, "left_edge", "left_gap", Win32.VK_LEFT, s.WinMoveStepRepSec);
                    if (isUp) EdgeMove(mon, hwnd, X, Y, W, H, "up_edge", "up_gap", Win32.VK_UP, s.WinMoveStepRepSec);
                    if (isDown) EdgeMove(mon, hwnd, X, Y, W, H, "down_edge", "down_gap", Win32.VK_DOWN, s.WinMoveStepRepSec);
                }
                else if (isCtrl)
                {
                    WindowManager.Restore(hwnd);
                    WindowManager.GetPos(hwnd, out X, out Y, out W, out H); // re-read after restore
                    var m = mon.FromRectCenter(X, Y, W, H);
                    double sx = m.WorkLeft, sy = m.WorkTop, sw = m.WorkWidth, sh = m.WorkHeight;

                    if (!controlTriggered)
                    {
                        controlTriggered = true;
                        gridNo = 1 + KeyState.CountRecentTaps("Control");
                    }

                    if (isUp) { DwmHelper.WinMove(hwnd, null, sy + Math.Ceiling((Y - sy - 1) / sh * gridNo - 1) * sh / gridNo, sw / gridNo, sh / gridNo); Pacing.KeyWaitRelease(Win32.VK_UP, s.WinMoveStepRepSec); }
                    if (isDown) { DwmHelper.WinMove(hwnd, null, sy + Math.Ceiling((Y - sy + 1) / sh * gridNo) * sh / gridNo, sw / gridNo, sh / gridNo); Pacing.KeyWaitRelease(Win32.VK_DOWN, s.WinMoveStepRepSec); }
                    if (isLeft) { DwmHelper.WinMove(hwnd, sx + Math.Ceiling((X - sx - 1) / sw * gridNo - 1) * sw / gridNo, null, sw / gridNo, sh / gridNo); Pacing.KeyWaitRelease(Win32.VK_LEFT, s.WinMoveStepRepSec); }
                    if (isRight) { DwmHelper.WinMove(hwnd, sx + Math.Ceiling((X - sx + 1) / sw * gridNo) * sw / gridNo, null, sw / gridNo, sh / gridNo); Pacing.KeyWaitRelease(Win32.VK_RIGHT, s.WinMoveStepRepSec); }
                }
                else
                {
                    // no modifier: send arrow keys to the app, sped up by CapsLock taps
                    if (capSpeedUp == 0)
                        capSpeedUp = 1 + KeyState.CountRecentTaps("CapsLock");
                    for (int i = 0; i < capSpeedUp; i++)
                    {
                        if (isUp) InputSimulator.KeyPress(Win32.VK_UP);
                        if (isDown) InputSimulator.KeyPress(Win32.VK_DOWN);
                        if (isLeft) InputSimulator.KeyPress(Win32.VK_LEFT);
                        if (isRight) InputSimulator.KeyPress(Win32.VK_RIGHT);
                    }
                    Thread.Sleep(10);
                }
            }

            if (!KeyState.Caps)
                break;
            if (!isUp && !isDown && !isLeft && !isRight)
                Thread.Sleep(10);
        }
    }

    private static void EdgeMove(MonitorSet mon, IntPtr hwnd, int X, int Y, int W, int H,
        string edgeMode, string gapMode, int vk, double rep)
    {
        double? edgeI = mon.EdgeScan(edgeMode, X, Y, W, H);
        double? edgeJ = mon.EdgeScan(gapMode, X, Y, W, H);
        DwmHelper.GetBorders(hwnd, out int bL, out int bT, out int bR, out int bB);

        bool horizontal = edgeMode.StartsWith("right") || edgeMode.StartsWith("left");
        if (edgeMode.StartsWith("right"))
        {
            if (edgeI != null && edgeJ != null)
            {
                if (edgeI.Value - X - W < edgeJ.Value - X) WindowManager.Move(hwnd, edgeI.Value - W + bR, null);
                else WindowManager.Move(hwnd, edgeJ.Value - bL, null);
            }
            else if (edgeI != null) WindowManager.Move(hwnd, edgeI.Value - W + bR, null);
            else if (edgeJ != null) WindowManager.Move(hwnd, edgeJ.Value - bL, null);
        }
        else if (edgeMode.StartsWith("left"))
        {
            if (edgeI != null && edgeJ != null)
            {
                if (X - edgeI.Value < X + W - edgeJ.Value) WindowManager.Move(hwnd, edgeI.Value - bL, null);
                else WindowManager.Move(hwnd, edgeJ.Value - W + bR, null);
            }
            else if (edgeI != null) WindowManager.Move(hwnd, edgeI.Value - bL, null);
            else if (edgeJ != null) WindowManager.Move(hwnd, edgeJ.Value - W + bR, null);
        }
        else if (edgeMode.StartsWith("up"))
        {
            if (edgeI != null && edgeJ != null)
            {
                if (Y - edgeI.Value < Y + H - edgeJ.Value) WindowManager.Move(hwnd, null, edgeI.Value - bT);
                else WindowManager.Move(hwnd, null, edgeJ.Value - H + bB);
            }
            else if (edgeI != null) WindowManager.Move(hwnd, null, edgeI.Value - bT);
            else if (edgeJ != null) WindowManager.Move(hwnd, null, edgeJ.Value - H + bB);
        }
        else // down
        {
            if (edgeI != null && edgeJ != null)
            {
                if (edgeI.Value - Y - H < edgeJ.Value - Y) WindowManager.Move(hwnd, null, edgeI.Value - H + bB);
                else WindowManager.Move(hwnd, null, edgeJ.Value - bT);
            }
            else if (edgeI != null) WindowManager.Move(hwnd, null, edgeI.Value - H + bB);
            else if (edgeJ != null) WindowManager.Move(hwnd, null, edgeJ.Value - bT);
        }
        _ = horizontal;
        Pacing.KeyWaitRelease(vk, rep);
    }
}
