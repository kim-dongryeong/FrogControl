using FrogControl.Input;
using FrogControl.Native;
using FrogControl.UI;
using FrogControl.Windows;

namespace FrogControl.Features;

/// <summary>
/// CapsLock + '+' : show mouse coordinates; press it twice quickly to enter the constrained-mouse
/// mode where the cursor is locked to one axis (Space returns it to the start). Port of the
/// CapsLock &amp; + block + MouseConstraintMode + IsCapsLockReleased.
/// </summary>
public static class CoordinateMode
{
    private static int _process;
    private static readonly object Sync = new();
    private static IntPtr _activeWin;
    private static bool _capsInitial;

    public static void Handle()
    {
        int dur = FrogControl.App.Settings.TooltipDurationShortMs;
        lock (Sync)
        {
            if (!FrogControl.App.FlagCoorConstrainedMouse)
            {
                _capsInitial = CapsLockState.IsOn;
                FrogControl.App.FlagCoorConstrainedMouse = true;
                _activeWin = WindowManager.Active;
                WindowManager.ActivateTaskbar();
            }

            if (_process > 0)
            {
                _process++;
                return;
            }
            _process = 1;
        }

        InputSimulator.GetCursor(out int cx, out int cy);
        ToolTipService.ShowTimed($"mouse coordinates: ({cx}, {cy})", dur);

        // After ~300 ms decide: single press = just coords; double press = constrained mode.
        FrogControl.App.RunDetached("coordMode", () =>
        {
            Thread.Sleep(300);
            int proc;
            lock (Sync) proc = _process;
            if (proc > 1)
                ConstrainedLoop();
            lock (Sync) _process = 0;
            WaitCapsReleaseAndRestore();
        });
    }

    private static void ConstrainedLoop()
    {
        ToolTipService.Show("Constrained mouse mode\n- Spacebar: moves to the initial position", 2);
        ToolTipService.ShowTimed("Constrained mouse mode\n- Spacebar: moves to the initial position", 3000, 2);
        InputSimulator.GetCursor(out int origX, out int origY);
        while (true)
        {
            lock (Sync) _process = 0;
            InputSimulator.GetCursor(out int curX, out int curY);
            double det = Math.Abs(curX - origX) - Math.Abs(curY - origY);
            int step = (int)Math.Floor(Math.Exp(det - Math.Abs(det)));
            InputSimulator.MoveCursor(origX + (curX - origX) * step, origY + (curY - origY) * (1 - step));
            if (KeyState.Space)
            {
                InputSimulator.MoveCursor(origX, origY);
                ToolTipService.ShowTimed($"initial coordinates: ({origX}, {origY})", FrogControl.App.Settings.TooltipDurationShortMs);
            }
            if (!KeyState.Caps)
                break;
            Thread.Sleep(2);
        }
    }

    private static void WaitCapsReleaseAndRestore()
    {
        // Wait for CapsLock to be released, then restore its toggle state and re-focus the window.
        while (KeyState.Caps) Thread.Sleep(20);
        if (FrogControl.App.FlagCoorConstrainedMouse)
        {
            WindowManager.Activate(_activeWin);
            CapsLockState.Set(_capsInitial);
            FrogControl.App.FlagCoorConstrainedMouse = false;
        }
    }
}
